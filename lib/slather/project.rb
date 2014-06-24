require 'fileutils'
require 'xcodeproj'
require 'json'
require 'yaml'

module Slather
  class Project < Xcodeproj::Project

    attr_accessor :build_directory, :ignore_list, :ci_service

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
        coverage_file = coverage_file_class.new(file)
        coverage_file.project = self
        # If there's no source file for this gcno, it probably belongs to another project.
        if coverage_file.source_file_pathname && !coverage_file.ignored?
          coverage_file
        else
          nil
        end
      end.compact

      if coverage_files.empty?
        raise StandardError, "No coverage files found. Are you sure your project is setup for generating coverage files? Try `slather setup your/project.pbxproj`"
      else
        coverage_files
      end
    end
    private :coverage_files

    def self.yml_file
      @yml_file ||= begin
        yml_filename = '.slather.yml'
        if File.exist?(yml_filename)
          YAML.load_file(yml_filename)
        else
          nil
        end
      end
    end

    def configure_from_yml
      if self.class.yml_file
        self.build_directory = self.class.yml_file["build_directory"] if self.class.yml_file["build_directory"]
        self.ignore_list = self.class.yml_file["ignore"] || []
        self.ci_service = (self.class.yml_file["ci_service"] || :travis_ci).to_sym

        coverage_service = self.class.yml_file["coverage_service"]
        if coverage_service == "coveralls"
          extend(Slather::CoverageService::Coveralls)
        elsif coverage_service == "terminal"
          extend(Slather::CoverageService::SimpleOutput)
        elsif !self.class.method_defined?(:post)
          raise ArgumentError, "value `#{coverage_service}` not valid for key `coverage_service` in #{self.class.yml_file.path}. Try `terminal` or `coveralls`"
        end
      end
    end

    def setup_for_coverage
      build_configurations.each do |build_configuration|
        build_configuration.build_settings["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"] = "YES"
        build_configuration.build_settings["GCC_GENERATE_TEST_COVERAGE_FILES"] = "YES"
      end
    end

  end
end