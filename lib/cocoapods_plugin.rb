require 'slather'

Pod::HooksManager.register('slather', :post_install) do |installer_context|
  sandbox_root = installer_context.sandbox_root
  sandbox = Pod::Sandbox.new(sandbox_root)
  project = Xcodeproj::Project.open(sandbox.project_path)
  project.slather_setup_for_coverage()
  project.save()
end

