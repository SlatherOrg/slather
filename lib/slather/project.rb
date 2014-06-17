require 'fileutils'
require 'xcodeproj'
require 'json'

module Slather
  class Project < Xcodeproj::Project

    def derived_data_dir
      File.expand_path('~') + "/Library/Developer/Xcode/DerivedData/"
    end
    private :derived_data_dir

    def coverage_files
      Dir["#{derived_data_dir}/**/*.gcno"].map do |file|
        coverage_file = Slather::CoverallsCoverageFile.new(file)
        coverage_file.project = self
        # If there's no source file for this gcno, or the gcno is old, it probably belongs to another project.
        if coverage_file.source_file_pathname
          stale_seconds_limit = 60
          if (Time.now - File.mtime(file) < stale_seconds_limit)
            next coverage_file
          else
            puts "Skipping #{file} -- older than #{stale_seconds_limit} seconds ago."
          end
        end
        next nil
      end.compact
    end
    private :coverage_files

    def coveralls_coverage_data
      {
        :service_job_id => ENV['TRAVIS_JOB_ID'] || 27647662,
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