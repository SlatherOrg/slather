require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Slather::CoverageService::SimpleOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.build_directory = TEMP_DERIVED_DATA_PATH
    proj.input_format = "profdata"
    proj.configure
    proj
  end

  describe '#coverage_file_class' do
    it "should return CoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::ProfdataCoverageFile)
    end
  end

  describe '#post' do
    it "should print out the coverage for each file, and then total coverage" do
      ["spec/fixtures/fixtures/fixtures.m: 3 of 6 lines (50.00%)",
      "spec/fixtures/fixtures/more_files/Branches.m: 13 of 30 lines (43.33%)",
      "spec/fixtures/fixturesTests/BranchesTests.m: 16 of 16 lines (100.00%)",
      "spec/fixtures/fixturesTests/fixturesTests.m: 12 of 12 lines (100.00%)",
      "spec/fixtures/fixturesTests/peekaviewTests.m: 11 of 11 lines (100.00%)",
      "Test Coverage: 73.33%"
      ].each do |line|
        expect(fixtures_project).to receive(:puts).with(line)
      end

      fixtures_project.post
    end

    describe 'ci_service reporting output' do

      context "ci_service is :teamcity" do
        before(:each) { fixtures_project.ci_service = :teamcity }

        it "should print out the coverage" do
          ["spec/fixtures/fixtures/fixtures.m: 3 of 6 lines (50.00%)",
           "spec/fixtures/fixtures/more_files/Branches.m: 13 of 30 lines (43.33%)",
           "spec/fixtures/fixturesTests/BranchesTests.m: 16 of 16 lines (100.00%)",
           "spec/fixtures/fixturesTests/fixturesTests.m: 12 of 12 lines (100.00%)",
           "spec/fixtures/fixturesTests/peekaviewTests.m: 11 of 11 lines (100.00%)",
           "##teamcity[buildStatisticValue key='CodeCoverageAbsLCovered' value='55']",
           "##teamcity[buildStatisticValue key='CodeCoverageAbsLTotal' value='75']",
           "Test Coverage: 73.33%"
          ].each do |line|
            expect(fixtures_project).to receive(:puts).with(line)
          end

          fixtures_project.post
        end
      end

    end

  end
end
