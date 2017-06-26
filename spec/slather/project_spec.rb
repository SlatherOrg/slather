require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::Project do

  FIXTURES_PROJECT_SETUP_PATH = 'fixtures_setup.xcodeproj'

  let(:fixtures_project) do
    Slather::Project.open(FIXTURES_PROJECT_PATH)
  end

  describe "#build_directory" do
    it "should return the build_directory property, if it has been explicitly set" do
      build_directory_mock = double(String)
      fixtures_project.build_directory = build_directory_mock
      expect(fixtures_project.build_directory).to eq(build_directory_mock)
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
      allow(Dir).to receive(:[]).and_call_original
      allow(Dir).to receive(:[]).with("#{fixtures_project.build_directory}/**/*.gcno").and_return(["/some/path/fixtures.gcno",
                                                                                  "/some/path/peekaview.gcno",
                                                                                  "/some/path/fixturesTests.gcno",
                                                                                  "/some/path/peekaviewTests💣.gcno",
                                                                                  "/some/path/NotInProject.gcno",
                                                                                  "/some/path/NSRange.gcno"])
      allow(fixtures_project).to receive(:coverage_file_class).and_return(SpecCoverageFile)
    end

    it "should return coverage file objects of type coverage_file_class for unignored project files" do
      fixtures_project.ignore_list = ["*fixturesTests*"]
      allow(fixtures_project).to receive(:dedupe) { |coverage_files| coverage_files }
      coverage_files = fixtures_project.coverage_files
      coverage_files.each { |cf| expect(cf.kind_of?(SpecCoverageFile)).to be_truthy }
      expect(coverage_files.map { |cf| cf.source_file_pathname.basename.to_s }).to eq(["fixtures.m", "peekaview.m"])
    end

    it "should raise an exception if no unignored project coverage file files were found" do
      fixtures_project.ignore_list = ["*fixturesTests*", "*fixtures*"]
      expect {fixtures_project.coverage_files}.to exit_with_code(102)
    end
  end

  describe "#profdata_coverage_files" do
    class SpecXcode7CoverageFile < Slather::ProfdataCoverageFile
    end

    before(:each) do
      allow(Dir).to receive(:[]).and_call_original
      allow(Dir).to receive(:[]).with("#{fixtures_project.build_directory}/**/Coverage.profdata").and_return(["/some/path/Coverage.profdata"])
      allow(fixtures_project).to receive(:binary_file).and_return(["Fixtures"])
      allow(fixtures_project).to receive(:profdata_llvm_cov_output).and_return("#{FIXTURES_SWIFT_FILE_PATH}:
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
      allow(fixtures_project).to receive(:coverage_file_class).and_return(SpecXcode7CoverageFile)
      allow(fixtures_project).to receive(:ignore_list).and_return([])
    end

    it "should return Coverage.profdata file objects" do
      profdata_coverage_files = fixtures_project.send(:profdata_coverage_files)
      profdata_coverage_files.each { |cf| expect(cf.kind_of?(SpecXcode7CoverageFile)).to be_truthy }
      expect(profdata_coverage_files.map { |cf| cf.source_file_pathname.basename.to_s }).to eq(["Fixtures.swift"])
    end

    it "should ignore files from the ignore list" do
      allow(fixtures_project).to receive(:ignore_list).and_return(["**/Fixtures.swift"])
      profdata_coverage_files = fixtures_project.send(:profdata_coverage_files)
      expect(profdata_coverage_files.count).to eq(0)
    end
  end

  describe "#invalid_characters" do
    it "should correctly encode invalid characters" do
      allow(fixtures_project).to receive(:input_format).and_return("profdata")
      allow(fixtures_project).to receive(:ignore_list).and_return([])
      allow(Dir).to receive(:[]).with("#{fixtures_project.build_directory}/**/Coverage.profdata").and_return(["/some/path/Coverage.profdata"])
      allow(fixtures_project).to receive(:binary_file).and_return(["Fixtures"])
      allow(fixtures_project).to receive(:unsafe_profdata_llvm_cov_output).and_return("#{FIXTURES_SWIFT_FILE_PATH}:
      1|    8|    func application(application: \255, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
      1|    9|        return true
      0|   14|}")
      fixtures_project.extend(Slather::CoverageService::HtmlOutput)
      profdata_coverage_files = fixtures_project.send(:profdata_coverage_files)
      expect(profdata_coverage_files.count).to eq(1)
    end
  end

  describe "#binary_file" do

    let(:build_directory) do
      TEMP_DERIVED_DATA_PATH
    end

    before(:each) do
      allow(Dir).to receive(:[]).and_call_original
      allow(fixtures_project).to receive(:build_directory).and_return(build_directory)
      allow(fixtures_project).to receive(:input_format).and_return("profdata")
      allow(fixtures_project).to receive(:scheme).and_return("fixtures")
      allow(Dir).to receive(:[]).with("#{build_directory}/**/CodeCoverage/FixtureScheme").and_return(["#{build_directory}/Build/Intermediates/CodeCoverage/FixtureScheme"])
      allow(Dir).to receive(:[]).with("#{build_directory}/Build/Intermediates/CodeCoverage/FixtureScheme/**/*.xctest").and_return(["#{build_directory}/Build/Intermediates/CodeCoverage/FixtureScheme/FixtureAppTests.xctest"])
    end

    it "should use binary_file" do
      fixtures_project.binary_file = ["/path/to/binary"]
      fixtures_project.send(:configure_binary_file)
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location.count).to eq(1)
      expect(binary_file_location.first).to eq("/path/to/binary")
    end

    it "should find the product path provided a scheme" do
      allow(fixtures_project).to receive(:scheme).and_return("fixtures")
      fixtures_project.send(:configure_binary_file)
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location.count).to eq(1)
      expect(binary_file_location.first).to end_with("Debug/fixturesTests.xctest/Contents/MacOS/fixturesTests")
    end

    it "should find the product path provided a workspace and scheme" do
      allow(fixtures_project).to receive(:workspace).and_return("fixtures.xcworkspace")
      allow(fixtures_project).to receive(:scheme).and_return("fixtures")
      fixtures_project.send(:configure_binary_file)
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location.count).to eq(1)
      expect(binary_file_location.first).to end_with("Debug/fixturesTests.xctest/Contents/MacOS/fixturesTests")
    end

    it "should find the product path for a scheme with no buildable products" do
      allow(fixtures_project).to receive(:scheme).and_return("fixturesTests")
      fixtures_project.send(:configure_binary_file)
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location.count).to eq(1)
      expect(binary_file_location.first).to end_with("Debug/fixturesTests.xctest/Contents/MacOS/fixturesTests")
    end

    it "should find multiple unique paths for a scheme with serveral buildable/testable products" do
      allow(fixtures_project).to receive(:scheme).and_return("aggregateFixturesTests")
      fixtures_project.send(:configure_binary_file)
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location).to contain_exactly(
                                          end_with("Debug/fixturesTests.xctest/Contents/MacOS/fixturesTests"),
                                          end_with("Debug/fixturesTestsSecond.xctest/Contents/MacOS/fixturesTestsSecond"),
                                      )
    end

    let(:fixture_yaml) do
        yaml_text = <<-EOF
          binary_file: "/FixtureScheme/From/Yaml/Contents/MacOS/FixturesFromYaml"
        EOF
        yaml = YAML.load(yaml_text)
    end

    it "should configure the binary_file from yml" do
      allow(Slather::Project).to receive(:yml).and_return(fixture_yaml)
      fixtures_project.send(:configure_binary_file)
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location).to eq(["/FixtureScheme/From/Yaml/Contents/MacOS/FixturesFromYaml"])
    end

    let(:other_fixture_yaml) do
      yaml_text = <<-EOF
        binary_basename: "fixtures"
      EOF
      yaml = YAML.load(yaml_text)
    end

    it "should configure the binary_basename from yml" do
      allow(Slather::Project).to receive(:yml).and_return(other_fixture_yaml)
      allow(Dir).to receive(:[]).with("#{build_directory}/Build/Intermediates/CodeCoverage/Products/Debug/fixtureTests.xctest").and_return(["fixtureTests.xctest"])
      fixtures_project.send(:configure_binary_file)
      binary_file_location = fixtures_project.send(:binary_file)
      expect(binary_file_location.count).to eq(1)
      expect(binary_file_location.first).to end_with("/fixturesTests.xctest/Contents/MacOS/fixturesTests")
    end
  end

  describe "#dedupe" do
    it "should return a deduplicated list of coverage files, favoring the file with higher coverage" do
      coverage_file_1 = double(Slather::CoverageFile)
      allow(coverage_file_1).to receive(:source_file_pathname).and_return("some/path/class1.m")
      allow(coverage_file_1).to receive(:percentage_lines_tested).and_return(100)

      coverage_file_2 = double(Slather::CoverageFile)
      allow(coverage_file_2).to receive(:source_file_pathname).and_return("some/path/class2.m")
      allow(coverage_file_2).to receive(:percentage_lines_tested).and_return(100)

      coverage_file_2b = double(Slather::CoverageFile)
      allow(coverage_file_2b).to receive(:source_file_pathname).and_return("some/path/class2.m")
      allow(coverage_file_2b).to receive(:percentage_lines_tested).and_return(0)

      coverage_files = [coverage_file_1, coverage_file_2, coverage_file_2b]
      deduped_coverage_files = fixtures_project.send(:dedupe, coverage_files)
      expect(deduped_coverage_files.size).to eq(2)
      expect(deduped_coverage_files).to include(coverage_file_1)
      expect(deduped_coverage_files).to include(coverage_file_2)
    end
  end

  describe "#configure" do
    it "should configure all properties from the yml" do
      unstubbed_project = Slather::Project.open(FIXTURES_PROJECT_PATH)
      expect(unstubbed_project).to receive(:configure_build_directory)
      expect(unstubbed_project).to receive(:configure_source_directory)
      expect(unstubbed_project).to receive(:configure_ignore_list)
      expect(unstubbed_project).to receive(:configure_ci_service)
      expect(unstubbed_project).to receive(:configure_coverage_service)
      expect(unstubbed_project).to receive(:configure_input_format)
      expect(unstubbed_project).to receive(:configure_scheme)
      expect(unstubbed_project).to receive(:configure_configuration)
      expect(unstubbed_project).to receive(:configure_workspace)
      unstubbed_project.configure
    end
  end

  describe "#configure_ignore_list" do
    it "should set the ignore_list if it has been provided in the yml and has not already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"ignore" => ["test", "ing"] })
      fixtures_project.configure_ignore_list
      expect(fixtures_project.ignore_list).to eq(["test", "ing"])
    end

    it "should force the ignore_list into an array" do
      allow(Slather::Project).to receive(:yml).and_return({"ignore" => "test" })
      fixtures_project.configure_ignore_list
      expect(fixtures_project.ignore_list).to eq(["test"])
    end

    it "should not set the ignore_list if it has already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"ignore" => ["test", "ing"] })
      fixtures_project.ignore_list = ["already", "set"]
      fixtures_project.configure_ignore_list
      expect(fixtures_project.ignore_list).to eq(["already", "set"])
    end

    it "should default the ignore_list to an empty array if nothing is provided in the yml" do
      allow(Slather::Project).to receive(:yml).and_return({})
      fixtures_project.configure_ignore_list
      expect(fixtures_project.ignore_list).to eq([])
    end
  end

  describe "#configure_build_directory" do
    it "should set the build_directory if it has been provided in the yml and has not already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"build_directory" => "/some/path"})
      fixtures_project.configure_build_directory
      expect(fixtures_project.build_directory).to eq("/some/path")
    end

    it "should not set the build_directory if it has already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"build_directory" => "/some/path"})
      fixtures_project.build_directory = "/already/set"
      fixtures_project.configure_build_directory
      expect(fixtures_project.build_directory).to eq("/already/set")
    end

    it "should default the build_directory to derived data if nothing is provided in the yml" do
      allow(Slather::Project).to receive(:yml).and_return({})
      fixtures_project.configure_build_directory
      expect(fixtures_project.build_directory).to eq(fixtures_project.send(:derived_data_path))
    end
  end

  describe "#configure_source_directory" do
    it "should set the source_directory if it has been provided in the yml and has not already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"source_directory" => "/some/path"})
      fixtures_project.configure_source_directory
      expect(fixtures_project.source_directory).to eq("/some/path")
    end

    it "should not set the source_directory if it has already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"source_directory" => "/some/path"})
      fixtures_project.source_directory = "/already/set"
      fixtures_project.configure_source_directory
      expect(fixtures_project.source_directory).to eq("/already/set")
    end
  end

  describe "#configure_output_directory" do
    it "should set the output_directory if it has been provided in the yml and has not already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"output_directory" => "/some/path"})
      fixtures_project.configure_output_directory
      expect(fixtures_project.output_directory).to eq("/some/path")
    end

    it "should not set the output_directory if it has already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"output_directory" => "/some/path"})
      fixtures_project.output_directory = "/already/set"
      fixtures_project.configure_output_directory
      expect(fixtures_project.output_directory).to eq("/already/set")
    end
  end

  describe "#configure_configuration" do
    it "should set the configuration if it has been provided in the yml and has not already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"configuration" => "Release"})
      fixtures_project.configure_configuration
      expect(fixtures_project.configuration).to eq("Release")
    end

    it "should not set the configuration if it has already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"configuration" => "Release"})
      fixtures_project.configuration = "Debug"
      fixtures_project.configure_configuration
      expect(fixtures_project.configuration).to eq("Debug")
    end
  end

  describe "#configure_workspace" do
    it "should set the workspace if it has been provided in the yml and has not already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"workspace" => "fixtures.xcworkspace"})
      fixtures_project.configure_workspace
      expect(fixtures_project.workspace).to eq("fixtures.xcworkspace")
    end

    it "should not set the workspace if it has already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"workspace" => "fixtures.xcworkspace"})
      fixtures_project.workspace = "MyWorkspace.xcworkspace"
      fixtures_project.configure_workspace
      expect(fixtures_project.workspace).to eq("MyWorkspace.xcworkspace")
    end
  end

  describe "#configure_ci_service" do
    it "should set the ci_service if it has been provided in the yml and has not already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"ci_service" => "some_service"})
      fixtures_project.configure_ci_service
      expect(fixtures_project.ci_service).to eq(:some_service)
    end

    it "should not set the ci_service if it has already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"ci_service" => "some service"})
      fixtures_project.ci_service = "already_set"
      fixtures_project.configure_ci_service
      expect(fixtures_project.ci_service).to eq(:already_set)
    end

    it "should default the ci_service to :travis_ci if nothing is provided in the yml" do
      allow(Slather::Project).to receive(:yml).and_return({})
      fixtures_project.configure_ci_service
      expect(fixtures_project.ci_service).to eq(:travis_ci)
    end
  end

  describe "#ci_service=" do
    it "should set the ci_service as a symbol" do
      fixtures_project.ci_service = "foobar"
      expect(fixtures_project.ci_service).to eq(:foobar)
    end
  end

  describe "#configure_coverage_service" do
    it "should set the coverage_service if it has been provided by the yml" do
      allow(Slather::Project).to receive(:yml).and_return({"coverage_service" => "some_service"})
      expect(fixtures_project).to receive(:coverage_service=).with("some_service")
      fixtures_project.configure_coverage_service
    end

    it "should default the coverage_service to :terminal if nothing is provided in the yml" do
      allow(Slather::Project).to receive(:yml).and_return({})
      expect(fixtures_project).to receive(:coverage_service=).with(:terminal)
      fixtures_project.configure_coverage_service
    end

    it "should not set the coverage_service if it has already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"coverage_service" => "some_service" })
      allow(fixtures_project).to receive(:coverage_service).and_return("already set")
      expect(fixtures_project).to_not receive(:coverage_service=)
      fixtures_project.configure_coverage_service
    end
  end

  describe "#configure_coverage_access_token" do
    it "should set the coverage_access_token if it has been provided by the yml" do
      allow(Slather::Project).to receive(:yml).and_return({"coverage_access_token" => "abc123"})
      expect(fixtures_project).to receive(:coverage_access_token=).with("abc123")
      fixtures_project.configure_coverage_access_token
    end

    it "should set the coverage_access_token if it is in the ENV" do
      stub_const('ENV', ENV.to_hash.merge('COVERAGE_ACCESS_TOKEN' => 'asdf456'))
      expect(fixtures_project).to receive(:coverage_access_token=).with("asdf456")
      fixtures_project.configure_coverage_access_token
    end

  end

  describe "#configure_input_format" do
    it "should set the input_format if it has been provided by the yml" do
      allow(Slather::Project).to receive(:yml).and_return({"input_format" => "gcov"})
      fixtures_project.configure_input_format
      expect(fixtures_project.input_format).to eq("gcov")
    end

    it "should default the input_format to auto if nothing is provided in the yml" do
      allow(Slather::Project).to receive(:yml).and_return({})
      expect(fixtures_project).to receive(:input_format=).with("auto")
      fixtures_project.configure_input_format
    end

    it "should not set the input_format if it has already been set" do
      allow(Slather::Project).to receive(:yml).and_return({"input_format" => "some_format" })
      fixtures_project.input_format = "gcov"
      expect(fixtures_project).to_not receive(:input_format=)
      fixtures_project.configure_input_format
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
      expect { fixtures_project.coverage_service = "xcode bots, lol" }.to exit_with_code(109)
    end
  end

  describe "#slather_setup_for_coverage" do

    let(:fixtures_project_setup) do
      FileUtils.cp_r "#{FIXTURES_PROJECT_PATH}/", "#{FIXTURES_PROJECT_SETUP_PATH}/"
      allow_any_instance_of(Slather::Project).to receive(:configure)
      Slather::Project.open(FIXTURES_PROJECT_SETUP_PATH)
    end

    after(:each) do
      FileUtils.rm_rf(FIXTURES_PROJECT_SETUP_PATH)
    end

    it "should enable the correct flags to generate test coverage on all of the build_configurations build settings" do
      fixtures_project_setup.slather_setup_for_coverage
      fixtures_project_setup.build_configurations.each do |build_configuration|
        expect(build_configuration.build_settings["GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"]).to eq("YES")
        expect(build_configuration.build_settings["GCC_GENERATE_TEST_COVERAGE_FILES"]).to eq("YES")
      end
    end

    it "should apply Xcode7 enableCodeCoverage setting" do
      fixtures_project_setup.slather_setup_for_coverage
      schemes_path = Xcodeproj::XCScheme.shared_data_dir(fixtures_project_setup.path)
      Xcodeproj::Project.schemes(fixtures_project_setup.path).each do |scheme_name|
        xcscheme_path = "#{schemes_path + scheme_name}.xcscheme"
        xcscheme = Xcodeproj::XCScheme.new(xcscheme_path)
        expect(xcscheme.test_action.xml_element.attributes['codeCoverageEnabled']).to eq("YES")
      end
    end

    it "should fail for unknown coverage type" do
      expect { fixtures_project_setup.slather_setup_for_coverage "this should fail" }.to exit_with_code(101)
    end
  end

  describe "#verbose_mode" do

    let(:fixtures_project) do
      proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
      proj.build_directory = TEMP_DERIVED_DATA_PATH
      proj.input_format = "profdata"
      proj.verbose_mode = true
      proj.configure
      proj
    end

    it "should print out environment info when in verbose_mode" do
      project_root = Pathname("./").realpath

      ["\nProcessing coverage file: #{project_root}/spec/DerivedData/libfixtures/Build/Intermediates/CodeCoverage/Coverage.profdata",
       "Against binary files:",
       "\t#{project_root}/spec/DerivedData/libfixtures/Build/Intermediates/CodeCoverage/Products/Debug/fixturesTests.xctest/Contents/MacOS/fixturesTests",
       "\n"
      ].each do |line|
        expect(fixtures_project).to receive(:puts).with(line)
      end

      fixtures_project.send(:configure)
    end

    it "should print error when no binaries found" do
      allow(fixtures_project).to receive(:binary_file).and_return(nil)

      project_root = Pathname("./").realpath

      ["\nProcessing coverage file: #{project_root}/spec/DerivedData/libfixtures/Build/Intermediates/CodeCoverage/Coverage.profdata",
       "No binary files found.",
       "\n",
      ].each do |line|
        expect(fixtures_project).to receive(:puts).with(line)
      end

      fixtures_project.send(:configure)
    end
  end

  describe "#source_files" do

    let(:fixtures_project) do
      proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
      proj.build_directory = TEMP_DERIVED_DATA_PATH
      proj.input_format = "profdata"
      proj.source_files = ["./**/fixtures{,Two}.m"]
      proj.binary_basename = ["fixturesTests", "libfixturesTwo"]
      proj.configure
      proj
    end

    it "should find relevant source files" do
      source_files = fixtures_project.find_source_files
      expect(source_files.count).to eq(2)
      expect(source_files.first.to_s).to include("fixtures.m")
      expect(source_files.last.to_s).to include("fixturesTwo.m")
    end

    it "should print out the coverage for each file, and then total coverage" do
      ["spec/fixtures/fixtures/fixtures.m: 3 of 6 lines (50.00%)",
      "spec/fixtures/fixturesTwo/fixturesTwo.m: 6 of 6 lines (100.00%)",
      "Test Coverage: 75.00%"
      ].each do |line|
        expect(fixtures_project).to receive(:puts).with(line)
      end
      fixtures_project.post
    end
  end

  def decimal_f *args
    fixtures_project.decimal_f *args
  end

  describe '#decimal_f' do
    it 'should preserve length 2 decimals for backwards compatibility' do
      expect(decimal_f('100.00')).to eq('100.00')
      expect(decimal_f('50.00')).to eq('50.00')
    end

    it 'should convert length >= 3 decimals to floats' do
      fixtures_project.decimals = 3
      expect(decimal_f('100.000')).to eq('100.0')
      expect(decimal_f('50.00000')).to eq('50.0')
    end
  end

  describe '#find_binary_files' do
    let(:configuration) { 'Debug' }
    let(:project_root) { Pathname("./").realpath }
    let(:coverage_dir) { "#{project_root}/spec/DerivedData/DerivedData/Build/Intermediates/CodeCoverage" }
    let(:search_dir) { "#{coverage_dir}/Products/#{configuration}*/fixtures*" }
    let(:binary_file) { "#{coverage_dir}/Products/#{configuration}-iphonesimulator/fixtures.app/fixtures" }

    before do
      allow(fixtures_project).to receive(:scheme).and_return("fixtures")
      allow(fixtures_project).to receive(:workspace).and_return("fixtures.xcworkspace")
      allow(fixtures_project).to receive(:binary_basename).and_return(["fixtures"])
      allow(fixtures_project).to receive(:profdata_coverage_dir).and_return(coverage_dir)
      allow(Dir).to receive(:[]).with(search_dir).and_return([binary_file])
    end

    context 'load configuration from xcsheme' do
      it "search binary from 'Products/Debug*'" do
        expect(fixtures_project.find_binary_files).to eq([binary_file])
      end
    end

    context 'load configuration from option' do
      let(:configuration) { 'Release' }
      it "search binary from 'Products/Release*'" do
        fixtures_project.configuration = configuration
        expect(fixtures_project.find_binary_files).to eq([binary_file])
      end
    end
  end
end
