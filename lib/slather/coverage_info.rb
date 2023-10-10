module Slather
  module CoverageInfo

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

    def source_file_pathname_relative_to_repo_root
      test_path=source_file_pathname
      equivalence=ENV["COVERAGE_PATH_EQUIVALENCE"]
      if equivalence
        orig_prefix=equivalence.delete_suffix(",.")
        if "#{source_file_pathname}".start_with?(orig_prefix)
          test_path=Pathname("." + "#{source_file_pathname}".delete_prefix(orig_prefix))
        end
      end
      test_path.realpath.relative_path_from(Pathname("./").realpath)
    end

    def ignored?
      project.ignore_list.any? do |ignore|
        File.fnmatch(ignore, source_file_pathname_relative_to_repo_root)
      end
    end

  end
end