require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'json'

describe Slather::CoverageService::SonarqubeXmlOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.build_directory = TEMP_DERIVED_DATA_PATH
    proj.input_format = "profdata"
    proj.coverage_service = "sonarqube_xml"
    proj.configure
    proj
  end

  describe '#coverage_file_class' do
    it "should return CoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::ProfdataCoverageFile)
    end
  end

  describe '#post' do
    it "should create an XML report spanning all coverage files" do
      fixtures_project.post

      file = File.open(FIXTURES_SONARQUBE_XML_PATH)
      fixture_xml_doc = Nokogiri::XML(file)
      file.close

      file = File.open('sonarqube-generic-coverage.xml')
      current_xml_doc = Nokogiri::XML(file)
      file.close

      expect(EquivalentXml.equivalent?(current_xml_doc, fixture_xml_doc)).to be_truthy
    end

    it "should create an XML report in the given output directory" do
      fixtures_project.output_directory = "./output"
      fixtures_project.post

      filepath = "#{fixtures_project.output_directory}/sonarqube-generic-coverage.xml"
      expect(File.exists?(filepath)).to be_truthy

      FileUtils.rm_rf(fixtures_project.output_directory)
    end
  end
end
