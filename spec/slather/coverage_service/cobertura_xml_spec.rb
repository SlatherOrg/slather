require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'json'

describe Slather::CoverageService::CoberturaXmlOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::CoberturaXmlOutput)
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
      current_xml_doc.root['timestamp'] = ''
      current_xml_doc.root['version'] = ''
      source_node = current_xml_doc.at_css "source"
      source_node.content = ''
      
      expect(current_xml_doc.to_xml).to eq(fixture_xml_doc.to_xml)
      
      File.unlink('cobertura.xml')
    end
  end
end
