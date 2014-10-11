require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::CoberturaCoverageFile do

  let(:fixtures_project) do
    Slather::Project.open(FIXTURES_PROJECT_PATH)
  end

  let(:coverage_file) do
    fixtures_project.coverage_service = "cobertura_xml"
    fixtures_project.send(:coverage_files).detect { |cf| cf.source_file_pathname.basename.to_s == "Branches.m" }
  end

  describe "#initialize" do
    it "should convert the provided path string to a Pathname object, and set it as the gcno_file_pathname" do
      expect(coverage_file.gcno_file_pathname.exist?).to be_truthy
      expect(coverage_file.gcno_file_pathname.basename.to_s).to eq("Branches.gcno")
    end
  end

  describe "branch_coverage_data" do
    it "should return a hash with keys representing the line number of a branch statement" do
      expect(coverage_file.branch_coverage_data.keys[0]).to eq("15")
      expect(coverage_file.branch_coverage_data.keys[1]).to eq("18")
    end

    it "should store an array for each line number which contains the execution percentage of the branch" do
      percentages = coverage_file.branch_coverage_data["15"]
      expect(percentages.length).to eq(2)
      expect(percentages[0]).to eq(50)
      expect(percentages[1]).to eq(50)

      percentages = coverage_file.branch_coverage_data["18"]
      expect(percentages.length).to eq(2)
      expect(percentages[0]).to eq(0)
      expect(percentages[1]).to eq(100)
    end
  end

  describe "coverage_for_line" do
    it "should return nil for lines without coverage data" do
      line = "branch  0 taken 100%"
      expect(coverage_file.coverage_for_line(line)).to eq(nil)
    end
  end

  describe "branch_coverage_data_for_statement_on_line" do
    it "return the array with branch percentages for statement at a given line number" do
      data = coverage_file.branch_coverage_data_for_statement_on_line("15")
      expect(data.length).to eq(2)
      expect(data[0]).to eq(50)
      expect(data[1]).to eq(50)
    end
  end
  
  describe "branch_hits_for_statement_on_line" do
    it "returns the number of branches executed below the statement at a given line number" do
      expect(coverage_file.branch_hits_for_statement_on_line("18")).to eq(1)
    end
  end
  
  describe "branch_coverage_rate_for_statement_on_line" do
    it "returns the ration bewteen execution percentage and number of branches divided by 100" do
      expect(coverage_file.branch_coverage_rate_for_statement_on_line("15")).to eq(0.5)
      expect(coverage_file.branch_coverage_rate_for_statement_on_line("18")).to eq(0.5)
    end
  end
  
  describe "branch_coverage_percentage_for_statement_on_line" do
    it "returns the average percentage of all branches below the statement at a given line number" do
      expect(coverage_file.branch_coverage_percentage_for_statement_on_line("15")).to eq(50)
      expect(coverage_file.branch_coverage_percentage_for_statement_on_line("18")).to eq(50)
    end
  end
  
  describe "num_branches_testable" do
    it "returns the number of testable branches inside the class" do
      expect(coverage_file.num_branches_testable).to eq(4)
    end
  end

  describe "num_branches_tested" do
    it "returns the number of tested branches inside the class" do
      expect(coverage_file.num_branches_tested).to eq(3)
    end
  end

  describe "rate_branches_tested" do
    it "returns the rate of tested branches inside the class" do
      expect(coverage_file.rate_branches_tested).to eq(0.5)
    end
  end

  describe "source_file_basename" do
    it "returns the base name of the source file" do
      expect(coverage_file.source_file_basename).to eq("Branches")
    end
  end

end
