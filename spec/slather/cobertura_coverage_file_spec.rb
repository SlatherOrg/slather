require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::CoberturaCoverageFile do

  let(:fixtures_project) do
    Slather::Project.open(FIXTURES_PROJECT_PATH)
  end

  let(:coverage_file) do
    fixtures_project.send(:coverage_files).detect { |cf| cf.source_file_pathname.basename.to_s == "peekaview.m" }
  end

  describe "#initialize" do
    it "should convert the provided path string to a Pathname object, and set it as the gcno_file_pathname" do
      expect(coverage_file.gcno_file_pathname.exist?).to be_truthy
      expect(coverage_file.gcno_file_pathname.basename.to_s).to eq("peekaview.gcno")
    end
  end

  describe "#source_file_pathname" do
    it "should return the path to the coverage files's source implementation file" do
      expect(coverage_file.source_file_pathname).to eq(fixtures_project["fixtures/more_files/peekaview.m"].real_path)
    end

    it "should look in the source_directory if it has been set on the project" do
      coverage_file = Slather::CoberturaCoverageFile.new(fixtures_project, "peekaview.m")
      fixtures_project.source_directory = Pathname(File.join(File.dirname(__FILE__), '../more_files/')).realpath.to_s
      expect(coverage_file.source_file_pathname).to eq(fixtures_project["fixtures/more_files/fixtures.m"].real_path)
    end

    it "should look in the source_directory if it has been set on the project" do
      coverage_file = Slather::CoberturaCoverageFile.new(fixtures_project, "peekaview.m")
      fixtures_project.source_directory = Pathname(File.join(File.dirname(__FILE__), '../fixtures//fixturesTests')).realpath.to_s
      expect(coverage_file.source_file_pathname).to be_nil
    end

    it "should return nil if it couldn't find the coverage files's source implementation file in the project" do
      whoami_file = Slather::CoberturaCoverageFile.new(fixtures_project, "/some/path/whoami.gcno")
      expect(whoami_file.source_file_pathname).to be_nil
    end
  end

  describe "#source_file" do
    it "should return a file object for the source_file_pathname" do
      file = coverage_file.source_file
      expect(file.kind_of?(File)).to be_truthy
      expect(Pathname(file.path)).to eq(coverage_file.source_file_pathname)
    end
  end

  describe "#source_data" do
    
    describe "#coverage_for_line" do
      
      it "should return nil if the line is not relevant to coverage" do
        expect(coverage_file.coverage_for_line("        -:   31: }")).to be_nil
      end

      it "should return the number of times the line was executed if the line is relevant to coverage" do
        expect(coverage_file.coverage_for_line("        1:   75: }")).to eq(1)
        expect(coverage_file.coverage_for_line("        15:   75: }")).to eq(15)
        expect(coverage_file.coverage_for_line("        ####:   75: }")).to eq(0)
      end
    end

    describe "gcov_data" do
      it "should process the gcno file with gcov and return the contents of the file" do
        expect(coverage_file.gcov_data.include?("1:   15:    NSLog(@\"tested\");")).to be_truthy
      end
    end

    describe "branch_coverage_data" do
      it "should return a hash with keys representing the line number of a branch statement" do
        # coverage_file.branch_coverage_data.keys
      end
    end

    describe "num_lines_tested" do
      it "should return the correct number of lines tested" do
        expect(coverage_file.num_lines_tested).to eq(2)
      end
    end

    describe "num_lines_testable" do
      it "should return the correct number of lines that are testable" do
        expect(coverage_file.num_lines_testable).to eq(4)
      end
    end

    describe "percentage_lines_tested" do
      it "should return the correct percentage of lines that are tested" do
        expect(coverage_file.percentage_lines_tested).to eq(50)
      end
      
      it "should return 0" do
        coverage_file.stub(:num_lines_testable).and_return(0)
        expect(coverage_file.percentage_lines_tested).to eq(0)
      end
    end

  end
end
