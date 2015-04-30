require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'nokogiri'

describe Slather::CoverageService::HtmlOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::HtmlOutput)
  end

  describe '#coverage_file_class' do
    it "should return CoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverageFile)
    end
  end

  describe '#post' do
    it "should create index html that includes coverage file index" do
      fixtures_project.post
    end

    it "should create html coverage for each file with correct coverage" do
    end

    it "should create an HTML report folder in the given output directory" do
      # fixtures_project.output_directory = "./output"
      # fixtures_project.post
      #
      # filepath = "#{fixtures_project.output_directory}/html"
      # expect(File.exists?(filepath)).to be_truthy
      #
      # FileUtils.rm_rf(fixtures_project.output_directory)
    end
  end
end
