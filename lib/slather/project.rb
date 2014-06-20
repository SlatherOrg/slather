require 'fileutils'
require 'xcodeproj'
require 'json'
require 'yaml'

module Slather
  class Project < Xcodeproj::Project

    attr_accessor :build_directory, :ignore_list

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
    private :build_directory

    def coverage_files
      Dir["#{build_directory}/**/*.gcno"].map do |file|
        coverage_file = coverage_file_class.new(file)
        coverage_file.project = self
        # If there's no source file for this gcno, it probably belongs to another project.
        puts regex
        if coverage_file.source_file_pathname && !(coverage_file.source_file_pathname_relative_to_project_root.to_s =~ /^(#{ignore_list.join("|")})$/)
          coverage_file
        else
          nil
        end
      end.compact
    end
    private :coverage_files

    def coveralls_coverage_data
      {
        :service_job_id => ENV['TRAVIS_JOB_ID'],
        :service_name => "travis-ci",
        :source_files => coverage_files.map(&:as_json)
      }.to_json
    end
    private :coveralls_coverage_data

    def post_to_coveralls
      f = File.open('coveralls_json_file', 'w+')
      f.write(coveralls_coverage_data)
      `curl -s --form json_file=@#{f.path} https://coveralls.io/api/v1/jobs`
      FileUtils.rm(f)
    end

    def self.yml_file
      @yml_file ||= begin
        yml_filename = '.slather.yml'
        if File.exist?(yml_filename)
          YAML.load_file(yml_filename)
        else
          {}
        end
      end
    end

    def configure_from_yml
      self.build_directory = self.class.yml_file["build_directory"] if self.class.yml_file["build_directory"]
      self.ignore_list = self.class.yml_file["ignore"] || []

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
end