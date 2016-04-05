require 'slather/coverage_info'
require 'slather/coveralls_coverage'

module Slather
  class ProfdataCoverageFile

    include CoverageInfo
    include CoverallsCoverage

    attr_accessor :project, :source, :line_data

    def initialize(project, source)
      self.project = project
      self.source = source
      create_line_data
    end

    def create_line_data
      all_lines = self.source.split("\n")[1..-1]
      line_data = Hash.new
      all_lines.each { |line| line_data[line_number_in_line(line)] = line }
      self.line_data = line_data
    end
    private :create_line_data

    def source_file_pathname
      @source_file_pathname ||= begin
        path = self.source.split("\n")[0].sub ":", ""
        path &&= Pathname(path)
      end
    end

    def source_file
      File.new(source_file_pathname)
    end

    def source_data
      all_lines.join("\n")
    end

    def all_lines
      if @all_lines == nil
        @all_lines = self.source.split("\n")[1..-1]
      end
      @all_lines
    end

    def cleaned_gcov_data
      source_data
    end

    def raw_data
      self.source
    end

    def line_number_in_line(line)
      line =~ /^(\s*)(\d*)\|(\s*)(\d+)\|/
      if $4 != nil
        match = $4.strip
        case match
          when /[0-9]+/
            return match.to_i
        end
      end
      0
    end

    def line_coverage_data
      self.source.split("\n")[1..-1].map do |line|
        coverage_for_line(line)
      end
    end

    def coverage_for_line(line)
      line = line.gsub(":", "|")
      line =~ /^(\s*)(\d*)\|/

      if $2 == nil
        # Check for thousands or millions (llvm-cov outputs hit counts as 25.3k or 3.8M)
        did_match = line =~ /^(\s*)(\d+\.\d+)(k|M)\|/

        if did_match
          count = $2.strip
          units = $3 == 'k' ? 1000 : 1000000

          count.to_f * units
        else
          return nil
        end
      else
        match = $2.strip
        case match
        when /[0-9]+/
          match.to_i
        when /#+/
          0
        when "-"
          nil
        end
      end
    end

    def branch_coverage_data
      @branch_coverage_data ||= begin
        Hash.new
      end
    end

    def source_file_basename
      File.basename(source_file_pathname, '.swift')
    end

    def line_number_separator
      "|"
    end

    def supported_file_extensions
      ["swift"]
    end
    private :supported_file_extensions

    def ignored?
      ignore = false
      platform_ignore_list.map do |ignore_suffix|
        ignore = source_file_pathname.to_s.end_with? ignore_suffix
        if ignore
          break
        end
      end
      ignore ? ignore : super
    end

    def platform_ignore_list
      ["MacOSX.platform/Developer/Library/Frameworks/XCTest.framework/Headers/XCTestAssertionsImpl.h",
        "MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/usr/include/objc/objc.h",
        "MacOSX.platform/Developer/Library/Frameworks/XCTest.framework/Headers/XCTestAssertions.h"]
    end
    private :platform_ignore_list
  end
end
