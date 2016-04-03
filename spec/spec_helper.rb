if ENV['SIMPLECOV']
  require 'simplecov'
  SimpleCov.start
else
  require 'coveralls'
  Coveralls.wear!
end

require 'slather'
require 'pry'
require 'json_spec'
require 'equivalent-xml'


FIXTURES_XML_PATH = File.join(File.dirname(__FILE__), 'fixtures/cobertura.xml')
FIXTURES_JSON_PATH = File.join(File.dirname(__FILE__), 'fixtures/gutter.json')
FIXTURES_HTML_FOLDER_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures_html')
FIXTURES_PROJECT_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures.xcodeproj')
FIXTURES_WORKSPACE_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures.xcworkspace')
FIXTURES_SWIFT_FILE_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures/Fixtures.swift')
TEMP_DERIVED_DATA_PATH = File.join(File.dirname(__FILE__), 'DerivedData')
TEMP_PROJECT_BUILD_PATH = File.join(TEMP_DERIVED_DATA_PATH, "libfixtures")
TEMP_WORKSPACE_BUILD_PATH = File.join(TEMP_DERIVED_DATA_PATH, "libfixtures")
TEMP_OBJC_GCNO_PATH = File.join(File.dirname(__FILE__), 'fixtures/ObjectiveC.gcno')
TEMP_OBJC_GCDA_PATH = File.join(File.dirname(__FILE__), 'fixtures/ObjectiveC.gcda')

module FixtureHelpers
  def self.delete_derived_data
    dir = Dir[TEMP_DERIVED_DATA_PATH].first
    if dir
      FileUtils.rm_rf(dir)
    end
  end

  def self.delete_temp_gcov_files
    if File.file?(TEMP_OBJC_GCNO_PATH)
      FileUtils.rm(TEMP_OBJC_GCNO_PATH)
    end

    if File.file?(TEMP_OBJC_GCDA_PATH)
      FileUtils.rm_f(TEMP_OBJC_GCDA_PATH)
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    FixtureHelpers.delete_derived_data
    FixtureHelpers.delete_temp_gcov_files
    `xcodebuild -project "#{FIXTURES_PROJECT_PATH}" -scheme fixtures -configuration Debug -derivedDataPath #{TEMP_PROJECT_BUILD_PATH} -enableCodeCoverage YES clean test`
    `xcodebuild -workspace "#{FIXTURES_WORKSPACE_PATH}" -scheme fixtures -configuration Debug -derivedDataPath #{TEMP_WORKSPACE_BUILD_PATH} -enableCodeCoverage YES clean test`
  end

  config.after(:suite) do
    FixtureHelpers.delete_derived_data
    FixtureHelpers.delete_temp_gcov_files
  end
end

JsonSpec.configure do
  exclude_keys "timestamp"
end
