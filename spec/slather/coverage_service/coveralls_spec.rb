require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Slather::CoverageService::Coveralls do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.build_directory = TEMP_DERIVED_DATA_PATH
    proj.coverage_service = "coveralls"
    proj
  end

  describe "#coverage_file_class" do
    it "should return CoverallsCoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverageFile)
    end
  end

  describe "#travis_job_id" do
    it "should return the TRAVIS_JOB_ID environment variable" do
      actual_travis_job_id = ENV['TRAVIS_JOB_ID']
      ENV['TRAVIS_JOB_ID'] = "9182"
      expect(fixtures_project.send(:travis_job_id)).to eq("9182")
      ENV['TRAVIS_JOB_ID'] = actual_travis_job_id
    end
  end

  context "#gcov file format" do
    before(:each) { 
      fixtures_project.stub(:input_format).and_return("gcov")
      fixtures_project.send(:configure_from_yml)
    }

    describe '#coveralls_coverage_data' do

      context "coverage_service is :travis_ci" do
        before(:each) { fixtures_project.ci_service = :travis_ci }

        it "should return valid json for coveralls coverage gcov data" do
          fixtures_project.stub(:travis_job_id).and_return("9182")
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql("{\"service_job_id\":\"9182\",\"service_name\":\"travis-ci\"}").excluding("source_files")
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql(fixtures_project.send(:coverage_files).map(&:as_json).to_json).at_path("source_files")
        end

        it "should raise an error if there is no TRAVIS_JOB_ID" do
          fixtures_project.stub(:travis_job_id).and_return(nil)
          expect { fixtures_project.send(:coveralls_coverage_data) }.to raise_error(StandardError)
        end
      end

      context "coverage_service is :travis_pro" do
        before(:each) { fixtures_project.ci_service = :travis_pro }

        it "should return valid json for coveralls coverage data" do
          fixtures_project.stub(:travis_job_id).and_return("9182")
          fixtures_project.stub(:coverage_access_token).and_return("abc123")
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql("{\"service_job_id\":\"9182\",\"service_name\":\"travis-pro\",\"repo_token\":\"abc123\"}").excluding("source_files")
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql(fixtures_project.send(:coverage_files).map(&:as_json).to_json).at_path("source_files")
        end

        it "should raise an error if there is no TRAVIS_JOB_ID" do
          fixtures_project.stub(:travis_job_id).and_return(nil)
          expect { fixtures_project.send(:coveralls_coverage_data) }.to raise_error(StandardError)
        end
      end

      context "coverage_service is :circleci" do
        before(:each) { fixtures_project.ci_service = :circleci }

        it "should return valid json for coveralls coverage data" do
          fixtures_project.stub(:circleci_job_id).and_return("9182")
          fixtures_project.stub(:coverage_access_token).and_return("abc123")
          fixtures_project.stub(:circleci_pull_request).and_return("1")
          fixtures_project.stub(:circleci_build_url).and_return("https://circleci.com/gh/Bruce/Wayne/1")
          fixtures_project.stub(:circleci_git_info).and_return({ :head => { :id => "ababa123", :author_name => "bwayne", :message => "hello" }, :branch => "master" })
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql("{\"service_job_id\":\"9182\",\"service_name\":\"circleci\",\"repo_token\":\"abc123\",\"service_pull_request\":\"1\",\"service_build_url\":\"https://circleci.com/gh/Bruce/Wayne/1\",\"git\":{\"head\":{\"id\":\"ababa123\",\"author_name\":\"bwayne\",\"message\":\"hello\"},\"branch\":\"master\"}}").excluding("source_files")
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql(fixtures_project.send(:coverage_files).map(&:as_json).to_json).at_path("source_files")
        end

        it "should raise an error if there is no CIRCLE_BUILD_NUM" do
          fixtures_project.stub(:circleci_job_id).and_return(nil)
          expect { fixtures_project.send(:coveralls_coverage_data) }.to raise_error(StandardError)
        end
      end

      context "coverage_service is :jenkins" do
        before(:each) { fixtures_project.ci_service = :jenkins }

        it "should return valid json for coveralls coverage data" do
          fixtures_project.stub(:jenkins_job_id).and_return("9182")
          fixtures_project.stub(:coverage_access_token).and_return("abc123")
          fixtures_project.stub(:jenkins_git_info).and_return({head: {id: "master", author_name: "author", message: "pull title" }, branch: "branch"})
          fixtures_project.stub(:jenkins_branch_name).and_return('master')
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql("{\"service_job_id\":\"9182\",\"service_name\":\"jenkins\",\"repo_token\":\"abc123\",\"git\":{\"head\":{\"id\":\"master\",\"author_name\":\"author\",\"message\":\"pull title\"},\"branch\":\"branch\"}}").excluding("source_files")
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql(fixtures_project.send(:coverage_files).map(&:as_json).to_json).at_path("source_files")
        end

        it "should raise an error if there is no BUILD_ID" do
          fixtures_project.stub(:jenkins_job_id).and_return(nil)
          expect { fixtures_project.send(:coveralls_coverage_data) }.to raise_error(StandardError)
        end
      end

      it "should raise an error if it does not recognize the ci_service" do
        fixtures_project.ci_service = :jenkins_ci
        expect { fixtures_project.send(:coveralls_coverage_data) }.to raise_error(StandardError)
      end
    end

    describe '#post' do
      it "should save the coveralls_coverage_data to a file and post it to coveralls" do
        fixtures_project.stub(:travis_job_id).and_return("9182")
        expect(fixtures_project).to receive(:`) do |cmd|
          expect(cmd).to eq("curl -s --form json_file=@coveralls_json_file https://coveralls.io/api/v1/jobs")
          expect(File.read('coveralls_json_file')).to be_json_eql(fixtures_project.send(:coveralls_coverage_data))
        end.once
        fixtures_project.post
      end

      it "should always remove the coveralls_json_file after it's done" do
        fixtures_project.stub(:`)

        fixtures_project.stub(:travis_job_id).and_return("9182")
        fixtures_project.post
        expect(File.exist?("coveralls_json_file")).to be_falsy
        fixtures_project.stub(:travis_job_id).and_return(nil)
        expect { fixtures_project.post }.to raise_error(StandardError)
        expect(File.exist?("coveralls_json_file")).to be_falsy
      end
    end
  end

  context "#profdata file format" do
    before(:each) { 
      fixtures_project.stub(:input_format).and_return("profdata")
      fixtures_project.send(:configure_from_yml)
    }

    describe '#coveralls_coverage_data' do
      context "coverage_service is :travis_ci" do
        before(:each) { fixtures_project.ci_service = :travis_ci }

        it "should return valid json for coveralls coverage profdata data" do
          fixtures_project.stub(:travis_job_id).and_return("9182")
          fixtures_project.stub(:profdata_llvm_cov_output).and_return("/Users/civetta/Works/Personal/slather/viteinfinite-slather/spec/fixtures/fixtures/fixtures.m:
         |    1|//
         |    2|//  fixtures.m
         |    3|//  fixtures
         |    4|//
         |    5|//  Created by Mark Larsen on 6/24/14.
         |    6|//  Copyright (c) 2014 marklarr. All rights reserved.
         |    7|//
         |    8|
         |    9|#import \"fixtures.h\"
         |   10|
         |   11|@implementation fixtures
         |   12|
         |   13|- (void)testedMethod
        1|   14|{
        1|   15|    NSLog(@\"tested\");
        1|   16|}
         |   17|
         |   18|- (void)untestedMethod
        0|   19|{
        0|   20|    NSLog(@\"untested\");
        0|   21|}
         |   22|
         |   23|@end
  ")
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql("{\"service_job_id\":\"9182\",\"service_name\":\"travis-ci\"}").excluding("source_files")
          expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql(fixtures_project.send(:coverage_files).map(&:as_json).to_json).at_path("source_files")
        end
      end
    end
  end
end
