module Slather
  module CoverageService
    module SimpleOutput

      def coverage_file_class
        if input_format == "profdata"
          Slather::ProfdataCoverageFile
        else
          Slather::CoverageFile
        end
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

        # check if there needs to be custom reporting based on the ci service
        if ci_service == :teamcity
          # TeamCity Build Statistic Reporting
          #
          # Reporting format ##teamcity[buildStatisticValue key='<valueTypeKey>' value='<value>']
          # key='CodeCoverageAbsLCovered' is total number of lines covered
          # key='CodeCoverageAbsLTotal' is total number of lines
          #
          # Sources:
          # - https://confluence.jetbrains.com/display/TCDL/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-ReportingBuildStatistics
          # - https://confluence.jetbrains.com/display/TCDL/Custom+Chart#CustomChart-listOfDefaultStatisticValues
          puts "##teamcity[buildStatisticValue key='CodeCoverageAbsLCovered' value='%i']" % total_project_lines_tested
          puts "##teamcity[buildStatisticValue key='CodeCoverageAbsLTotal' value='%i']" % total_project_lines
        end

        total_percentage = '%.2f' % [(total_project_lines_tested / total_project_lines.to_f) * 100.0]
        puts "Test Coverage: #{total_percentage}%"
      end

    end
  end
end
