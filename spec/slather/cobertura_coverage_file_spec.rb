require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::CoberturaCoverageFile do

  let(:fixtures_project) do
    Slather::Project.open(FIXTURES_PROJECT_PATH)
  end

  let(:coverage_file) do
    fixtures_project.coverage_service = "cobertura_xml"
    fixtures_project.send(:coverage_files).detect { |cf| cf.source_file_pathname.basename.to_s == "Branches.m" }
  end

  describe "branch_coverage_data" do
    it "should return a hash with keys representing the line number of a branch statement" do
      expect(coverage_file.branch_coverage_data.keys[0]).to eq("15")
      expect(coverage_file.branch_coverage_data.keys[1]).to eq("18")
    end

    it "should store an array for each line number which contains the hit count for each branch" do
      data = coverage_file.branch_coverage_data["15"]
      expect(data.length).to eq(2)
      expect(data[0]).to eq(1)
      expect(data[1]).to eq(1)

      data = coverage_file.branch_coverage_data["18"]
      expect(data.length).to eq(2)
      expect(data[0]).to eq(0)
      expect(data[1]).to eq(1)
    end
  end

  describe "branch_coverage_data_for_statement_on_line" do
    it "return the array with branch hit counts for statement at a given line number" do
      data = coverage_file.branch_coverage_data_for_statement_on_line("15")
      expect(data.length).to eq(2)
      expect(data[0]).to eq(1)
      expect(data[1]).to eq(1)
    end
  end
  
  describe "num_branch_hits_for_statement_on_line" do
    it "returns the number of branches executed below the statement at a given line number" do
      expect(coverage_file.num_branch_hits_for_statement_on_line("18")).to eq(1)
    end
  end
  
  describe "rate_branch_coverage_for_statement_on_line" do
    it "returns the ratio between number of executed and number of total branches at a given line number" do
      expect(coverage_file.rate_branch_coverage_for_statement_on_line("15")).to eq(1.0)
      expect(coverage_file.rate_branch_coverage_for_statement_on_line("18")).to eq(0.5)
      expect(coverage_file.rate_branch_coverage_for_statement_on_line("29")).to eq(0.0)
    end
  end
  
  describe "percentage_branch_coverage_for_statement_on_line" do
    it "returns the average hit percentage of all branches below the statement at a given line number" do
      expect(coverage_file.percentage_branch_coverage_for_statement_on_line("15")).to eq(100)
      expect(coverage_file.percentage_branch_coverage_for_statement_on_line("18")).to eq(50)
      expect(coverage_file.percentage_branch_coverage_for_statement_on_line("29")).to eq(0)
    end
  end
  
  describe "num_branches_testable" do
    it "returns the number of testable branches inside the class" do
      expect(coverage_file.num_branches_testable).to eq(10)
    end
  end

  describe "num_branches_tested" do
    it "returns the number of tested branches inside the class" do
      expect(coverage_file.num_branches_tested).to eq(4)
    end
  end

  describe "rate_branches_tested" do
    it "returns the ratio between tested and testable branches inside the class" do
      expect(coverage_file.rate_branches_tested).to eq(0.4)
    end
  end

  describe "source_file_basename" do
    it "returns the base name of the source file" do
      expect(coverage_file.source_file_basename).to eq("Branches")
    end
  end

end
