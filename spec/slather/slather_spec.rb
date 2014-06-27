require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather do

  describe "::prepare_pods" do
    it "should setup the pods project for coverage" do
      pods_mock = double(Object)
      
      installer_mock = double(Object)
      project_mock = double(Xcodeproj::Project)
      installer_mock.stub(:project).and_return(project_mock)
      expect(project_mock).to receive(:slather_setup_for_coverage)

      expect(pods_mock).to receive(:post_install).and_yield(installer_mock)

      Slather.prepare_pods(pods_mock)
    end
  end
end