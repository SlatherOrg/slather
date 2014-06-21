module Slather
  module CoverageService
    module Coveralls

      def coverage_file_class
        Slather::CoverallsCoverageFile
      end

      def travis_job_id
        ENV['TRAVIS_JOB_ID']
      end

      def coveralls_coverage_data
        if ci_service == :travis_ci
          if travis_job_id
            {
              :service_job_id => travis_job_id,
              :service_name => "travis-ci",
              :source_files => coverage_files.map(&:as_json)
            }.to_json
          else
            raise StandardError, "Environment variable `TRAVIS_JOB_ID` not set. Is this running on a travis build?"
          end
        else
          raise StandardError, "No support for ci named #{ci_service}"
        end
      end
      private :coveralls_coverage_data

      def post
        f = File.open('coveralls_json_file', 'w+')
        f.write(coveralls_coverage_data)
        `curl -s --form json_file=@#{f.path} #{coveralls_api_jobs_path}`
        FileUtils.rm(f)
      end

      def coveralls_api_jobs_path
        "https://coveralls.io/api/v1/jobs"
      end

    end
  end
end