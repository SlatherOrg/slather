require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'json'

describe Slather::CoverageService::CoberturaXmlOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::CoberturaXmlOutput)
    proj.build_directory = FIXTURES_DERIVED_DATA_PATH
    proj
  end

  describe '#coverage_file_class' do
    it "should return CoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverageFile)
    end
  end

  describe '#post' do
    it "should create an XML report spanning all coverage files" do
      fixtures_project.post

      file = File.open(FIXTURES_XML_PATH)
      fixture_xml_doc = Nokogiri::XML(file)
      file.close

      file = File.open('cobertura.xml')
      current_xml_doc = Nokogiri::XML(file)
      file.close

      [current_xml_doc, fixture_xml_doc].each do |xml_doc|
        xml_doc.root['timestamp'] = ''
        xml_doc.root['version'] = ''
        source_node = xml_doc.at_css "source"
        source_node.content = ''
      end

      expect(EquivalentXml.equivalent?(current_xml_doc, fixture_xml_doc)).to be_truthy
    end

    it "should create an XML report in the given output directory" do
      fixtures_project.output_directory = "./output"
      fixtures_project.post

      filepath = "#{fixtures_project.output_directory}/cobertura.xml"
      expect(File.exists?(filepath)).to be_truthy

      FileUtils.rm_rf(fixtures_project.output_directory)
    end
  end
end
