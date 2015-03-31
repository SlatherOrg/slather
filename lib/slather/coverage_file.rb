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
          path = Dir["#{project.source_directory}/**/#{base_filename}.{m,mm,cpp,hpp}"].first
          path &&= Pathname(path)
        else
          pbx_file = project.files.detect { |pbx_file|
            t = Regexp.new(Regexp.escape(base_filename.to_s) + "\.(m|mm|cpp|hpp)$")
            !t.match(pbx_file.real_path.basename.to_s).nil?
          }
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
        else
          gcov_data = ""
        end

        gcov_files_created.each { |file| FileUtils.rm_f(file) }
        gcov_data
      end
    end

    def line_coverage_data
      unless cleaned_gcov_data.empty?
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
      if num_lines_testable > 0
        (num_lines_tested / num_lines_testable.to_f)
      else
        0
      end
    end

    def percentage_lines_tested
      if num_lines_testable == 0
        100
      else
        rate_lines_tested * 100
      end
    end

    def branch_coverage_data
      @branch_coverage_data ||= begin
        branch_coverage_data = Hash.new

          gcov_data.scan(/(^(\s+(-|#+|[0-9]+):\s+[1-9]+:(.*)$\r?\n)(^branch\s+[0-9]+\s+[a-zA-Z0-9]+\s+[a-zA-Z0-9]+$\r?\n)+)+/) do |data|
            lines = data[0].split("\n")
            line_number = lines[0].split(':')[1].strip.to_i
            branch_coverage_data[line_number] = lines[1..-1].map do |line|
              if line.split(' ')[2].strip == "never"
                0
              else
                line.split(' ')[3].strip.to_i
              end
            end
          end
        branch_coverage_data
      end
    end

    def branch_coverage_data_for_statement_on_line(line_number)
      branch_coverage_data[line_number] || []
    end

    def num_branches_for_statement_on_line(line_number)
      branch_coverage_data_for_statement_on_line(line_number).length
    end

    def num_branch_hits_for_statement_on_line(line_number)
      branch_coverage_data_for_statement_on_line(line_number).count { |hit_count| hit_count > 0 }
    end

    def rate_branch_coverage_for_statement_on_line(line_number)
      branch_data = branch_coverage_data_for_statement_on_line(line_number)
      if branch_data.empty?
        0.0
      else
        (num_branch_hits_for_statement_on_line(line_number) / branch_data.length.to_f)
      end
    end

    def percentage_branch_coverage_for_statement_on_line(line_number)
      rate_branch_coverage_for_statement_on_line(line_number) * 100
    end

    def num_branches_testable
      branch_coverage_data.keys.reduce(0) do |sum, line_number|
        sum += num_branches_for_statement_on_line(line_number)
      end
    end

    def num_branches_tested
      branch_coverage_data.keys.reduce(0) do |sum, line_number|
        sum += num_branch_hits_for_statement_on_line(line_number)
      end
    end

    def rate_branches_tested
      if (num_branches_testable > 0)
        (num_branches_tested / num_branches_testable.to_f)
      else
        0.0
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
