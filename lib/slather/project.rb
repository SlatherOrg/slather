require 'fileutils'
require 'xcodeproj'
require 'json'

module Slather
  class Project < Xcodeproj::Project

    attr_accessor :build_directory, :ignore_list

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

  end
end