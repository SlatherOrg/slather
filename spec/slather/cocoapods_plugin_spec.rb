require 'cocoapods'
require File.join(File.dirname(__FILE__), '..', 'spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/cocoapods_plugin')

describe Slather do
  describe 'CocoaPods Plugin' do
    it 'should setup slather for coverage in the Pods project' do
      mock_project = double(Xcodeproj::Project)
      allow(Xcodeproj::Project).to receive(:open).and_return(mock_project)
      expect(mock_project).to receive(:slather_setup_for_coverage)
      expect(mock_project).to receive(:save)

      # Execute the post_install hook via CocoaPods
      sandbox_root = 'Pods'
      sandbox = Pod::Sandbox.new(sandbox_root)
      context = Pod::Installer::PostInstallHooksContext.generate(sandbox, [])
      Pod::HooksManager.run(:post_install, context, {'slather' => nil})
    end
  end
end

