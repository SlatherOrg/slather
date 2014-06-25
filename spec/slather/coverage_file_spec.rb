require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::CoverageFile do

  let(:fixtures_project) do
    Slather::Project.open(FIXTURES_PROJECT_PATH)
  end

  let(:coverage_file) do
    gcno_path = Pathname(File.join(File.dirname(__FILE__), "fixtures.gcno")).to_s
    Slather::CoverageFile.new(fixtures_project, gcno_path)
  end

  describe "#initialize" do
    it "should convert the provided path string to a Pathname object, and set it as the gcno_file_pathname" do
      expect(coverage_file.gcno_file_pathname).to eq(Pathname(File.join(File.dirname(__FILE__), "fixtures.gcno")))
    end
  end

  describe "#source_file_pathname" do
    it "should return the path to the coverage files's source implementation file" do
      expect(coverage_file.source_file_pathname).to eq(fixtures_project["fixtures/fixtures.m"].real_path)
    end

    it "should return nil if it couldn't find the coverage files's source implementation file in the project" do
      whoami_file = Slather::CoverageFile.new(fixtures_project, "/some/path/whoami.gcno")
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

    describe "source_file_pathname_relative_to_repo_root" do
      it "should return a pathname to the source_file, relative to the root of the repo" do
        expect(coverage_file.source_file_pathname_relative_to_repo_root).to eq(Pathname("spec/fixtures/fixtures/fixtures.m"))
      end
    end

    describe "#coverage_for_line" do
      it "should return nil if the line is not relevant to coverage" do
        expect(coverage_file.coverage_for_line("        -:   75: }")).to be_nil
      end

      it "should return the number of times the line was executed if the line is relevant to coverage" do
        expect(coverage_file.coverage_for_line("        1:   75: }")).to eq(1)
        expect(coverage_file.coverage_for_line("        15:   75: }")).to eq(15)
        expect(coverage_file.coverage_for_line("        ####:   75: }")).to eq(0)
      end
    end

    describe "#ignored" do
      it "should return true if the source_file_pathname globs against anything in the project.ignore_list" do
        coverage_file.project.ignore_list = ["*spec*", "*test*"]
        expect(coverage_file.ignored?).to be_truthy
      end

      it "should return false if the source_file_pathname does not glob against anything in the project.ignore_list" do
        coverage_file.project.ignore_list = ["*test*", "*XCTest*"]
        expect(coverage_file.ignored?).to be_falsy
      end
    end

    describe "gcov_data" do
      it "should process the gcno file with gcov and return the contents of the file" do
        expected = <<-GCOV
        -:    0:Source:/Users/marklarsen/github.com/slather/spec/fixtures/fixtures/fixtures.m
        -:    0:Graph:/Users/marklarsen/github.com/slather/spec/slather/fixtures.gcno
        -:    0:Data:-
        -:    0:Runs:0
        -:    0:Programs:0
        -:    1://
        -:    2://  fixtures.m
        -:    3://  fixtures
        -:    4://
        -:    5://  Created by Mark Larsen on 6/24/14.
        -:    6://  Copyright (c) 2014 marklarr. All rights reserved.
        -:    7://
        -:    8:
        -:    9:#import "fixtures.h"
        -:   10:
        -:   11:@implementation fixtures
        -:   12:
        -:   13:- (void)testedMethod
        -:   14:{
    #####:   15:    NSLog(@"tested");
    #####:   16:}
        -:   17:
        -:   18:- (void)untestedMethod
        -:   19:{
    #####:   20:    NSLog(@"untested");
    #####:   21:}
        -:   22:
        -:   23:@end
GCOV
        expect(coverage_file.gcov_data).to eq(expected)
      end
    end

  end
end