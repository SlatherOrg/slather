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
