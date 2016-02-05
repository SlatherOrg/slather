require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::CoverageFile do

  let(:fixtures_project) do
    project = Slather::Project.open(FIXTURES_PROJECT_PATH)
    project.build_directory = TEMP_DERIVED_DATA_PATH
    project.send(:configure)
    allow(project).to receive(:input_format).and_return("gcov")
    project
  end

  let(:coverage_file) do
    fixtures_project.send(:coverage_files).detect { |cf| cf.source_file_pathname.basename.to_s == "fixtures.m" }
  end

  describe "#initialize" do
    it "should convert the provided path string to a Pathname object, and set it as the gcno_file_pathname" do
      expect(coverage_file.gcno_file_pathname).to be_exist
      expect(coverage_file.gcno_file_pathname.basename.to_s).to eq("fixtures.gcno")
    end
  end

  describe "#source_file_pathname" do
    it "should look in the source_directory if it has been set on the project" do
      coverage_file = Slather::CoverageFile.new(fixtures_project, "fixtures.m")
      fixtures_project.source_directory = Pathname(File.join(File.dirname(__FILE__), '../fixtures/')).realpath.to_s
      expect(coverage_file.source_file_pathname).to eq(fixtures_project["fixtures/fixtures.m"].real_path)
    end

    it "should look in the source_directory if it has been set on the project" do
      coverage_file = Slather::CoverageFile.new(fixtures_project, "fixtures.m")
      fixtures_project.source_directory = Pathname(File.join(File.dirname(__FILE__), '../fixtures/fixturesTests')).realpath.to_s
      expect(coverage_file.source_file_pathname).to be_nil
    end

    it "should return nil if it couldn't find the coverage files's source implementation file in the project" do
      whoami_file = Slather::CoverageFile.new(fixtures_project, "/some/path/whoami.gcno")
      expect(whoami_file.source_file_pathname).to be_nil
    end

    ["cpp", "mm", "m"].each do |file_ext|
      it "should work for #{file_ext} files" do
        file_name = "fixtures_#{file_ext}.#{file_ext}"
        coverage_file = fixtures_project.send(:coverage_files).detect { |cf| cf.source_file_pathname.basename.to_s == file_name }
        expect(coverage_file.source_file_pathname).to eq(fixtures_project["fixtures/#{file_name}"].real_path)
      end
    end
  end

  describe "#source_file" do
    it "should return a file object for the source_file_pathname" do
      file = coverage_file.source_file
      expect(file).to be_a File
      expect(Pathname(file.path)).to eq(coverage_file.source_file_pathname)
    end
  end

  describe "#source_data" do
    it "should return the contents of the source_file" do
      expected = <<-OBJC
//
//  fixtures.m
//  fixtures
//
//  Created by Mark Larsen on 6/24/14.
//  Copyright (c) 2014 marklarr. All rights reserved.
//

#import "fixtures.h"

@implementation fixtures

- (void)testedMethod
{
    NSLog(@"tested");
}

- (void)untestedMethod
{
    NSLog(@"untested");
}

@end
OBJC
      expect(coverage_file.source_data).to eq(expected)
    end
  end

  describe "source_file_basename" do
    it "returns the base name of the source file" do
      expect(coverage_file.source_file_basename).to eq("fixtures")
    end
  end

  describe "source_file_pathname_relative_to_repo_root" do
    it "should return a pathname to the source_file, relative to the root of the repo" do
      expect(coverage_file.source_file_pathname_relative_to_repo_root).to eq(Pathname("spec/fixtures/fixtures/fixtures.m"))
    end
  end

  describe "#ignored" do
    it "should return true if the source_file_pathname globs against anything in the project.ignore_list" do
      coverage_file.project.ignore_list = ["*spec*", "*test*"]
      expect(coverage_file).to be_ignored
    end

    it "should return false if the source_file_pathname does not glob against anything in the project.ignore_list" do
      coverage_file.project.ignore_list = ["*test*", "*XCTest*"]
      expect(coverage_file).not_to be_ignored
    end
  end

  describe "gcov_data" do
    it "should process the gcno file with gcov and return the contents of the file" do
      expect(coverage_file.gcov_data).to include(":   15:    NSLog(@\"tested\");")
    end
  end

  describe "line coverage" do

    before(:each) {
      allow(fixtures_project).to receive(:input_format).and_return("gcov")
    }

    let(:line_coverage_file) do
      fixtures_project.send(:coverage_files).detect { |cf| cf.source_file_pathname.basename.to_s == "fixtures.m" }
    end

    describe "#coverage_for_line" do
      it "should return nil if the line is not relevant to coverage" do
        expect(line_coverage_file.coverage_for_line("        -:   75: }")).to be_nil
      end

      it "should return the number of times the line was executed if the line is relevant to coverage" do
        expect(line_coverage_file.coverage_for_line("        1:   75: }")).to eq(1)
        expect(line_coverage_file.coverage_for_line("        15:   75: }")).to eq(15)
        expect(line_coverage_file.coverage_for_line("        ####:   75: }")).to eq(0)
      end
    end

    describe "num_lines_tested" do
      it "should return the correct number of lines tested" do
        expect(line_coverage_file.num_lines_tested).to eq(3)
      end
    end

    describe "num_lines_testable" do
      it "should return the correct number of lines that are testable" do
        expect(line_coverage_file.num_lines_testable).to eq(6)
      end
    end

    describe "percentage_lines_tested" do
      it "should return the correct percentage of lines that are tested" do
        expect(line_coverage_file.percentage_lines_tested).to eq(50)
      end

      it "should return 100 if no testable lines" do
        allow(line_coverage_file).to receive(:num_lines_testable).and_return(0)
        expect(line_coverage_file.percentage_lines_tested).to eq(100)
      end
    end
  end

  describe "branch coverage" do

    let(:branch_coverage_file) do
      fixtures_project.send(:coverage_files).detect { |cf| cf.source_file_pathname.basename.to_s == "Branches.m" }
    end

    describe "branch_coverage_data" do
      it "should return a hash with keys representing the line number of a branch statement" do
        expect(branch_coverage_file.branch_coverage_data.keys[0]).to eq(15)
        expect(branch_coverage_file.branch_coverage_data.keys[1]).to eq(18)
        expect(branch_coverage_file.branch_coverage_data.keys[2]).to eq(26)
        expect(branch_coverage_file.branch_coverage_data.keys[3]).to eq(29)
      end

      it "should store an array for each line number which contains the hit count for each branch" do
        data = branch_coverage_file.branch_coverage_data[15]
        expect(data.length).to eq(2)
        expect(data[0]).to be >= 1
        expect(data[1]).to be >= 1

        data = branch_coverage_file.branch_coverage_data[18]
        expect(data.length).to eq(2)
        expect(data[0]).to eq(0)
        expect(data[1]).to be >= 1

        data = branch_coverage_file.branch_coverage_data[26]
        expect(data.length).to eq(2)
        expect(data[0]).to be >= 2
        expect(data[1]).to eq(0)

        data = branch_coverage_file.branch_coverage_data[29]
        expect(data.length).to eq(4)
        expect(data[0]).to eq(0)
        expect(data[1]).to eq(0)
        expect(data[2]).to eq(0)
        expect(data[3]).to eq(0)
      end
    end

    describe "branch_coverage_data_for_statement_on_line" do
      it "return the array with branch hit counts for statement at a given line number" do
        data = branch_coverage_file.branch_coverage_data[15]
        expect(data.length).to eq(2)
        expect(data[0]).to be >= 1
        expect(data[1]).to be >= 1

        data = branch_coverage_file.branch_coverage_data[18]
        expect(data.length).to eq(2)
        expect(data[0]).to eq(0)
        expect(data[1]).to be >= 1

        data = branch_coverage_file.branch_coverage_data[26]
        expect(data.length).to eq(2)
        expect(data[0]).to be >= 2
        expect(data[1]).to eq(0)

        data = branch_coverage_file.branch_coverage_data[29]
        expect(data.length).to eq(4)
        expect(data[0]).to eq(0)
        expect(data[1]).to eq(0)
        expect(data[2]).to eq(0)
        expect(data[3]).to eq(0)
      end
    end

    describe "num_branch_hits_for_statement_on_line" do
      it "returns the number of branches executed below the statement at a given line number" do
        expect(branch_coverage_file.num_branch_hits_for_statement_on_line(15)).to eq(2)
        expect(branch_coverage_file.num_branch_hits_for_statement_on_line(18)).to eq(1)
        expect(branch_coverage_file.num_branch_hits_for_statement_on_line(26)).to eq(1)
        expect(branch_coverage_file.num_branch_hits_for_statement_on_line(29)).to eq(0)
      end
    end

    describe "rate_branch_coverage_for_statement_on_line" do
      it "returns the ratio between number of executed and number of total branches at a given line number" do
        expect(branch_coverage_file.rate_branch_coverage_for_statement_on_line(15)).to eq(1.0)
        expect(branch_coverage_file.rate_branch_coverage_for_statement_on_line(18)).to eq(0.5)
        expect(branch_coverage_file.rate_branch_coverage_for_statement_on_line(26)).to eq(0.5)
        expect(branch_coverage_file.rate_branch_coverage_for_statement_on_line(29)).to eq(0.0)
      end

      it "return 0.0 for a line without branch data" do
        expect(branch_coverage_file.rate_branch_coverage_for_statement_on_line(1)).to eq(0.0)
      end
    end

    describe "percentage_branch_coverage_for_statement_on_line" do
      it "returns the average hit percentage of all branches below the statement at a given line number" do
        expect(branch_coverage_file.percentage_branch_coverage_for_statement_on_line(15)).to eq(100)
        expect(branch_coverage_file.percentage_branch_coverage_for_statement_on_line(18)).to eq(50)
        expect(branch_coverage_file.percentage_branch_coverage_for_statement_on_line(26)).to eq(50)
        expect(branch_coverage_file.percentage_branch_coverage_for_statement_on_line(29)).to eq(0)
      end
    end

    describe "num_branches_testable" do
      it "returns the number of testable branches inside the class" do
        expect(branch_coverage_file.num_branches_testable).to eq(10)
      end
    end

    describe "num_branches_tested" do
      it "returns the number of tested branches inside the class" do
        expect(branch_coverage_file.num_branches_tested).to eq(4)
      end
    end

    describe "rate_branches_tested" do
      it "returns the ratio between tested and testable branches inside the class" do
        expect(branch_coverage_file.rate_branches_tested).to eq(0.4)
      end
    end
  end

  describe "empty coverage data" do

    let(:empty_file) do
      fixtures_project.send(:coverage_files).detect { |cf| cf.source_file_pathname.basename.to_s == "Empty.m" }
    end

    describe "gcov_data" do
      it "returns an empty string" do
        gcov_data = empty_file.gcov_data
        expect(gcov_data).to be_empty
      end
    end

    describe "cleaned_gcov_data" do
      it "returns an empty string" do
        cleaned_gcov_data = empty_file.cleaned_gcov_data
        expect(cleaned_gcov_data).to be_empty
      end
    end

    describe "branch_coverage_data" do
      it "returns an empty hash for branch_coverage_data of an empty file" do
        data = empty_file.branch_coverage_data
        expect(data).to be_empty
      end
    end

    describe "num_branch_hits_for_statement_on_line" do
      it "returns 0.0 when no data is available" do
        expect(empty_file.num_branch_hits_for_statement_on_line(1)).to eq(0)
      end
    end

    describe "rate_branch_coverage_for_statement_on_line" do
      it "returns 0.0 when no data is available" do
        expect(empty_file.rate_branch_coverage_for_statement_on_line(1)).to eq(0.0)
      end
    end

    describe "percentage_branch_coverage_for_statement_on_line" do
      it "returns 0 when no data is available" do
        expect(empty_file.percentage_branch_coverage_for_statement_on_line(1)).to eq(0)
      end
    end

    describe "num_branches_testable" do
      it "returns 0 when no data is available" do
        expect(empty_file.num_branches_testable).to eq(0)
      end
    end

    describe "num_branches_tested" do
      it "returns 0 when no data is available" do
        expect(empty_file.num_branches_tested).to eq(0)
      end
    end

    describe "rate_branches_tested" do
      it "returns 0.0 when no data is available" do
        expect(empty_file.rate_branches_tested).to eq(0.0)
      end
    end
  end

end
