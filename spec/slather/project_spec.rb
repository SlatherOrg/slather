require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::Project do

  let(:fixtures_project) { Slather::Project.open(FIXTURES_PROJECT_PATH) }

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

  describe "::yml_file" do
    after(:each) { Slather::Project.instance_variable_set("@yml_file", nil) }

    context ".slather.yml file exists" do
      before(:all) { File.open(".slather.yml", "w") { |f| f.write("two: 2") } }
      after(:all) { puts File.delete(".slather.yml") }

      it "should load and return .slather.yml, if it exists" do
        expect(Slather::Project.yml_file).to eq({"two" => 2})
      end
    end

    context ".slather.yml file doesn't exist" do
      it "should return nil" do
        expect(Slather::Project.yml_file).to be_nil
      end
    end
  end
end