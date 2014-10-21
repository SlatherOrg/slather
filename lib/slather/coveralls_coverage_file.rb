module Slather
  class CoverallsCoverageFile < CoverageFile

    def as_json
      {
        :name => source_file_pathname_relative_to_repo_root.to_s,
        :source => source_data,
        :coverage => line_coverage_data
      }
    end

  end
end
