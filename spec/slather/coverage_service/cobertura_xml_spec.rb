require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'json'

describe Slather::CoverageService::CoberturaXmlOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::CoberturaXmlOutput)
  end

  describe '#coverage_file_class' do
    it "should return CoberturaCoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoberturaCoverageFile)
    end
  end

  describe '#create_xml_report' do
    
    it "should create a coverage-node which is the root node of the XML document" do
    end
    it "should create timestamp, the overall line-rate and branch-rate attributes inside the coverage-node" do
    end

    it "should create a package-node" do
    end
    it "should create name, line-rate and branch-rate attributes inside the package-node" do
    end

    it "should create a class-node for each coverage file" do
    end
    it "should create name, filename, line-rate, branch-rate and complexity attributes inside the class-node" do
    end

    it "should create a method-node for each testable method inside the coverage file" do
    end
    it "should create name, line-rate, branch-rate and signature attributes inside the method-node" do
    end

    it "should create a line-node for each line inside a testable method" do
    end
    it "should create number, hits, and branch attributes inside the line-node" do
    end

  end

  describe '#post' do
    it "should print out the coverage for each file, and then total coverage" do
      fixtures_project.post

      # fixture_json = JSON.parse(File.read(FIXTURES_JSON_PATH))
      # fixture_json['meta']['timestamp'] = ''

      # current_json = JSON.parse(File.read('.gutter.json'))
      # current_json['meta']['timestamp'] = ''

      # expect(current_json).to eq(fixture_json)
      
      File.unlink('cobertura.xml')
    end
  end
end
