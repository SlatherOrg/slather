require 'coveralls'
Coveralls.wear!

require 'slather'
require 'pry'
require 'json_spec'


FIXTURES_XML_PATH = File.join(File.dirname(__FILE__), 'fixtures/cobertura.xml')
FIXTURES_JSON_PATH = File.join(File.dirname(__FILE__), 'fixtures/gutter.json')
FIXTURES_PROJECT_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures.xcodeproj')

RSpec.configure do |config|
  config.before(:suite) do
    `xcodebuild -project #{FIXTURES_PROJECT_PATH} -scheme fixtures -configuration Debug test`
  end

  config.after(:suite) do
    FileUtils.rm_rf(Dir[File.expand_path('~') + "/Library/Developer/Xcode/DerivedData/fixture*"].first)
  end
end

JsonSpec.configure do
  exclude_keys "timestamp"
end
