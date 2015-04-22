module Slather
  class ContinuousIntegrationCoverageService < CoverageService

    def coverage_file_class
      # TODO: Make this ContinuousIntegrationCoverageFile
      Slather::CoverallsCoverageFile
    end

    def travis_job_id
      ENV['TRAVIS_JOB_ID']
    end
    private :travis_job_id

    def circleci_job_id
      ENV['CIRCLE_BUILD_NUM']
    end
    private :circleci_job_id

    def jenkins_job_id
      "#{ENV['JOB_NAME']}/#{ENV['BUILD_NUMBER']}"
    end
    private :jenkins_job_id

    def circleci_pull_request
      ENV['CI_PULL_REQUEST']
    end
    private :circleci_pull_request

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

    def coverage_data
      unsupported_ci_service(project.ci_service) unless supported_ci_services.include?(project.ci_service)

      if project.ci_service == :travis_ci || project.ci_service == :travis_pro
        if travis_job_id
          if project.ci_service == :travis_ci
            {
              :service_job_id => travis_job_id,
              :service_name => "travis-ci",
              :source_files => coverage_files.map(&:as_json)
            }.to_json
          elsif project.ci_service == :travis_pro
            {
              :service_job_id => travis_job_id,
              :service_name => "travis-pro",
              :repo_token => project.ci_access_token,
              :source_files => coverage_files.map(&:as_json)
            }.to_json
          end
        else
          raise StandardError, "Environment variable `TRAVIS_JOB_ID` not set. Is this running on a travis build?"
        end
      elsif ci_service == :jenkins_ci
        if jenkins_job_id
          {
            :service_job_id => jenkins_job_id,
            :service_name => "jenkins-ci",
            :repo_token => project.ci_access_token
            :source_files => coverage_files.map(&:as_json)
          }.to_json
      elsif project.ci_service == :circleci
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
      else
        unsupported_ci_service(project.ci_service)
      end
    end
    protected :coverage_data

    def unsupported_ci_service(ci_service)
      raise StandardError, "No support for ci named #{ci_service}"
    end
    protected :unsupported_ci_service

    def post
      f = File.open('coverage_data_file', 'w+')
      begin
        f.write(coverage_data)
        f.close
        `curl --form json_file=@#{f.path} #{api_jobs_path}`
      rescue StandardError => e
        FileUtils.rm(f)
        raise e
      end
      FileUtils.rm(f)
    end

    def api_jobs_path
      raise NotImplementedError
    end
    protected :api_jobs_path

    def supported_ci_services
      [:circleci, :jenkins_ci, :travis_ci, :travis_pro]
    end
    protected :supported_ci_services

  end
end
