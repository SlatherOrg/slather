require 'fileutils'
require 'xcodeproj'
require 'httmultiparty'

module Smother
  class Project < Xcodeproj::Project

    def gcno_file_dir
      "/Users/marklarsen/Library/Developer/Xcode/DerivedData/OCMock-enxcxyopnlsrzqdfbcahokpmqtwj/Build/Intermediates/OCMock.build/Debug/OCMock.build/Objects-normal/x86_64/"
    end

    def coverage_files
      Dir["#{gcno_file_dir}/*.gcno"].map do |file|
        coverage_file = Smother::CoverallsCoverageFile.new(file)
        coverage_file.project = self
        coverage_file
      end
    end

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
      HTTMultiParty.post("https://coveralls.io/api/v1/jobs", :body => { :json_file => f })
      #FileUtils.rm(f)
    end

  end
end