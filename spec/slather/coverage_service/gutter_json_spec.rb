require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'json'

describe Slather::CoverageService::GutterJsonOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::GutterJsonOutput)
    proj.build_directory = TEMP_DERIVED_DATA_PATH
    proj
  end

  describe '#coverage_file_class' do
    it "should return CoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverageFile)
    end
  end

  describe '#post' do
    it "should print out the coverage for each file, and then total coverage" do
      fixtures_project.post

      fixture_json = File.read(FIXTURES_JSON_PATH)
      current_json = File.read('.gutter.json')

      expect(current_json).to be_json_eql(fixture_json)
      File.unlink('.gutter.json')
    end
  end
end
