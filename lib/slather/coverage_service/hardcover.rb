module Slather
  module CoverageService
    module Hardcover

      def supported_ci_services
        [:jenkins_ci, :travis_ci]
      end

      def api_jobs_path
        "#{hardcover_base_url}/v1/jobs"
      end

      def hardcover_base_url
        url = project.hardcover_base_url
        unless url
          raise "No `base_url` configured. Please add it to your `.hardcover.yml`"
        end
        url
      end
      private :hardcover_base_url

    end
  end
end
