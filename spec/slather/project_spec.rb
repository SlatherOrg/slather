require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::Project do

  let(:fixtures_project) do
    Slather::Project.any_instance.stub(:configure_from_yml)
    Slather::Project.open(FIXTURES_PROJECT_PATH)
  end

  describe "::open" do
    it "should return a project instance that has been configured from yml" do
      expect_any_instance_of(Slather::Project).to receive(:configure_from_yml)
      expect(fixtures_project).not_to be_nil
    end
  end

  describe "#derived_data_dir" do
    it "should return the system's derived data directory" do
      expect(fixtures_project.send(:derived_data_dir)).to eq(File.expand_path('~') + "/Library/Developer/Xcode/DerivedData/")
    end
  end

  describe "#build_directory" do
    it "should return the build_directory property, if it has been explicitly set" do
      build_directory_mock = double(String)
      fixtures_project.build_directory = build_directory_mock
      expect(fixtures_project.build_directory).to eq(build_directory_mock)
    end

    it "should return the derived_data_dir if no build_directory has been set" do
      derived_data_dir_mock = double(String)
      fixtures_project.stub(:derived_data_dir).and_return(derived_data_dir_mock)
      expect(fixtures_project.build_directory).to eq(derived_data_dir_mock)
    end
  end

  describe "::yml" do
    before(:each) { Slather::Project.instance_variable_set("@yml", nil) }

    context ".slather.yml file exists" do
      before(:all) { File.open(".slather.yml", "w") { |f| f.write("two: 2") } }
      after(:all) { File.delete(".slather.yml") }

      it "should load and return .slather.yml, if it exists" do
        expect(Slather::Project.yml).to eq({"two" => 2})
      end
    end

    context ".slather.yml file doesn't exist" do
      it "should return an empy hash" do
        expect(Slather::Project.yml).to eq({})
      end
    end
  end

  describe "#coverage_files" do
    class SpecCoverageFile < Slather::CoverageFile
    end

    before(:each) do
      Dir.stub(:[]).and_call_original
      Dir.stub(:[]).with("#{fixtures_project.build_directory}/**/*.gcno").and_return(["/some/path/fixtures.gcno",
                                                                                  "/some/path/peekaview.gcno",
                                                                                  "/some/path/fixturesTests.gcno",
                                                                                  "/some/path/peekaviewTests.gcno",
                                                                                  "/some/path/NotInProject.gcno",
                                                                                  "/some/path/NSRange.gcno"])
      fixtures_project.stub(:coverage_file_class).and_return(SpecCoverageFile)
    end

    it "should return coverage file objects of type coverage_file_class for unignored project files" do
      fixtures_project.ignore_list = ["*fixturesTests*"]
      coverage_files = fixtures_project.send(:coverage_files)
      coverage_files.each { |cf| expect(cf.kind_of?(SpecCoverageFile)).to be_truthy }
      expect(coverage_files.map { |cf| cf.source_file_pathname.basename.to_s }).to eq(["fixtures.m", "peekaview.m"])
    end

    it "should raise an exception if no unignored project coverage file files were found" do
      fixtures_project.ignore_list = ["*fixturesTests*", "*fixtures*"]
      expect {fixtures_project.send(:coverage_files)}.to raise_error(StandardError)
    end
  end

  describe "#dedupe" do
    it "should return a deduplicated list of coverage files, favoring the file with higher coverage" do
      coverage_file_1 = double(Slather::CoverageFile)
      coverage_file_1.stub(:source_file_pathname).and_return("some/path/class1.m")
      coverage_file_1.stub(:percentage_lines_tested).and_return(100)

      coverage_file_2 = double(Slather::CoverageFile)
      coverage_file_2.stub(:source_file_pathname).and_return("some/path/class2.m")
      coverage_file_2.stub(:percentage_lines_tested).and_return(100)

      coverage_file_2b = double(Slather::CoverageFile)
      coverage_file_2b.stub(:source_file_pathname).and_return("some/path/class2.m")
      coverage_file_2b.stub(:percentage_lines_tested).and_return(0)

      coverage_files = [coverage_file_1, coverage_file_2, coverage_file_2b]
      deduped_coverage_files = fixtures_project.send(:dedupe, coverage_files)
      expect(deduped_coverage_files.size).to eq(2)
      expect(deduped_coverage_files).to include(coverage_file_1)
      expect(deduped_coverage_files).to include(coverage_file_2)
    end
  end

  describe "#configure_from_yml" do
    it "should configure all properties from the yml" do
      unstubbed_project = Slather::Project.open(FIXTURES_PROJECT_PATH)
      expect(unstubbed_project).to receive(:configure_build_directory_from_yml)
      expect(unstubbed_project).to receive(:configure_source_directory_from_yml)
      expect(unstubbed_project).to receive(:configure_ignore_list_from_yml)
      expect(unstubbed_project).to receive(:configure_ci_service_from_yml)
      expect(unstubbed_project).to receive(:configure_coverage_service_from_yml)
      unstubbed_project.configure_from_yml
    end
  end

  describe "#configure_ignore_list_from_yml" do
    it "should set the ignore_list if it has been provided in the yml and has not already been set" do
      Slather::Project.stub(:yml).and_return({"ignore" => ["test", "ing"] })
      fixtures_project.configure_ignore_list_from_yml
      expect(fixtures_project.ignore_list).to eq(["test", "ing"])
    end

    it "should force the ignore_list into an array" do
      Slather::Project.stub(:yml).and_return({"ignore" => "test" })
      fixtures_project.configure_ignore_list_from_yml
      expect(fixtures_project.ignore_list).to eq(["test"])
    end

    it "should not set the ignore_list if it has already been set" do
      Slather::Project.stub(:yml).and_return({"ignore" => ["test", "ing"] })
      fixtures_project.ignore_list = ["already", "set"]
      fixtures_project.configure_ignore_list_from_yml
      expect(fixtures_project.ignore_list).to eq(["already", "set"])
    end

    it "should default the ignore_list to an empty array if nothing is provided in the yml" do
      Slather::Project.stub(:yml).and_return({})
      fixtures_project.configure_ignore_list_from_yml
      expect(fixtures_project.ignore_list).to eq([])
    end
  end

  describe "#configure_build_directory_from_yml" do
    it "should set the build_directory if it has been provided in the yml and has not already been set" do
      Slather::Project.stub(:yml).and_return({"build_directory" => "/some/path"})
      fixtures_project.configure_build_directory_from_yml
      expect(fixtures_project.build_directory).to eq("/some/path")
    end

    it "should not set the build_directory if it has already been set" do
      Slather::Project.stub(:yml).and_return({"build_directory" => "/some/path"})
      fixtures_project.build_directory = "/already/set"
      fixtures_project.configure_build_directory_from_yml
      expect(fixtures_project.build_directory).to eq("/already/set")
    end

    it "should default the build_directory to derived data if nothing is provided in the yml" do
      Slather::Project.stub(:yml).and_return({})
      fixtures_project.configure_build_directory_from_yml
      expect(fixtures_project.build_directory).to eq(fixtures_project.send(:derived_data_dir))
    end
  end

  describe "#configure_source_directory_from_yml" do
    it "should set the source_directory if it has been provided in the yml and has not already been set" do
      Slather::Project.stub(:yml).and_return({"source_directory" => "/some/path"})
      fixtures_project.configure_source_directory_from_yml
      expect(fixtures_project.source_directory).to eq("/some/path")
    end

    it "should not set the source_directory if it has already been set" do
      Slather::Project.stub(:yml).and_return({"source_directory" => "/some/path"})
      fixtures_project.source_directory = "/already/set"
      fixtures_project.configure_source_directory_from_yml
      expect(fixtures_project.source_directory).to eq("/already/set")
    end
  end

  describe "#configure_ci_service_from_yml" do
    it "should set the ci_service if it has been provided in the yml and has not already been set" do
      Slather::Project.stub(:yml).and_return({"ci_service" => "some_service"})
      fixtures_project.configure_ci_service_from_yml
      expect(fixtures_project.ci_service).to eq(:some_service)
    end

    it "should not set the ci_service if it has already been set" do
      Slather::Project.stub(:yml).and_return({"ci_service" => "some service"})
      fixtures_project.ci_service = "already_set"
      fixtures_project.configure_ci_service_from_yml
      expect(fixtures_project.ci_service).to eq(:already_set)
    end

    it "should default the ci_service to :travis_ci if nothing is provided in the yml" do
      Slather::Project.stub(:yml).and_return({})
      fixtures_project.configure_ci_service_from_yml
      expect(fixtures_project.ci_service).to eq(:travis_ci)
    end
  end

  describe "#ci_service=" do
    it "should set the ci_service as a symbol" do
      fixtures_project.ci_service = "foobar"
      expect(fixtures_project.ci_service).to eq(:foobar)
    end
  end

  describe "#configure_coverage_service_from_yml" do
    it "should set the coverage_service if it has been provided by the yml" do
      Slather::Project.stub(:yml).and_return({"coverage_service" => "some_service"})
      expect(fixtures_project).to receive(:coverage_service=).with("some_service")
      fixtures_project.configure_coverage_service_from_yml
    end

    it "should default the coverage_service to :terminal if nothing is provided in the yml" do
      Slather::Project.stub(:yml).and_return({})
      expect(fixtures_project).to receive(:coverage_service=).with(:terminal)
      fixtures_project.configure_coverage_service_from_yml
    end

    it "should not set the coverage_service if it has already been set" do
      Slather::Project.stub(:yml).and_return({"coverage_service" => "some_service" })
      fixtures_project.stub(:coverage_service).and_return("already set")
      expect(fixtures_project).to_not receive(:coverage_service=)
      fixtures_project.configure_coverage_service_from_yml
    end
  end

  describe "#coverage_service=" do
    it "should extend Slather::CoverageService::Coveralls and set coverage_service = :coveralls if given coveralls" do
      expect(fixtures_project).to receive(:extend).with(Slather::CoverageService::Coveralls)
      fixtures_project.coverage_service = "coveralls"
      expect(fixtures_project.coverage_service).to eq(:coveralls)
    end

    it "should extend Slather::CoverageService::SimpleOutput and set coverage_service = :terminal if given terminal" do
      expect(fixtures_project).to receive(:extend).with(Slather::CoverageService::SimpleOutput)
      fixtures_project.coverage_service = "terminal"
      expect(fixtures_project.coverage_service).to eq(:terminal)
    end

    it "should raise an exception if it does not recognize the coverage service" do
      expect { fixtures_project.coverage_service = "xcode bots, lol" }.to raise_error(StandardError)
    end
  end

  describe "#slather_setup_for_coverage" do
    it "should enable the correct flags to generate test coverage on all of the build_configurations build settings" do
      fixtures_project.slather_setup_for_coverage
      fixtures_project.build_configurations.each do |build_configuration|
        expect(build_configuration.build_settings["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"]).to eq("YES")
        expect(build_configuration.build_settings["GCC_GENERATE_TEST_COVERAGE_FILES"]).to eq("YES")
      end
    end
  end
end
