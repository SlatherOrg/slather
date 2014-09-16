module Slather
  module CoverageService
    module Hardcover

      def yml_filename
        '.hardcover.yml'
      end

      def yml
        @yml ||= if File.exists?(yml_filename)
                   YAML.load_file(yml_filename)
                 else
                   raise StandardError, "No .hardcover.yml found"
                 end
      end

      def coverage_file_class
        Slather::CoverallsCoverageFile
      end
      private :coverage_file_class

      def travis_job_id
        ENV['TRAVIS_JOB_ID']
      end
      private :travis_job_id

      def jenkins_job_id
        "#{ENV['JOB_NAME']}/#{ENV['BUILD_NUMBER']}"
      end
      private :jenkins_job_id

      def hardcover_coverage_data
        if ci_service == :travis_ci
          if travis_job_id
            {
              :service_job_id => travis_job_id,
              :service_name => "travis-ci",
              :repo_token => yml["repo_token"],
              :source_files => coverage_files.map(&:as_json)
            }.to_json
          else
            raise StandardError, "Environment variable `TRAVIS_JOB_ID` not set. Is this running on a travis build?"
          end
        elsif ci_service == :jenkins_ci
          if jenkins_job_id
            {
              :service_job_id => jenkins_job_id,
              :service_name => "jenkins-ci",
              :repo_token => yml["repo_token"],
              :source_files => coverage_files.map(&:as_json)
            }.to_json
          else
            raise StandardError, "Environment variables `BUILD_NUMBER` and `JOB_NAME` are not set. Is this running on a Jenkins build?"
          end
        else
          raise StandardError, "No support for ci named #{ci_service}"
        end
      end
      private :hardcover_coverage_data

      def post
        f = File.open('hardcover_json_file', 'w+')
        begin
          f.write(hardcover_coverage_data)
          f.close
          `curl -s --form json_file=@#{f.path} #{hardcover_api_jobs_path}`
        rescue StandardError => e
          FileUtils.rm(f)
          raise e
        end
        FileUtils.rm(f)
      end

      def hardcover_api_jobs_path
        "#{hardcover_base_url}/v1/jobs"
      end
      private :hardcover_api_jobs_path

      def hardcover_base_url
        url = yml["base_url"]
        unless url
          raise "No `base_url` configured. Please add it to your `.hardcover.yml`"
        end
        url
      end
      private :hardcover_base_url
    end
  end
end
