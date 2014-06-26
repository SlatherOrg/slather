require 'fileutils'
require 'xcodeproj'
require 'json'
require 'yaml'

module Slather
  class Project < Xcodeproj::Project

    attr_accessor :build_directory, :ignore_list, :ci_service, :coverage_service

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
      coverage_files = Dir["#{build_directory}/**/*.gcno"].map do |file|
        coverage_file = coverage_file_class.new(self, file)
        # If there's no source file for this gcno, it probably belongs to another project.
        coverage_file.source_file_pathname && !coverage_file.ignored? ? coverage_file : nil
      end.compact

      if coverage_files.empty?
        raise StandardError, "No coverage files found. Are you sure your project is setup for generating coverage files? Try `slather setup your/project.pbxproj`"
      else
        coverage_files
      end
    end
    private :coverage_files

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
      configure_coverage_service_from_yml
    end

    def configure_build_directory_from_yml
      self.build_directory = self.class.yml["build_directory"] if self.class.yml["build_directory"] && !@build_directory
    end

    def configure_ignore_list_from_yml
      self.ignore_list ||= [(self.class.yml["ignore"] || [])].flatten
    end

    def configure_ci_service_from_yml
      self.ci_service ||= (self.class.yml["ci_service"] || :travis_ci)
    end

    def ci_service=(service)
      @ci_service = service && service.to_sym
    end

    def configure_coverage_service_from_yml
      self.coverage_service ||= (self.class.yml["coverage_service"] || :terminal)
    end

    def coverage_service=(service)
      service = service && service.to_sym
      if service == :coveralls
        extend(Slather::CoverageService::Coveralls)
      elsif service == :terminal
        extend(Slather::CoverageService::SimpleOutput)
      else
        raise ArgumentError, "`#{coverage_service}` is not a valid coverage service. Try `terminal` or `coveralls`"
      end
      @coverage_service = service
    end

    def setup_for_coverage
      build_configurations.each do |build_configuration|
        build_configuration.build_settings["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"] = "YES"
        build_configuration.build_settings["GCC_GENERATE_TEST_COVERAGE_FILES"] = "YES"
      end
    end

  end
end

