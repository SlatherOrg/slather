module Slather
  module CoverageService
    module SimpleOutput

      def coverage_file_class
        Slather::CoverageFile
      end
      private :coverage_file_class

      def post
        total_project_lines = 0
        total_project_lines_tested = 0
        coverage_files.each do |coverage_file|
          # ignore lines that don't count towards coverage (comments, whitespace, etc). These are nil in the array.

          lines_tested = coverage_file.num_lines_tested
          total_lines = coverage_file.num_lines_testable
          percentage = '%.2f' % [coverage_file.percentage_lines_tested]

          total_project_lines_tested += lines_tested
          total_project_lines += total_lines

          puts "#{coverage_file.source_file_pathname_relative_to_repo_root}: #{lines_tested} of #{total_lines} lines (#{percentage}%)"
        end
        total_percentage = '%.2f' % [(total_project_lines_tested / total_project_lines.to_f) * 100.0]
        puts "Test Coverage: #{total_percentage}%"
      end

    end
  end
end
