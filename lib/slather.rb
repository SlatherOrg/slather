require_relative 'slather/version'
require_relative 'slather/project'
require_relative 'slather/coverage_info'
require_relative 'slather/coverage_file'
require_relative 'slather/coveralls_coverage'
require_relative 'slather/profdata_coverage_file'
require_relative 'slather/coverage_service/cobertura_xml_output'
require_relative 'slather/coverage_service/coveralls'
require_relative 'slather/coverage_service/hardcover'
require_relative 'slather/coverage_service/gutter_json_output'
require_relative 'slather/coverage_service/simple_output'
require_relative 'slather/coverage_service/html_output'

module Slather

  Encoding.default_external = "utf-8"

  def self.prepare_pods(pods)
    Pod::UI.warn("[Slather] prepare_pods is now deprecated. The call to prepare_pods in your Podfile can simply be ommitted.")
  end

  def self.xcode_version
    xcode_path = `xcode-select -p`.strip
    xcode_version = `mdls -name kMDItemVersion -raw #{xcode_path.shellescape}/../..`.strip
    xcode_version.split('.').map(&:to_i)
  end

end
