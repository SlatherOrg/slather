require "bundler/gem_tasks"

desc "Generate the test fixtures"
task :generate_fixtures do
  sh "xcodebuild -project spec/fixtures/fixtures.xcodeproj/ -scheme fixtures -configuration Debug test"
end

desc "Run all the specs"
task :specs do
  sh "bundle exec rspec"
end

task :default => [:generate_fixtures, :specs]

