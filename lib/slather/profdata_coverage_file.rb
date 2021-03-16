require 'slather/coverage_info'
require 'slather/coveralls_coverage'
require 'digest/md5'

module Slather
  class ProfdataCoverageFile

    include CoverageInfo
    include CoverallsCoverage

    attr_accessor :project, :source, :segments, :line_numbers_first, :line_data

    def initialize(project, source, line_numbers_first)
      self.project = project
      self.source = source
      self.line_numbers_first = line_numbers_first
      create_line_data
    end

    def create_line_data
      line_data = Hash.new
      all_lines.each { |line| line_data[line_number_in_line(line, self.line_numbers_first)] = line }
      self.line_data = line_data
    end
    private :create_line_data

    def path_on_first_line?
      !source.lstrip.start_with?("1|")
    end

    def source_file_pathname
      @source_file_pathname ||= begin
        if path_on_first_line?
          end_index = self.source.index(/:?\n/)
          if end_index != nil
            end_index -= 1
            path = self.source[0..end_index]
          else
            # Empty file, output just contains path
            path = self.source.sub ":", ""
          end
          path &&= Pathname(path)
        else
          # llvm-cov was run with just one matching source file
          # It doesn't print the source path in this case, so we have to find it ourselves
          # This is slow because we read every source file and compare it, but this should only happen if there aren't many source files
          digest = Digest::MD5.digest(self.raw_source)
          path = nil

          project.find_source_files.each do |file|
            file_digest = Digest::MD5.digest(File.read(file).strip)

            if digest == file_digest
              path = file
            end
          end

          path
        end
      end
    end

    def source_file_pathname= (source_file_pathname)
        @source_file_pathname = source_file_pathname
    end

    def source_file
      File.new(source_file_pathname)
    end

    def source_code_lines
      lines = self.source.split("\n")[(path_on_first_line? ? 1 : 0)..-1]
      ignore_error_lines(lines)
    end

    def ignore_error_lines(lines, line_numbers_first = self.line_numbers_first)
      if line_numbers_first
        lines.reject { |line| line.lstrip.start_with?('|', '--') }
      else
        lines
      end
    end

    def source_data
      all_lines.join("\n")
    end

    def all_lines
      @all_lines ||= source_code_lines
    end

    def raw_source
      self.source.lines.map do |line|
        line.split('|').last
      end.join
    end

    def cleaned_gcov_data
      source_data
    end

    def raw_data
      self.source
    end

    def line_number_in_line(line, line_numbers_first = self.line_numbers_first)
      if line_numbers_first
        # Skip regex if the number is the first thing in the line
        fastpath_number = line.to_i
        return fastpath_number if fastpath_number != 0
        line =~ /^(\s*)(\d*)/
        group = $2
      else
        line =~ /^(\s*)(\d*)\|(\s*)(\d+)\|/
        group = $4
      end

      if group != nil
        match = group.strip
        case match
          when /[0-9]+/
            return match.to_i
        end
      else
        # llvm-cov outputs hit counts as 25.3k or 3.8M, so check this pattern as well
        did_match = line =~ /^(\s*)(\d+\.\d+)(k|M)\|(\s*)(\d+)\|/

        if did_match
          match = $5.strip
          case match
            when /[0-9]+/
              return match.to_i
          end
        end
      end
      0
    end

    def line_coverage_data
      all_lines.map do |line|
        coverage_for_line(line, self.line_numbers_first)
      end
    end

    def coverage_for_line(line, line_numbers_first = self.line_numbers_first)
      line = line.gsub(":", "|")

      if line_numbers_first
        line =~ /^(\s*)(\d*)\|(\s*)(\d+)\|/
        group = $4
      else
        line =~ /^(\s*)(\d*)\|/
        group = $2
      end

      if group == nil
        # Check for thousands or millions (llvm-cov outputs hit counts as 25.3k or 3.8M)
        if line_numbers_first
          did_match = line =~ /^(\s*)(\d+)\|(\s*)(\d+\.\d+)(k|M)\|/
          group = $4
          units_group = $5
        else
          did_match = line =~ /^(\s*)(\d+\.\d+)(k|M)\|/
          group = $2
          units_group = $3
        end

        if did_match
          count = group.strip
          units = units_group == 'k' ? 1000 : 1000000

          (count.to_f * units).to_i
        else
          return nil
        end
      else
        match = group.strip
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
        branch_coverage_data = Hash.new

        self.segments.each do |segment|
          line, col, hits, has_count, *rest = segment
          next if !has_count
          if branch_coverage_data.key?(line)
            branch_coverage_data[line] = branch_coverage_data[line] + [hits]
          else
            branch_coverage_data[line] = [hits]
          end
        end

        branch_coverage_data
      end
    end

    def branch_region_data
      @branch_region_data ||= begin
        branch_region_data = Hash.new
        region_start = nil
        current_line = 0
        @segments ||= []
        @segments.each do |segment|
          line, col, hits, has_count, *rest = segment
          # Make column 0 based index
          col = col - 1
          if hits == 0 && has_count
            current_line = line
            region_start = col
          elsif region_start != nil && hits > 0 && has_count
            # if the region wrapped to a new line before ending, put nil to indicate it didnt end on this line
            region_end = line == current_line ? col - region_start : nil
            if branch_region_data.key?(current_line)
              branch_region_data[current_line] << [region_start, region_end]
            else
              branch_region_data[current_line] = [[region_start, region_end]]
            end
            region_start = nil
          end
        end
        branch_region_data
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
      # This indicates a llvm-cov coverage warning (occurs if a passed in source file 
      # is not covered or with ccache in some cases).
      ignore = source_file_pathname.to_s.end_with? "isn't covered."

      if !ignore
        # Ignore source files inside of platform SDKs
        ignore = (/Xcode.*\.app\/Contents\/Developer\/Platforms/ =~ source_file_pathname.to_s) != nil
      end

      ignore ? ignore : super
    end
  end
end
