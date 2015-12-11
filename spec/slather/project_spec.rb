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

  describe "#derived_data_path" do
    it "should return the system's derived data directory" do
      expect(fixtures_project.send(:derived_data_path)).to eq(File.expand_path('~') + "/Library/Developer/Xcode/DerivedData/")
    end
  end

  describe "#build_directory" do
    it "should return the build_directory property, if it has been explicitly set" do
      build_directory_mock = double(String)
      fixtures_project.build_directory = build_directory_mock
      expect(fixtures_project.build_directory).to eq(build_directory_mock)
    end

    it "should return the derived_data_path if no build_directory has been set" do
      derived_data_path_mock = double(String)
      fixtures_project.stub(:derived_data_path).and_return(derived_data_path_mock)
      expect(fixtures_project.build_directory).to eq(derived_data_path_mock)
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
      fixtures_project.stub(:dedupe) { |coverage_files| coverage_files }
      coverage_files = fixtures_project.send(:coverage_files)
      coverage_files.each { |cf| expect(cf.kind_of?(SpecCoverageFile)).to be_truthy }
      expect(coverage_files.map { |cf| cf.source_file_pathname.basename.to_s }).to eq(["fixtures.m", "peekaview.m"])
    end

    it "should raise an exception if no unignored project coverage file files were found" do
      fixtures_project.ignore_list = ["*fixturesTests*", "*fixtures*"]
      expect {fixtures_project.send(:coverage_files)}.to raise_error(StandardError)
    end
  end

  describe "#profdata_coverage_files" do
    class SpecXcode7CoverageFile < Slather::ProfdataCoverageFile
    end

    before(:each) do
      Dir.stub(:[]).and_call_original
      Dir.stub(:[]).with("#{fixtures_project.build_directory}/**/Coverage.profdata").and_return(["/some/path/Coverage.profdata"])
      fixtures_project.stub(:profdata_llvm_cov_output).and_return("#{FIXTURES_SWIFT_FILE_PATH}:
       |    0|
       |    1|import UIKit
       |    2|
       |    3|@UIApplicationMain
       |    4|class AppDelegate: UIResponder, UIApplicationDelegate {
       |    5|
       |    6|    var window: UIWindow?
       |    7|
      1|    8|    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
      1|    9|        return true
      1|   10|    }
       |   11|
      0|   12|    func applicationWillResignActive(application: UIApplication) {
      0|   13|    }
      0|   14|}")
      fixtures_project.stub(:coverage_file_class).and_return(SpecXcode7CoverageFile)
      fixtures_project.stub(:ignore_list).and_return([])
    end

    it "should return Coverage.profdata file objects" do
      profdata_coverage_files = fixtures_project.send(:profdata_coverage_files)
      profdata_coverage_files.each { |cf| expect(cf.kind_of?(SpecXcode7CoverageFile)).to be_truthy }
      expect(profdata_coverage_files.map { |cf| cf.source_file_pathname.basename.to_s }).to eq(["Fixtures.swift"])
    end

    it "should ignore files from the ignore list" do
      fixtures_project.stub(:ignore_list).and_return(["**/Fixtures.swift"])
      profdata_coverage_files = fixtures_project.send(:profdata_coverage_files)
      expect(profdata_coverage_files.count).to eq(0)
    end
  end

  describe "#binary_file" do
    before(:each) do
      Dir.stub(:[]).and_call_original
      fixtures_project.stub(:scheme).and_return("FixtureScheme")
      Dir.stub(:[]).with("#{fixtures_project.build_directory}/**/CodeCoverage/FixtureScheme").and_return(["/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme"])
      Dir.stub(:[]).with("/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/**/*.xctest").and_return(["/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/FixtureAppTests.xctest"])
    end

    it "should return the binary file location for a test bundle provided a scheme" do
      Dir.stub(:[]).with("/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/FixtureAppTests.xctest/**/FixtureAppTests").and_return(["/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/FixtureAppTests.xctest/Contents/MacOS/FixtureAppTests"])
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location).to eq("/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/FixtureAppTests.xctest/Contents/MacOS/FixtureAppTests")
    end

    it "should return the binary file location for an app bundle provided a scheme" do
      Dir.stub(:[]).with("/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/*.app").and_return(["/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/FixtureApp.app"])
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location).to eq("/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/FixtureApp.app/FixtureApp")
    end

    it "should return the binary file location for a framework bundle provided a scheme" do
      Dir.stub(:[]).with("/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/*.framework").and_return(["/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/FixtureFramework.framework"])
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location).to eq("/Users/venmo/Library/Developer/Xcode/DerivedData/FixtureScheme/FixtureFramework.framework/FixtureFramework")
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
      expect(unstubbed_project).to receive(:configure_input_format_from_yml)
      expect(unstubbed_project).to receive(:configure_scheme_from_yml)
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
      expect(fixtures_project.build_directory).to eq(fixtures_project.send(:derived_data_path))
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

  describe "#configure_output_directory_from_yml" do
    it "should set the output_directory if it has been provided in the yml and has not already been set" do
      Slather::Project.stub(:yml).and_return({"output_directory" => "/some/path"})
      fixtures_project.configure_output_directory_from_yml
      expect(fixtures_project.output_directory).to eq("/some/path")
    end

    it "should not set the output_directory if it has already been set" do
      Slather::Project.stub(:yml).and_return({"output_directory" => "/some/path"})
      fixtures_project.output_directory = "/already/set"
      fixtures_project.configure_output_directory_from_yml
      expect(fixtures_project.output_directory).to eq("/already/set")
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

  describe "#configure_coverage_access_token" do
    it "should set the coverage_access_token if it has been provided by the yml" do
      Slather::Project.stub(:yml).and_return({"coverage_access_token" => "abc123"})
      expect(fixtures_project).to receive(:coverage_access_token=).with("abc123")
      fixtures_project.configure_coverage_access_token_from_yml
    end
    
    it "should set the coverage_access_token if it is in the ENV" do
      stub_const('ENV', ENV.to_hash.merge('COVERAGE_ACCESS_TOKEN' => 'asdf456'))
      expect(fixtures_project).to receive(:coverage_access_token=).with("asdf456")
      fixtures_project.configure_coverage_access_token_from_yml
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
