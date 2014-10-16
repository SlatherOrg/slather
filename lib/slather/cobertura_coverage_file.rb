module Slather
  class CoberturaCoverageFile < CoverageFile

    def gcov_data
      @gcov_data ||= begin
        gcov_output = `gcov "#{source_file_pathname}" --object-directory "#{gcno_file_pathname.parent}" --branch-probabilities --branch-counts`
        # Sometimes gcov makes gcov files for Cocoa Touch classes, like NSRange. Ignore and delete later.
        gcov_files_created = gcov_output.scan(/creating '(.+\..+\.gcov)'/)

        gcov_file_name = "./#{source_file_pathname.basename}.gcov"
        if File.exists?(gcov_file_name)
          gcov_data = File.new(gcov_file_name).read
        end

        gcov_files_created.each { |file| FileUtils.rm_f(file) }
        gcov_data = cleaned_gcov_data(gcov_data)
      end
    end

    def branch_coverage_data
      @branch_coverage_data ||= begin
        branch_coverage_data = Hash.new
        branch_hits = Array.new
        line_number = nil

        @gcov_data.split("\n").each do |line|
          line_segments = line.split(':')
          if line_segments.length == 0 || line_segments[0].strip == '-'
            next
          end
          if line.match(/^branch/)
            if line.split(' ')[2].strip == "never"
              branch_hits.push(0)
            else
              taken = line.split(' ')[3].strip.to_i
              branch_hits.push(taken)
            end
          else
            if !branch_hits.empty?
              branch_coverage_data[line_number] = branch_hits.dup
              branch_hits.clear
            end
            line_number = line_segments[1].strip
          end
        end
        branch_coverage_data
      end
    end

    def cleaned_gcov_data(data)
      data.gsub(/^function(.*) called [0-9]+ returned [0-9]+% blocks executed(.*)$/, '')
    end

    def coverage_for_line(line)
      line =~ /^(.+?):/

      if $1 == nil
        return nil
      end

      match = $1.strip
      case match
      when /[0-9]+/
        match.to_i
      when /#+/
        0
      when "-"
        nil
      end
    end

    def branch_coverage_data_for_statement_on_line(line_number)
      branch_coverage_data[line_number]
    end

    def num_branches_for_statement_on_line(line_number)
      branch_coverage_data_for_statement_on_line(line_number).length
    end

    def num_branch_hits_for_statement_on_line(line_number)
      branch_hits = 0
      branch_coverage_data_for_statement_on_line(line_number).each do |hit_count|
        if hit_count > 0
          branch_hits += 1
        end
      end
      branch_hits
    end

    def rate_branch_coverage_for_statement_on_line(line_number)
      branch_data = branch_coverage_data_for_statement_on_line(line_number)
      (num_branch_hits_for_statement_on_line(line_number) / branch_data.length.to_f)
    end

    def percentage_branch_coverage_for_statement_on_line(line_number)
      rate_branch_coverage_for_statement_on_line(line_number) * 100.to_i
    end

    def num_branches_testable
      branches_testable = 0
      branch_coverage_data.keys.each do |line_number|
        branches_testable += num_branches_for_statement_on_line(line_number)
      end
      branches_testable
    end

    def num_branches_tested
      branches_tested = 0
      branch_coverage_data.keys.each do |line_number|
        branches_tested += num_branch_hits_for_statement_on_line(line_number)
      end
      branches_tested
    end

    def rate_branches_tested
      if (branch_coverage_data.keys.length == 0)
        0.0
      else
        (num_branches_tested / num_branches_testable.to_f)
      end
    end

    def rate_lines_tested
      (num_lines_tested / num_lines_testable.to_f)
    end

    def source_file_basename
      File.basename(source_file_pathname, '.m')
    end
    
  end
end