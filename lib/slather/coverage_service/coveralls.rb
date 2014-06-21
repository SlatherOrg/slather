module Slather
  module CoverageService
    module Coveralls

      def coverage_file_class
        Slather::CoverallsCoverageFile
      end

      def coveralls_coverage_data
        if ci_service == :travis_ci
          if ENV['TRAVIS_JOB_ID']
            {
              :service_job_id => ENV['TRAVIS_JOB_ID'],
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
        `curl -s --form json_file=@#{f.path} https://coveralls.io/api/v1/jobs`
        FileUtils.rm(f)
      end

    end
  end
end