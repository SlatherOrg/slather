module Slather
  module CoverageService
    module Coveralls

      def coverage_file_class
        Slather::CoverallsCoverageFile
      end
      private :coverage_file_class

      def travis_job_id
        ENV['TRAVIS_JOB_ID']
      end
      private :travis_job_id

      def coveralls_coverage_data
        if ci_service == :travis_ci || ci_service == :travis_pro
          if travis_job_id
            if ci_service == :travis_ci
              {
                :service_job_id => travis_job_id,
                :service_name => "travis-ci",
                :source_files => coverage_files.map(&:as_json)
              }.to_json
            elsif ci_service == :travis_pro
              {
                :service_job_id => travis_job_id,
                :service_name => "travis-pro",
                :repo_token => ci_access_token,
                :source_files => coverage_files.map(&:as_json)
              }.to_json
            end
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
        begin
          f.write(coveralls_coverage_data)
          f.close
          `curl -s --form json_file=@#{f.path} #{coveralls_api_jobs_path}`
        rescue StandardError => e
          FileUtils.rm(f)
          raise e
        end
        FileUtils.rm(f)
      end

      def coveralls_api_jobs_path
        "https://coveralls.io/api/v1/jobs"
      end
      private :coveralls_api_jobs_path

    end
  end
end