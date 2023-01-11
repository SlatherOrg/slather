require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'json'

describe Slather::CoverageService::JsonOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.build_directory = TEMP_DERIVED_DATA_PATH
    proj.binary_basename = ["fixturesTests", "libfixturesTwo"]
    proj.input_format = "profdata"
    proj.coverage_service = "json"
    proj.configure
    proj
  end

  describe '#coverage_file_class' do
    it "should return ProfdataCoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::ProfdataCoverageFile)
    end
  end

  describe '#post' do
    it "should create an JSON report spanning all coverage files" do
      fixtures_project.post

      output_json = JSON.parse(File.read('report.json'))
      fixture_json = JSON.parse(File.read(FIXTURES_JSON_PATH))

      expect(output_json).to eq(fixture_json)
      FileUtils.rm('report.json')
    end

    it "should create an JSON report in the given output directory" do
      fixtures_project.output_directory = "./output"
      fixtures_project.post

      filepath = "#{fixtures_project.output_directory}/report.json"
      expect(File.exist?(filepath)).to be_truthy

      FileUtils.rm_rf(fixtures_project.output_directory)
    end
  end
end
