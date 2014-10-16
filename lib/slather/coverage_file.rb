module Slather
  class CoverageFile

    attr_accessor :project, :gcno_file_pathname

    def initialize(project, gcno_file_pathname)
      self.project = project
      self.gcno_file_pathname = Pathname(gcno_file_pathname)
    end

    def source_file_pathname
      @source_file_pathname ||= begin
        base_filename = gcno_file_pathname.basename.sub_ext("")
        # TODO: Handle Swift
        path = nil
        if project.source_directory
          path = Dir["#{project.source_directory}/**/#{base_filename}.m"].first
          path &&= Pathname(path)
        else
          pbx_file = project.files.detect { |pbx_file| pbx_file.real_path.basename.to_s == "#{base_filename}.m" }
          path = pbx_file && pbx_file.real_path
        end
        path
      end
    end

    def source_file
      File.new(source_file_pathname)
    end

    def source_data
      source_file.read
    end

    def source_file_pathname_relative_to_repo_root
      source_file_pathname.realpath.relative_path_from(Pathname("./").realpath)
    end

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
        gcov_data
      end
    end

    def line_coverage_data
      if gcov_data
        first_line_start = cleaned_gcov_data =~ /^\s+(-|#+|[0-9+]):\s+1:/

        cleaned_gcov_data[first_line_start..-1].split("\n").map do |line|
          coverage_for_line(line)
        end
      else
        []
      end
    end

    def cleaned_gcov_data
      data = gcov_data.gsub(/^function(.*) called [0-9]+ returned [0-9]+% blocks executed(.*)$\r?\n/, '')
      data.gsub(/^branch(.*)$\r?\n/, '')
    end

    def coverage_for_line(line)
      line =~ /^(.+?):/

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

    def num_lines_tested
      line_coverage_data.compact.select { |cd| cd > 0 }.count
    end

    def num_lines_testable
      line_coverage_data.compact.count
    end

    def rate_lines_tested
      (num_lines_tested / num_lines_testable.to_f)
    end

    def percentage_lines_tested
      if num_lines_testable > 0 
        (num_lines_tested / num_lines_testable.to_f) * 100.0
      else
        0
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
          elsif line.match(/^function(.*) called [0-9]+ returned [0-9]+% blocks executed(.*)$/)
            next
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

    def source_file_basename
      File.basename(source_file_pathname, '.m')
    end

    def ignored?
      project.ignore_list.any? do |ignore|
        File.fnmatch(ignore, source_file_pathname_relative_to_repo_root)
      end
    end

  end
end
