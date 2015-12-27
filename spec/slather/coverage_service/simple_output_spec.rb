require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Slather::CoverageService::SimpleOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.build_directory = TEMP_DERIVED_DATA_PATH
    proj.input_format = "gcov"
    proj.configure
    proj
  end

  describe '#coverage_file_class' do
    it "should return CoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverageFile)
    end
  end

  describe '#post' do
    it "should print out the coverage for each file, and then total coverage" do
      ["spec/fixtures/fixtures/fixtures.m: 3 of 6 lines (50.00%)",
      "spec/fixtures/fixtures/more_files/peekaview.m: 0 of 6 lines (0.00%)",
      "spec/fixtures/fixtures/fixtures_cpp.cpp: 0 of 0 lines (100.00%)",
      "spec/fixtures/fixtures/fixtures_mm.mm: 0 of 0 lines (100.00%)",
      "spec/fixtures/fixtures/fixtures_m.m: 0 of 0 lines (100.00%)",
      "spec/fixtures/fixtures/more_files/Branches.m: 10 of 21 lines (47.62%)",
      "spec/fixtures/fixtures/more_files/Empty.m: 0 of 0 lines (100.00%)",
      "spec/fixtures/fixturesTests/fixturesTests.m: 10 of 10 lines (100.00%)",
      "spec/fixtures/fixturesTests/peekaviewTests.m: 9 of 9 lines (100.00%)",
      "spec/fixtures/fixturesTests/BranchesTests.m: 14 of 14 lines (100.00%)",
      "Test Coverage: 69.70%"].each do |line|
        expect(fixtures_project).to receive(:puts).with(line)
      end

      fixtures_project.post
    end
  end
end
