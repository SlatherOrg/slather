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

      def circleci_job_id
        ENV['CIRCLE_BUILD_NUM']
      end
      private :circleci_job_id

      def circleci_pull_request
        ENV['CI_PULL_REQUEST']
      end
      private :circleci_pull_request

      def jenkins_job_id
        ENV['BUILD_ID']
      end
      private :jenkins_job_id

      def jenkins_git_info
        {
          head: {
            id: ENV['sha1'],
            author_name: ENV['ghprbActualCommitAuthor'],
            message: ENV['ghprbPullTitle']
          },
          branch: ENV['ghprbSourceBranch']
        }

        ENV['GIT_BRANCH']
      end
      private :jenkins_git_info

      def circleci_git_info
        {
          :head => {
            :id => (ENV['CIRCLE_SHA1'] || ""),
            :author_name => (ENV['CIRCLE_USERNAME'] || ""),
            :message => (`git log --format=%s -n 1 HEAD`.chomp || "")
          },
          :branch => (ENV['CIRCLE_BRANCH'] || "")
        }
      end
      private :circleci_git_info

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
        elsif ci_service == :circleci
          if circleci_job_id
            coveralls_hash = {
              :service_job_id => circleci_job_id,
              :service_name => "circleci",
              :repo_token => ci_access_token,
              :source_files => coverage_files.map(&:as_json),
              :git => circleci_git_info
            }

            if circleci_pull_request != nil && circleci_pull_request.length > 0
              coveralls_hash[:service_pull_request] = circleci_pull_request.split("/").last
            end

            coveralls_hash.to_json
          else
            raise StandardError, "Environment variable `CIRCLE_BUILD_NUM` not set. Is this running on a circleci build?"
          end
        elsif ci_service == :jenkins
          if jenkins_job_id
            {
              service_job_id: jenkins_job_id,
              service_name: "jenkins",
              repo_token: ci_access_token,
              source_files: coverage_files.map(&:as_json),
              git: jenkins_git_info
            }.to_json
          else
            raise StandardError, "Environment variable `BUILD_ID` not set. Is this running on a jenkins build?"
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