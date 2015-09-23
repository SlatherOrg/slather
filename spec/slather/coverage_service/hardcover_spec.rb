require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Slather::CoverageService::Hardcover do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::Hardcover)
  end

  let(:fixture_yaml) do
      yaml_text = <<-EOF
        hardcover_repo_token: "27dd855e706b22126ec6daaaf7bb40b5"
        hardcover_base_url: "http://api.hardcover.io"
      EOF
      yaml = YAML.load(yaml_text)
  end

  describe "#coverage_file_class" do
    it "should return CoverallsCoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverageFile)
    end
  end

  describe "#job_id" do
    it "should return the Jenkins JOB_NAME and BUILD_NUMBER environment variables" do
      ENV['BUILD_NUMBER'] = "9182"
      ENV['JOB_NAME'] = "slather-master"
      expect(fixtures_project.send(:jenkins_job_id)).to eq("slather-master/9182")
    end
  end

  describe '#hardcover_coverage_data' do

    context "coverage_service is :jenkins_ci" do
      before(:each) do
        fixtures_project.ci_service = :jenkins_ci
        Slather::Project.stub(:yml).and_return(fixture_yaml)
      end

      it "should return a valid json" do
        json = JSON(fixtures_project.send(:hardcover_coverage_data))
        expect(json["service_job_id"]).to eq("slather-master/9182")
        expect(json["service_name"]).to eq("jenkins-ci")
        expect(json["repo_token"]).to eq("27dd855e706b22126ec6daaaf7bb40b5")
        expect(json["source_files"]).to_not be_empty
      end

      it "should raise an error if there is no BUILD_NUMBER or JOB_NAME" do
        fixtures_project.stub(:jenkins_job_id).and_return(nil)
        expect { fixtures_project.send(:hardcover_coverage_data) }.to raise_error(StandardError)
      end
    end

    it "should raise an error if it does not recognize the ci_service" do
      fixtures_project.ci_service = :non_existing_ci
      expect { fixtures_project.send(:hardcover_coverage_data) }.to raise_error(StandardError)
    end
  end

  describe '#post' do
    before(:each) do
      Slather::Project.stub(:yml).and_return(fixture_yaml)
      fixtures_project.ci_service = :jenkins_ci
    end

    it "should save the hardcover_coverage_data to a file and post it to hardcover" do
      fixtures_project.stub(:jenkins_job_id).and_return("slather-master/9182")
      fixtures_project.stub(:coverage_service_url).and_return("http://api.hardcover.io")
      expect(fixtures_project).to receive(:`) do |cmd|
        expect(cmd).to eq("curl --form json_file=@hardcover_json_file http://api.hardcover.io/v1/jobs")
      end.once
      fixtures_project.post
    end

    it "should always remove the hardcover_json_file after it's done" do
      fixtures_project.stub(:`)

      fixtures_project.stub(:jenkins_job_id).and_return("slather-master/9182")
      fixtures_project.stub(:coverage_service_url).and_return("http://api.hardcover.io")
      fixtures_project.post
      expect(File.exist?("hardcover_json_file")).to be_falsy
      fixtures_project.stub(:jenkins_job_id).and_return(nil)
      expect { fixtures_project.post }.to raise_error(StandardError)
      expect(File.exist?("hardcover_json_file")).to be_falsy
    end
  end
end
