module Slather
  module CoverageService
    module Coveralls

      def coverage_file_class
        Slather::CoverallsCoverageFile
      end

      def coveralls_coverage_data
        {
          :service_job_id => ENV['TRAVIS_JOB_ID'],
          :service_name => "travis-ci",
          :source_files => coverage_files.map(&:as_json)
        }.to_json
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