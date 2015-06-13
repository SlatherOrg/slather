require 'fileutils'
require 'xcodeproj'
require 'json'
require 'yaml'

module Xcodeproj
  class Project

    def slather_setup_for_coverage
      build_configurations.each do |build_configuration|
        build_configuration.build_settings["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"] = "YES"
        build_configuration.build_settings["GCC_GENERATE_TEST_COVERAGE_FILES"] = "YES"
      end
    end

  end
end

module Slather
  class Project < Xcodeproj::Project

    attr_accessor :build_directory, :ignore_list, :ci_service, :coverage_service, :coverage_access_token, :source_directory, :output_directory, :input_format, :scheme

    alias_method :setup_for_coverage, :slather_setup_for_coverage

    def self.open(xcodeproj)
      proj = super
      proj.configure_from_yml
      proj
    end

    def derived_data_dir
      File.expand_path('~') + "/Library/Developer/Xcode/DerivedData/"
    end
    private :derived_data_dir

    def build_directory
      @build_directory || derived_data_dir
    end

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
        raise StandardError, "No coverage files found. Are you sure your project is setup for generating coverage files? Try `slather setup your/project.pbxproj`"
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
      end
    end
    private :profdata_coverage_files

    def profdata_coverage_dir
      if self.scheme
        Dir["#{build_directory}/**/CodeCoverage/#{self.scheme}"].first
      else
        Dir["#{build_directory}/**/#{self.products.first.name}"].first
      end
    end

    def binary_file
      xctest_bundle_file = Dir["#{profdata_coverage_dir}/**/*.xctest"].first
      if xctest_bundle_file == nil
        raise StandardError, "No product binary found in #{profdata_coverage_dir}"
      end

      # Find the matching .app, if any
      xctest_bundle_file_directory = Pathname.new(xctest_bundle_file).dirname

      app_bundle_file = Dir["#{xctest_bundle_file_directory}/*.app"].first
      if app_bundle_file != nil
        app_bundle_file_name_noext = Pathname.new(app_bundle_file).basename.to_s.gsub(".app", "")
        "#{app_bundle_file}/#{app_bundle_file_name_noext}"
      else
        xctest_bundle_file_name_noext = Pathname.new(xctest_bundle_file).basename.to_s.gsub(".xctest", "")
        "#{xctest_bundle_file}/#{xctest_bundle_file_name_noext}"
      end
    end
    private :binary_file

    def profdata_llvm_cov_output
      profdata_coverage_dir = self.profdata_coverage_dir
      if profdata_coverage_dir == nil || (coverage_profdata = Dir["#{profdata_coverage_dir}/**/Coverage.profdata"].first) == nil
        raise StandardError, "No Coverage.profdata files found. Please make sure the \"Code Coverage\" checkbox is enabled in your scheme's Test action or the build_directory property is set."
      end
      xcode_path = `xcode-select -p`.strip
      llvm_cov_command = xcode_path + "Toolchains/XcodeDefault.xctoolchain/usr/bin/llvm-cov show -instr-profile #{coverage_profdata} #{binary_file}"
      `#{llvm_cov_command}`
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

    def configure_from_yml
      configure_build_directory_from_yml
      configure_ignore_list_from_yml
      configure_ci_service_from_yml
      configure_coverage_access_token_from_yml
      configure_coverage_service_from_yml
      configure_source_directory_from_yml
      configure_output_directory_from_yml
      configure_input_format_from_yml
      configure_scheme_from_yml
    end

    def configure_build_directory_from_yml
      self.build_directory = self.class.yml["build_directory"] if self.class.yml["build_directory"] && !@build_directory
    end

    def configure_source_directory_from_yml
      self.source_directory ||= self.class.yml["source_directory"] if self.class.yml["source_directory"]
    end

    def configure_output_directory_from_yml
      self.output_directory ||= self.class.yml["output_directory"] if self.class.yml["output_directory"]
    end

    def configure_ignore_list_from_yml
      self.ignore_list ||= [(self.class.yml["ignore"] || [])].flatten
    end

    def configure_ci_service_from_yml
      self.ci_service ||= (self.class.yml["ci_service"] || :travis_ci)
    end

    def configure_input_format_from_yml
      self.input_format ||= self.class.yml["input_format"] if self.class.yml["input_format"]
    end

    def configure_scheme_from_yml
      self.scheme ||= self.class.yml["scheme"] if self.class.yml["scheme"]
    end

    def ci_service=(service)
      @ci_service = service && service.to_sym
    end

    def configure_coverage_service_from_yml
      self.coverage_service ||= (self.class.yml["coverage_service"] || :terminal)
    end

    def configure_coverage_access_token_from_yml
      self.coverage_access_token ||= (ENV["COVERAGE_ACCESS_TOKEN"] || self.class.yml["coverage_access_token"] || "")
    end

    def coverage_service=(service)
      service = service && service.to_sym
      if service == :coveralls
        extend(Slather::CoverageService::Coveralls)
      elsif service == :hardcover
        extend(Slather::CoverageService::Hardcover)
      elsif service == :terminal
        extend(Slather::CoverageService::SimpleOutput)
      elsif service == :gutter_json
        extend(Slather::CoverageService::GutterJsonOutput)
      elsif service == :cobertura_xml
        extend(Slather::CoverageService::CoberturaXmlOutput)
      else
        raise ArgumentError, "`#{coverage_service}` is not a valid coverage service. Try `terminal`, `coveralls`, `gutter_json` or `cobertura_xml`"
      end
      @coverage_service = service
    end
  end
end

