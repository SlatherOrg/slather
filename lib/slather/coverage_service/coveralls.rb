module Slather
  module CoverageService
    module Coveralls

      def coverage_file_class
        if input_format == "profdata"
          Slather::ProfdataCoverageFile
        else
          Slather::CoverageFile
        end
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
        ENV['CIRCLE_PR_NUMBER'] || ENV['CI_PULL_REQUEST'] || ""
      end
      private :circleci_pull_request

      def teamcity_job_id
        ENV['TC_BUILD_NUMBER']
      end
      private :teamcity_job_id

      def jenkins_job_id
        ENV['BUILD_ID']
      end
      private :jenkins_job_id

      def jenkins_branch_name
        branch_name = ENV['GIT_BRANCH']
        if branch_name.include? 'origin/'
          branch_name[7...branch_name.length]
        else
          branch_name
        end
      end
      private :jenkins_branch_name

      def teamcity_branch_name
        ENV['GIT_BRANCH'] || `git ls-remote --heads origin | grep $(git rev-parse HEAD) | cut -d / -f 3-`.chomp
      end
      private :teamcity_branch_name

      def buildkite_job_id
        ENV['BUILDKITE_BUILD_NUMBER']
      end
      private :buildkite_job_id

      def buildkite_pull_request
        ENV['BUILDKITE_PULL_REQUEST']
      end
      private :buildkite_pull_request

      def jenkins_git_info
        {
          head: {
            id: ENV['sha1'],
            author_name: ENV['ghprbActualCommitAuthor'],
            message: ENV['ghprbPullTitle']
          },
          branch: jenkins_branch_name
        }
      end
      private :jenkins_git_info

      def teamcity_git_info
        {
          head: {
            :id => (`git log --format=%H -n 1 HEAD`.chomp || ""),
            :author_name => (`git log --format=%an -n 1 HEAD`.chomp || ""),
            :author_email => (`git log --format=%ae -n 1 HEAD`.chomp || ""),
            :message => (`git log --format=%s -n 1 HEAD`.chomp || "")
          },
          :branch => teamcity_branch_name
        }
      end
      private :teamcity_git_info

      def circleci_build_url
        "https://circleci.com/gh/" + ENV['CIRCLE_PROJECT_USERNAME'] || "" + "/" + ENV['CIRCLE_PROJECT_REPONAME'] || "" + "/" + ENV['CIRCLE_BUILD_NUM'] || ""
      end
      private :circleci_build_url

      def circleci_git_info
        {
          :head => {
            :id => (ENV['CIRCLE_SHA1'] || ""),
            :author_name => (ENV['CIRCLE_PR_USERNAME'] || ENV['CIRCLE_USERNAME'] || ""),
            :message => (`git log --format=%s -n 1 HEAD`.chomp || "")
          },
          :branch => (ENV['CIRCLE_BRANCH'] || "")
        }
      end
      private :circleci_git_info

      def buildkite_git_info
        {
          :head => {
            :id => ENV['BUILDKITE_COMMIT'],
            :author_name => (`git log --format=%an -n 1 HEAD`.chomp || ""),
            :author_email => (`git log --format=%ae -n 1 HEAD`.chomp || ""),
            :message => (`git log --format=%s -n 1 HEAD`.chomp || "")
          },
          :branch => ENV['BUILDKITE_BRANCH']
        }
      end

      def buildkite_build_url
        "https://buildkite.com/" + ENV['BUILDKITE_PROJECT_SLUG'] + "/builds/" + ENV['BUILDKITE_BUILD_NUMBER'] + "#"
      end

      def coveralls_coverage_data
        if ci_service == :travis_ci || ci_service == :travis_pro
          if travis_job_id
            if ci_service == :travis_ci
              
              if coverage_access_token.to_s.strip.length > 0
                raise StandardError, "Access token is set. Uploading coverage data for public repositories doesn't require an access token."
              end

              {
                :service_job_id => travis_job_id,
                :service_name => "travis-ci",
                :source_files => coverage_files.map(&:as_json)
              }.to_json
            elsif ci_service == :travis_pro              

              if coverage_access_token.to_s.strip.length == 0
                raise StandardError, "Access token is not set. Uploading coverage data for private repositories requires an access token."
              end

              {
                :service_job_id => travis_job_id,
                :service_name => "travis-pro",
                :repo_token => coverage_access_token,
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
              :repo_token => coverage_access_token,
              :source_files => coverage_files.map(&:as_json),
              :git => circleci_git_info,
              :service_build_url => circleci_build_url
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
              repo_token: coverage_access_token,
              source_files: coverage_files.map(&:as_json),
              git: jenkins_git_info
            }.to_json
          else
            raise StandardError, "Environment variable `BUILD_ID` not set. Is this running on a jenkins build?"
          end
        elsif ci_service == :buildkite
          if buildkite_job_id
            {
              :service_job_id => buildkite_job_id,
              :service_name => "buildkite",
              :repo_token => coverage_access_token,
              :source_files => coverage_files.map(&:as_json),
              :git => buildkite_git_info,
              :service_build_url => buildkite_build_url,
              :service_pull_request => buildkite_pull_request
            }.to_json
          else
            raise StandardError, "Environment variable `BUILDKITE_BUILD_NUMBER` not set. Is this running on a buildkite build?"
          end
        elsif ci_service == :teamcity
          if teamcity_job_id
            {
              :service_job_id => teamcity_job_id,
              :service_name => "teamcity",
              :repo_token => coverage_access_token,
              :source_files => coverage_files.map(&:as_json),
              :git => teamcity_git_info
            }.to_json
          end
        else
          raise StandardError, "No support for ci named #{ci_service}"
        end
      end
      private :coveralls_coverage_data

      def post
        puts "Uploading coverage data to Coveralls..."
        f = File.open('coveralls_json_file', 'w+')
        begin
          f.write(coveralls_coverage_data)
          f.close

          curl_result = `curl -s --form json_file=@#{f.path} #{coveralls_api_jobs_path}`

          if curl_result.is_a? String 
            curl_result_json = JSON.parse(curl_result)          

            if curl_result_json["error"]
              error_message = curl_result_json["message"]
              raise StandardError, "Error while uploading coverage data to Coveralls. CI Service: #{ci_service} Message: #{error_message}"
            end

            puts curl_result_json["url"]
          end

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
