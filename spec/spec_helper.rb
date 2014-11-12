require 'bundler/setup'
Bundler.setup

require 'slather'
require 'pry'
require 'coveralls'
require 'json_spec'

Coveralls.wear!

FIXTURES_XML_PATH = File.join(File.dirname(__FILE__), 'fixtures/cobertura.xml')
FIXTURES_JSON_PATH = File.join(File.dirname(__FILE__), 'fixtures/gutter.json')
FIXTURES_PROJECT_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures.xcodeproj')

RSpec.configure do |config|
  config.after(:suite) do
    FileUtils.rm_rf(Dir[File.expand_path('~') + "/Library/Developer/Xcode/DerivedData/fixture*"].first)
  end
end

JsonSpec.configure do
  exclude_keys "timestamp"
end
