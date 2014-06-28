require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Slather::CoverageService::SimpleOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::SimpleOutput)
  end

  describe '#coverage_file_class' do
    it "should return CoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverageFile)
    end
  end

  describe '#post' do
    it "should print out the coverage for each file, and then total coverage" do
      expect(fixtures_project).to receive(:puts).with("spec/fixtures/fixtures/fixtures.m: 2 of 4 lines (50.00%)")
      expect(fixtures_project).to receive(:puts).with("spec/fixtures/fixtures/more_files/peekaview.m: 0 of 6 lines (0.00%)")
      expect(fixtures_project).to receive(:puts).with("spec/fixtures/fixturesTests/fixturesTests.m: 7 of 7 lines (100.00%)")
      expect(fixtures_project).to receive(:puts).with("spec/fixtures/fixturesTests/peekaviewTests.m: 6 of 6 lines (100.00%)")
      expect(fixtures_project).to receive(:puts).with("Test Coverage: 65.22%")
      fixtures_project.post
    end
  end
end
