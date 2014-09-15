require 'slather/version'
require 'slather/project'
require 'slather/coverage_file'
require 'slather/coveralls_coverage_file'
require 'slather/coverage_service/coveralls'
require 'slather/coverage_service/hardcover'
require 'slather/coverage_service/simple_output'

module Slather

  Encoding.default_external = "utf-8"

  def self.prepare_pods(pods)
    pods.post_install do |installer|
      installer.project.slather_setup_for_coverage
    end
  end

end
