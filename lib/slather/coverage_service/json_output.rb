require 'nokogiri'
require 'date'

module Slather
  module CoverageService
    module JsonOutput

      def coverage_file_class
        if input_format == "profdata"
          Slather::ProfdataCoverageFile
        else
          Slather::CoverageFile
        end
      end
      private :coverage_file_class

      def post
        report = coverage_files.map do |file|
          {
            file: file.source_file_pathname_relative_to_repo_root,
            coverage: file.line_coverage_data
          }
        end.to_json

        store_report(report)
      end

      def store_report(report)
        output_file = 'report.json'
        if output_directory
          FileUtils.mkdir_p(output_directory)
          output_file = File.join(output_directory, output_file)
        end
        File.write(output_file, report.to_s)
      end
    end
  end
end
