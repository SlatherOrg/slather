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
        if Gem::Requirement.new('~> 0.27') =~ Gem::Version.new(Xcodeproj::VERSION)
          # @todo This will require to bump the xcodeproj dependency to ~> 0.27
          # (which would require to bump cocoapods too)
          schemes_path = Xcodeproj::XCScheme.shared_data_dir(self.path)
          Xcodeproj::Project.schemes(self.path).each do |scheme_name|
            xcscheme_path = "#{schemes_path + scheme_name}.xcscheme"
            xcscheme = Xcodeproj::XCScheme.new(xcscheme_path)
            xcscheme.test_action.xml_element.attributes['codeCoverageEnabled'] = 'YES'
            xcscheme.save_as(self.path, scheme_name)
          end
        else
          # @todo In the meantime, simply inform the user to do it manually
          puts %Q(Ensure you enabled "Gather coverage data" in each of your scheme's Test action)
        end
      end
    end

  end
end

module Slather
  class Project < Xcodeproj::Project

    attr_accessor :build_directory, :ignore_list, :ci_service, :coverage_service, :coverage_access_token, :source_directory,
      :output_directory, :xcodeproj, :show_html, :verbose_mode, :input_format, :scheme, :workspace, :binary_file, :binary_basename

    alias_method :setup_for_coverage, :slather_setup_for_coverage

    def self.open(xcodeproj)
      proj = super
      proj.xcodeproj = xcodeproj
      proj
    end

    def failure_help_string
      "\n\tAre you sure your project is generating coverage? Make sure you enable code coverage in the Test section of your Xcode scheme.\n\tDid you specify your Xcode scheme? (--scheme or 'scheme' in .slather.yml)\n\tIf you're using a workspace, did you specify it? (--workspace or 'workspace' in .slather.yml)"
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

      build_settings = `xcodebuild #{projectOrWorkspaceArgument} #{schemeArgument} -showBuildSettings #{buildAction}`

      if build_settings
        derived_data_path = build_settings.match(/ OBJROOT = (.+)/)[1]
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
    private :coverage_files

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
      files = profdata_llvm_cov_output.split("\n\n")

      files.map do |source|
        coverage_file = coverage_file_class.new(self, source)
        !coverage_file.ignored? ? coverage_file : nil
      end.compact
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
        dir = Dir[File.join("#{build_directory}","/**/CodeCoverage/#{self.scheme}")].first
      else
        dir = Dir[File.join("#{build_directory}","/**/#{first_product_name}")].first
      end

      if dir == nil
        # Xcode 7.3 moved the location of Coverage.profdata
        dir = Dir[File.join("#{build_directory}","/**/CodeCoverage")].first
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

    def unsafe_profdata_llvm_cov_output
      profdata_file_arg = profdata_file
      if profdata_file_arg == nil
        raise StandardError, "No Coverage.profdata files found. Please make sure the \"Code Coverage\" checkbox is enabled in your scheme's Test action or the build_directory property is set."
      end

      if self.binary_file == nil
        raise StandardError, "No binary file found."
      end

      llvm_cov_args = %W(show -instr-profile #{profdata_file_arg} #{self.binary_file})
      `xcrun llvm-cov #{llvm_cov_args.shelljoin}`
    end
    private :unsafe_profdata_llvm_cov_output

    def profdata_llvm_cov_output
      unsafe_profdata_llvm_cov_output.encode!('UTF-8', 'binary', :invalid => :replace, undef: :replace)
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
        configure_workspace
        configure_build_directory
        configure_ignore_list
        configure_ci_service
        configure_coverage_access_token
        configure_coverage_service
        configure_source_directory
        configure_output_directory
        configure_input_format
        configure_binary_file
      rescue => e
        puts e.message
        puts failure_help_string
        puts "\n"
        raise
      end

      if self.verbose_mode
        puts "\nProcessing coverage file: #{profdata_file}"
        puts "Against binary file: #{self.binary_file}\n\n"
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
      self.input_format ||= self.class.yml["input_format"] || input_format
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
      when :html
        extend(Slather::CoverageService::HtmlOutput)
      else
        raise ArgumentError, "`#{coverage_service}` is not a valid coverage service. Try `terminal`, `coveralls`, `gutter_json`, `cobertura_xml` or `html`"
      end
      @coverage_service = service
    end

    def configure_binary_file
      if self.input_format == "profdata"
        self.binary_file ||= self.class.yml["binary_file"] || File.expand_path(find_binary_file)
      end
    end

    def find_binary_file_in_bundle(bundle_file)
      bundle_file_noext = File.basename(bundle_file, File.extname(bundle_file))
      Dir["#{bundle_file}/**/#{bundle_file_noext}"].first
    end

    def find_binary_file
      binary_basename = self.binary_basename || self.class.yml["binary_basename"] || nil

      # Get scheme info out of the xcodeproj
      if self.scheme
        schemes_path = Xcodeproj::XCScheme.shared_data_dir(self.path)
        xcscheme_path = "#{schemes_path + self.scheme}.xcscheme"

        # Try to look inside 'xcuserdata' if the scheme is not found in 'xcshareddata'
        if !File.file?(xcscheme_path)
          schemes_path = Xcodeproj::XCScheme.user_data_dir(self.path)
          xcscheme_path = "#{schemes_path + self.scheme}.xcscheme"
        end

        raise StandardError, "No scheme named '#{self.scheme}' found in #{self.path}" unless File.exists? xcscheme_path

        xcscheme = Xcodeproj::XCScheme.new(xcscheme_path)

        begin
          buildable_name = xcscheme.build_action.entries[0].buildable_references[0].buildable_name
        rescue
          # xcodeproj will raise an exception if there are no entries in the build action
        end

        if buildable_name == nil or buildable_name.end_with? ".a"
          # Can't run code coverage on static libraries, look for an associated test bundle
          buildable_name = xcscheme.test_action.testables[0].buildable_references[0].buildable_name
        end

        configuration = xcscheme.test_action.build_configuration

        search_for = binary_basename || buildable_name
        found_product = Dir["#{profdata_coverage_dir}/Products/#{configuration}*/#{search_for}*"].sort { |x, y|
          # Sort the matches without the file extension to ensure better matches when there are multiple candidates
          # For example, if the binary_basename is Test then we want Test.app to be matched before Test Helper.app
          File.basename(x, File.extname(x)) <=> File.basename(y, File.extname(y))
        }.reject { |path|
          path.end_with? ".dSYM"
        }.first

        if found_product and File.directory? found_product
          found_binary = find_binary_file_in_bundle(found_product)
        else
          found_binary = found_product
        end
      else
        xctest_bundle = Dir["#{profdata_coverage_dir}/**/*.xctest"].reject { |bundle|
            # Ignore xctest bundles that are in the UI runner app
            bundle.include? "-Runner.app/PlugIns/"
        }.first

        # Find the matching binary file
        search_for = binary_basename || '*'
        xctest_bundle_file_directory = Pathname.new(xctest_bundle).dirname
        app_bundle = Dir["#{xctest_bundle_file_directory}/#{search_for}.app"].first
        dynamic_lib_bundle = Dir["#{xctest_bundle_file_directory}/#{search_for}.framework"].first
        matched_xctest_bundle = Dir["#{xctest_bundle_file_directory}/#{search_for}.xctest"].first

        if app_bundle != nil
            found_binary = find_binary_file_in_bundle(app_bundle)
        elsif dynamic_lib_bundle != nil
            found_binary = find_binary_file_in_bundle(dynamic_lib_bundle)
        elsif matched_xctest_bundle != nil
            found_binary = find_binary_file_in_bundle(matched_xctest_bundle)
        else
            found_binary = find_binary_file_in_bundle(xctest_bundle)
        end
      end

      raise StandardError, "No product binary found in #{profdata_coverage_dir}." unless found_binary != nil

      found_binary
    end
  end
end
