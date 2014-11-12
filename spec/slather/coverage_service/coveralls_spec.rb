require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Slather::CoverageService::Coveralls do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::Coveralls)
  end

  describe "#coverage_file_class" do
    it "should return CoverallsCoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverallsCoverageFile)
    end
  end

  describe "#travis_job_id" do
    it "should return the TRAVIS_JOB_ID environment variable" do
      ENV['TRAVIS_JOB_ID'] = "9182"
      expect(fixtures_project.send(:travis_job_id)).to eq("9182")
    end
  end

  describe '#coveralls_coverage_data' do

    context "coverage_service is :travis_ci" do
      before(:each) { fixtures_project.ci_service = :travis_ci }

      it "should return valid json for coveralls coverage data" do
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
        fixtures_project.stub(:ci_access_token).and_return("abc123")
        expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql("{\"service_job_id\":\"9182\",\"service_name\":\"travis-pro\",\"repo_token\":\"abc123\"}").excluding("source_files")
        expect(fixtures_project.send(:coveralls_coverage_data)).to be_json_eql(fixtures_project.send(:coverage_files).map(&:as_json).to_json).at_path("source_files")
      end

      it "should raise an error if there is no TRAVIS_JOB_ID" do
        fixtures_project.stub(:travis_job_id).and_return(nil)
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
      expect { fixtures_project.post }.to raise_error
      expect(File.exist?("coveralls_json_file")).to be_falsy
    end
  end
end
