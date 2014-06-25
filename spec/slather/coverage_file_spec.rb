require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::CoverageFile do

  let(:fixtures_project) do
    Slather::Project.open(FIXTURES_PROJECT_PATH)
  end

  let(:coverage_file) { Slather::CoverageFile.new(fixtures_project, "/some/path/fixtures.gcno") }

  describe "#initialize" do
    it "should convert the provided path string to a Pathname object, and set it as the gcno_file_pathname" do
      expect(coverage_file.gcno_file_pathname).to eq(Pathname("/some/path/fixtures.gcno"))
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

  end
end