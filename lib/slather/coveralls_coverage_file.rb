module Slather
  class CoverallsCoverageFile < CoverageFile

    def coverage_data
      first_line_start = gcov_data =~ /^\s+(-|#+|[0-9+]):\s+1:/

      gcov_data[first_line_start..-1].split("\n").map do |line|
        coverage_for_line(line)
      end
    end

    def as_json
      {
        :name => source_file_pathname_relative_to_project_root.to_s,
        :source => source_data,
        :coverage => coverage_data
      }
    end

  end
end