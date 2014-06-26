require 'bundler/setup'
Bundler.setup

require 'slather'
require 'pry'
require 'coveralls'

Coveralls.wear!

FIXTURES_PROJECT_PATH = File.join(File.dirname(__FILE__), 'fixtures/fixtures.xcodeproj')

RSpec.configure do |config|
end
