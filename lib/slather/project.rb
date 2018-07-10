require 'fileutils'
require 'xcodeproj'
require 'json'
require 'yaml'
require 'shellwords'

module Xcodeproj

  class Project

    def slather_setup_for_coverage(format = :auto)
      unless [:gcov, :clang, :auto].include?(format)
        raise StandardError, "Only supported formats for setup are gcov, clang or auto"
      end
      if format == :auto
        format = Slather.xcode_version[0] < 7 ? :gcov : :clang
      end

      build_configurations.each do |build_configuration|
        if format == :clang
          build_configuration.build_settings["CLANG_ENABLE_CODE_COVERAGE"] = "YES"
        else
          build_configuration.build_settings["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"] = "YES"
          build_configuration.build_settings["GCC_GENERATE_TEST_COVERAGE_FILES"] = "YES"
        end
      end

      # Patch xcschemes too
      if format == :clang
        schemes_path = Xcodeproj::XCScheme.shared_data_dir(self.path)
        Xcodeproj::Project.schemes(self.path).each do |scheme_name|
          xcscheme_path = "#{schemes_path + scheme_name}.xcscheme"
          xcscheme = Xcodeproj::XCScheme.new(xcscheme_path)
          xcscheme.test_action.xml_element.attributes['codeCoverageEnabled'] = 'YES'
          xcscheme.save_as(self.path, scheme_name)
        end
      end
    end

  end
end

module Slather
  class Project < Xcodeproj::Project

    attr_accessor :build_directory, :ignore_list, :ci_service, :coverage_service, :coverage_access_token, :source_directory,
      :output_directory, :xcodeproj, :show_html, :verbose_mode, :input_format, :scheme, :workspace, :binary_file, :binary_basename, :arch, :source_files,
      :decimals, :llvm_version, :configuration

    alias_method :setup_for_coverage, :slather_setup_for_coverage

    def self.open(xcodeproj)
      proj = super
      proj.xcodeproj = xcodeproj
      proj
    end

    def failure_help_string
      "\n\tAre you sure your project is generating coverage? Make sure you enable code coverage in the Test section of your Xcode scheme.\n\tDid you specify your Xcode scheme? (--scheme or 'scheme' in .slather.yml)\n\tIf you're using a workspace, did you specify it? (--workspace or 'workspace' in .slather.yml)\n\tIf you use a different Xcode configuration, did you specify it? (--configuration or 'configuration' in .slather.yml)"
    end

    def derived_data_path
      # Get the derived data path from xcodebuild
      # Use OBJROOT when possible, as it provides regardless of whether or not the Derived Data location is customized
      if self.workspace
        projectOrWorkspaceArgument = "-workspace \"#{self.workspace}\""
      else
        projectOrWorkspaceArgument = "-project \"#{self.path}\""
      end

      if self.scheme
        schemeArgument = "-scheme \"#{self.scheme}\""
        buildAction = "test"
      else
        schemeArgument = nil
        buildAction = nil
      end

      # redirect stderr to avoid xcodebuild errors being printed.
      build_settings = `xcodebuild #{projectOrWorkspaceArgument} #{schemeArgument} -showBuildSettings #{buildAction} CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO 2>&1`

      if build_settings
        derived_data_path = build_settings.match(/ OBJROOT = (.+)/)
        # when match fails derived_data_path is nil
        derived_data_path = derived_data_path[1] if derived_data_path
      end

      if derived_data_path == nil
        derived_data_path = File.expand_path('~') + "/Library/Developer/Xcode/DerivedData/"
      end

      derived_data_path
    end
    private :derived_data_path

    def coverage_files
      if self.input_format == "profdata"
        profdata_coverage_files
      else
        gcov_coverage_files
      end
    end

    def gcov_coverage_files
      coverage_files = Dir["#{build_directory}/**/*.gcno"].map do |file|
        coverage_file = coverage_file_class.new(self, file)
        # If there's no source file for this gcno, it probably belongs to another project.
        coverage_file.source_file_pathname && !coverage_file.ignored? ? coverage_file : nil
      end.compact

      if coverage_files.empty?
        raise StandardError, "No coverage files found."
      else
        dedupe(coverage_files)
      end
    end
    private :gcov_coverage_files

    def profdata_coverage_files
      coverage_files = []
      line_numbers_first = Gem::Version.new(self.llvm_version) >= Gem::Version.new('8.1.0')

      if self.binary_file
        self.binary_file.each do |binary_path|
          coverage_json_string = llvm_cov_export_output(binary_path)
          coverage_json = JSON.parse(coverage_json_string)
          pathnames_per_binary = coverage_json["data"].reduce([]) do |result, chunk|
            result.concat(chunk["files"].map do |file|
              Pathname(file["filename"]).realpath
            end)
          end

          files = profdata_llvm_cov_output(binary_path, pathnames_per_binary).split("\n\n")

          coverage_files.concat(files.map do |source|
            coverage_file = coverage_file_class.new(self, source, line_numbers_first)
            # If a single source file is used, the resulting output does not contain the file name.
            coverage_file.source_file_pathname = pathnames_per_binary.first if pathnames_per_binary.count == 1
            !coverage_file.ignored? ? coverage_file : nil
          end.compact)
        end
      end

      coverage_files
    end
    private :profdata_coverage_files

    def remove_extension(path)
      path.split(".")[0..-2].join(".")
    end

    def first_product_name
      first_product = self.products.first
      # If name is not available it computes it using
      # the path by dropping the 'extension' of the path.
      first_product.name || remove_extension(first_product.path)
    end

    def profdata_coverage_dir
      raise StandardError, "The specified build directory (#{self.build_directory}) does not exist" unless File.exists?(self.build_directory)
      dir = nil
      if self.scheme
        dir = Dir[File.join(build_directory,"/**/CodeCoverage/#{self.scheme}")].first
      else
        dir = Dir[File.join(build_directory,"/**/#{first_product_name}")].first
      end

      if dir == nil
        # Xcode 7.3 moved the location of Coverage.profdata
        dir = Dir[File.join(build_directory,"/**/CodeCoverage")].first
      end

      if dir == nil && Slather.xcode_version[0] >= 9
        # Xcode 9 moved the location of Coverage.profdata
        coverage_files = Dir[File.join(build_directory, "/**/ProfileData/*/Coverage.profdata")]

        if coverage_files.count == 0
          # Look up one directory
          # The ProfileData directory is next to Intermediates.noindex (in previous versions of Xcode the coverage was inside Intermediates)
          coverage_files = Dir[File.join(build_directory, "../**/ProfileData/*/Coverage.profdata")]
        end

        if coverage_files != nil
          dir = Pathname.new(coverage_files.first).parent()
        end
      end

      raise StandardError, "No coverage directory found." unless dir != nil
      dir
    end

    def profdata_file
      profdata_coverage_dir = self.profdata_coverage_dir
      if profdata_coverage_dir == nil
        raise StandardError, "No coverage directory found. Please make sure the \"Code Coverage\" checkbox is enabled in your scheme's Test action or the build_directory property is set."
      end

      file =  Dir["#{profdata_coverage_dir}/**/Coverage.profdata"].first
      unless file != nil
        return nil
      end
      return File.expand_path(file)
    end
    private :profdata_file

    def unsafe_llvm_cov_export_output(binary_path)
      profdata_file_arg = profdata_file
      if profdata_file_arg == nil
        raise StandardError, "No Coverage.profdata files found. Please make sure the \"Code Coverage\" checkbox is enabled in your scheme's Test action or the build_directory property is set."
      end

      if binary_path == nil
        raise StandardError, "No binary file found."
      end

      llvm_cov_args = %W(export -instr-profile #{profdata_file_arg} #{binary_path})
      if self.arch
        llvm_cov_args << "--arch" << self.arch
      end
      `xcrun llvm-cov #{llvm_cov_args.shelljoin}`
    end
    private :unsafe_llvm_cov_export_output

    def llvm_cov_export_output(binary_path)
      output = unsafe_llvm_cov_export_output(binary_path)
      output.valid_encoding? ? output : output.encode!('UTF-8', 'binary', :invalid => :replace, undef: :replace)
    end
    private :llvm_cov_export_output

    def unsafe_profdata_llvm_cov_output(binary_path, source_files)
      profdata_file_arg = profdata_file
      if profdata_file_arg == nil
        raise StandardError, "No Coverage.profdata files found. Please make sure the \"Code Coverage\" checkbox is enabled in your scheme's Test action or the build_directory property is set."
      end

      if binary_path == nil
        raise StandardError, "No binary file found."
      end

      llvm_cov_args = %W(show -instr-profile #{profdata_file_arg} #{binary_path})
      if self.arch
        llvm_cov_args << "--arch" << self.arch
      end
      `xcrun llvm-cov #{llvm_cov_args.shelljoin} #{source_files.shelljoin}`
    end
    private :unsafe_profdata_llvm_cov_output

    def profdata_llvm_cov_output(binary_path, source_files)
      output = unsafe_profdata_llvm_cov_output(binary_path, source_files)
      output.valid_encoding? ? output : output.encode!('UTF-8', 'binary', :invalid => :replace, undef: :replace)
    end
    private :profdata_llvm_cov_output

    def dedupe(coverage_files)
      coverage_files.group_by(&:source_file_pathname).values.map { |cf_array| cf_array.max_by(&:percentage_lines_tested) }
    end
    private :dedupe

    def self.yml_filename
      '.slather.yml'
    end

    def self.yml
      @yml ||= File.exist?(yml_filename) ? YAML.load_file(yml_filename) : {}
    end

    def configure
      begin
        configure_scheme
        configure_configuration
        configure_workspace
        configure_build_directory
        configure_ignore_list
        configure_ci_service
        configure_coverage_access_token
        configure_coverage_service
        configure_source_directory
        configure_output_directory
        configure_input_format
        configure_arch
        configure_binary_file
        configure_decimals

        self.llvm_version = `xcrun llvm-cov --version`.match(/LLVM version ([\d\.]+)/).captures[0]
      rescue => e
        puts e.message
        puts failure_help_string
        puts "\n"
        raise
      end

      if self.verbose_mode
        puts "\nProcessing coverage file: #{profdata_file}"
        if self.binary_file
          puts "Against binary files:"
          self.binary_file.each do |binary_file|
            puts "\t#{binary_file}"
          end
        else
          puts "No binary files found."
        end
        puts "\n"
      end
    end

    def configure_build_directory
      self.build_directory ||= self.class.yml["build_directory"] || derived_data_path
    end

    def configure_source_directory
      self.source_directory ||= self.class.yml["source_directory"] if self.class.yml["source_directory"]
    end

    def configure_output_directory
      self.output_directory ||= self.class.yml["output_directory"] if self.class.yml["output_directory"]
    end

    def configure_ignore_list
      self.ignore_list ||= [(self.class.yml["ignore"] || [])].flatten
    end

    def configure_ci_service
      self.ci_service ||= (self.class.yml["ci_service"] || :travis_ci)
    end

    def configure_input_format
      self.input_format ||= (self.class.yml["input_format"] || "auto")
    end

    def input_format=(format)
      format ||= "auto"
      unless %w(gcov profdata auto).include?(format)
        raise StandardError, "Only supported input formats are gcov, profdata or auto"
      end
      if format == "auto"
        @input_format = Slather.xcode_version[0] < 7 ? "gcov" : "profdata"
      else
        @input_format = format
      end
    end

    def configure_scheme
      self.scheme ||= self.class.yml["scheme"] if self.class.yml["scheme"]
    end

    def configure_configuration
      self.configuration ||= self.class.yml["configuration"] if self.class.yml["configuration"]
    end

    def configure_decimals
      return if self.decimals
      self.decimals ||= self.class.yml["decimals"] if self.class.yml["decimals"]
      self.decimals = self.decimals ? Integer(self.decimals) : 2
    end

    def configure_workspace
      self.workspace ||= self.class.yml["workspace"] if self.class.yml["workspace"]
    end

    def ci_service=(service)
      @ci_service = service && service.to_sym
    end

    def configure_coverage_service
      self.coverage_service ||= (self.class.yml["coverage_service"] || :terminal)
    end

    def configure_coverage_access_token
      self.coverage_access_token ||= (ENV["COVERAGE_ACCESS_TOKEN"] || self.class.yml["coverage_access_token"] || "")
    end

    def coverage_service=(service)
      service = service && service.to_sym
      case service
      when :coveralls
        extend(Slather::CoverageService::Coveralls)
      when :hardcover
        extend(Slather::CoverageService::Hardcover)
      when :terminal
        extend(Slather::CoverageService::SimpleOutput)
      when :gutter_json
        extend(Slather::CoverageService::GutterJsonOutput)
      when :cobertura_xml
        extend(Slather::CoverageService::CoberturaXmlOutput)
      when :llvm_cov
        extend(Slather::CoverageService::LlvmCovOutput)
      when :html
        extend(Slather::CoverageService::HtmlOutput)
      when :json
        extend(Slather::CoverageService::JsonOutput)
      else
        raise ArgumentError, "`#{coverage_service}` is not a valid coverage service. Try `terminal`, `coveralls`, `gutter_json`, `cobertura_xml` or `html`"
      end
      @coverage_service = service
    end

    def configure_binary_file
      if self.input_format == "profdata"
        self.binary_file = load_option_array("binary_file") || find_binary_files
      end
    end

    def configure_arch
      self.arch ||= self.class.yml["arch"] if self.class.yml["arch"]
    end

    def decimal_f decimal_arg
      configure_decimals unless decimals
      decimal = "%.#{decimals}f" % decimal_arg
      return decimal if decimals == 2 # special case 2 for backwards compatibility
      decimal.to_f.to_s
    end

    def find_binary_file_in_bundle(bundle_file)
      if File.directory? bundle_file
        bundle_file_noext = File.basename(bundle_file, File.extname(bundle_file))
        Dir["#{bundle_file}/**/#{bundle_file_noext}"].first
      else
        bundle_file
      end
    end

    def find_binary_files
      binary_basename = load_option_array("binary_basename")
      found_binaries = []

      # Get scheme info out of the xcodeproj
      if self.scheme
        schemes_path = Xcodeproj::XCScheme.shared_data_dir(self.path)
        xcscheme_path = "#{schemes_path + self.scheme}.xcscheme"

        # Try to look inside 'xcuserdata' if the scheme is not found in 'xcshareddata'
        if !File.file?(xcscheme_path)
          schemes_path = Xcodeproj::XCScheme.user_data_dir(self.path)
          xcscheme_path = "#{schemes_path + self.scheme}.xcscheme"
        end

        if self.workspace and !File.file?(xcscheme_path)
          # No scheme was found in the xcodeproj, check the workspace
          schemes_path = Xcodeproj::XCScheme.shared_data_dir(self.workspace)
          xcscheme_path = "#{schemes_path + self.scheme}.xcscheme"

          if !File.file?(xcscheme_path)
            schemes_path = Xcodeproj::XCScheme.user_data_dir(self.workspace)
            xcscheme_path = "#{schemes_path + self.scheme}.xcscheme"
          end
        end

        raise StandardError, "No scheme named '#{self.scheme}' found in #{self.path}" unless File.exists? xcscheme_path

        xcscheme = Xcodeproj::XCScheme.new(xcscheme_path)

        if self.configuration
          configuration = self.configuration
        else
          configuration = xcscheme.test_action.build_configuration
        end

        search_list = binary_basename || find_buildable_names(xcscheme)
        search_dir = profdata_coverage_dir

        if Slather.xcode_version[0] >= 9
          # Go from the directory containing Coverage.profdata back to the directory containing Products (back out of ProfileData/UUID-dir)
          search_dir = File.join(search_dir, '../..')
        end

        search_list.each do |search_for|
          found_product = Dir["#{search_dir}/Products/#{configuration}*/#{search_for}*"].sort { |x, y|
            # Sort the matches without the file extension to ensure better matches when there are multiple candidates
            # For example, if the binary_basename is Test then we want Test.app to be matched before Test Helper.app
            File.basename(x, File.extname(x)) <=> File.basename(y, File.extname(y))
          }.find { |path|
            next if path.end_with? ".dSYM"
            next if path.end_with? ".swiftmodule"

            if File.directory? path
              path = find_binary_file_in_bundle(path)
              next if path.nil?
            end

            matches_arch(path)
          }

          if found_product and File.directory? found_product
            found_binary = find_binary_file_in_bundle(found_product)
          else
            found_binary = found_product
          end

          if found_binary
            found_binaries.push(found_binary)
          end
        end
      else
        xctest_bundle = Dir["#{profdata_coverage_dir}/**/*.xctest"].reject { |bundle|
            # Ignore xctest bundles that are in the UI runner app
            bundle.include? "-Runner.app/PlugIns/"
        }.first

        # Find the matching binary file
        search_list = binary_basename || ['*']

        search_list.each do |search_for|
          xctest_bundle_file_directory = Pathname.new(xctest_bundle).dirname
          app_bundle = Dir["#{xctest_bundle_file_directory}/#{search_for}.app"].first
          matched_xctest_bundle = Dir["#{xctest_bundle_file_directory}/#{search_for}.xctest"].first
          dynamic_lib_bundle = Dir["#{xctest_bundle_file_directory}/#{search_for}.{framework,dylib}"].first

          if app_bundle != nil
            found_binary = find_binary_file_in_bundle(app_bundle)
          elsif matched_xctest_bundle != nil
            found_binary = find_binary_file_in_bundle(matched_xctest_bundle)
          elsif dynamic_lib_bundle != nil
            found_binary = find_binary_file_in_bundle(dynamic_lib_bundle)
          else
            found_binary = find_binary_file_in_bundle(xctest_bundle)
          end

          if found_binary
            found_binaries.push(found_binary)
          end
        end
      end

      raise StandardError, "No product binary found in #{profdata_coverage_dir}." unless found_binaries.count > 0

      found_binaries.map { |binary| File.expand_path(binary) }
    end

    def find_buildable_names(xcscheme)
      found_buildable_names = []

      # enumerate build action entries
      begin
        xcscheme.build_action.entries.each do |entry|
          buildable_name = entry.buildable_references[0].buildable_name

          if !buildable_name.end_with? ".a"
            # Can't run code coverage on static libraries
            found_buildable_names.push(buildable_name)
          end
        end
      rescue
        # xcodeproj will raise an exception if there are no entries in the build action
      end

      # enumerate test action entries
      begin
        xcscheme.test_action.testables.each do |entry|
          buildable_name = entry.buildable_references[0].buildable_name
          found_buildable_names.push(buildable_name)
        end
      rescue
        # just in case if there are no entries in the test action
      end

      # some items are both buildable and testable, so return only unique ones
      found_buildable_names.uniq
    end

    def matches_arch(binary_path)
      if self.arch
        lipo_output = `lipo -info "#{binary_path}"`
        archs_in_binary = lipo_output.split(':').last.split(' ')
        archs_in_binary.include? self.arch
      else
        true
      end
    end

    def find_source_files
      source_files = load_option_array("source_files")
      return if source_files.nil?

      current_dir = Pathname("./").realpath
      paths = source_files.flat_map { |pattern| Dir.glob(pattern) }.uniq

      paths.map do |path|
        source_file_absolute_path = Pathname(path).realpath
        source_file_relative_path = source_file_absolute_path.relative_path_from(current_dir)
        self.ignore_list.any? { |ignore| File.fnmatch(ignore, source_file_relative_path) } ? nil : source_file_absolute_path
      end.compact
    end

    def load_option_array(option)
      value = self.send(option.to_sym)
      # Only load if a value is not already set
      if !value
        value_yml = self.class.yml[option]
        # Need to check the type in the config file because it can be a string or array
        if value_yml and value_yml.is_a? Array
          value = value_yml
        elsif value_yml
          value = [value_yml]
        end
      end
      value
    end
  end
end
