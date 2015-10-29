require 'coveralls'
Coveralls.wear!

require 'slather'
require 'pry'
require 'json_spec'
require 'equivalent-xml'


FIXTURES_XML_PATH = File.join(File.dirname(__FILE__), 'fixtures/cobertura.xml')
FIXTURES_JSON_PATH = File.join(File.dirname(__FILE__), 'fixtures/gutter.json')
FIXTURES_HTML_FOLDER_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures_html')
FIXTURES_PROJECT_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures.xcodeproj')
FIXTURES_SWIFT_FILE_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures/Fixtures.swift')

RSpec.configure do |config|
  config.before(:suite) do
    `xcodebuild -project "#{FIXTURES_PROJECT_PATH}" -scheme fixtures -configuration Debug test`
  end

  config.after(:suite) do
    dir = Dir[File.expand_path('~') + "/Library/Developer/Xcode/DerivedData/fixture*"].first
    if dir
      FileUtils.rm_rf(dir)
    end
  end
end

JsonSpec.configure do
  exclude_keys "timestamp"
end
