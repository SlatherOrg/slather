class FileCoverage
  attr_accessor :percentage, :lines

  def initialize(percentage, lines)
    self.percentage = percentage.to_f
    self.lines = lines.to_i
  end

  def lines_tested
    lines * (percentage / 100.0)
  end
end

require 'pathname'

SOURCE_DIR = "/Users/marklarsen/github.com/VENCalculatorInputView"
COVERAGE_DIR = "."


def compute_coverage
  coverage = coverage_files.map { |cf| compute_coverage_for_source_file(source_file_path_for_object(cf.to_s.gsub(".gcno", ""))) }
  total_lines = coverage.map(&:lines).inject(:+)
  total_lines_tested = coverage.map(&:lines_tested).inject(:+)
  test_coverage = (((total_lines_tested / total_lines) * 100) * 100).round / 100.0
  puts "TOTAL: #{test_coverage}"
end

def coverage_files
  Dir.glob("#{COVERAGE_DIR}/*.gcno").map { |path| Pathname(path) }
end

def compute_coverage_for_source_file(source_file_pathname)
  command = "xcrun gcov -object-directory=#{COVERAGE_DIR} #{source_file_pathname}"
  puts command
  str = `#{command}`
  puts str
  coverage = nil
  if str =~ /Lines executed:(\d+\.\d+)% of (\d+)/
    puts "#{$1}, #{$2}, #{source_file_pathname}"
    coverage = FileCoverage.new($1.to_f, $2.to_i)
  end
  coverage
end

def source_file_path_for_object(object_name)
  Dir.glob("#{SOURCE_DIR}/**/#{object_name}.m").map { |path| Pathname(path) }.first
end
