require 'nokogiri'
require 'date'

module Slather
  module CoverageService
    module LlvmCovOutput

      def coverage_file_class
        if input_format == "profdata"
          Slather::ProfdataCoverageFile
        else
          raise StandardError, "Only profdata input format supported by llvm-cov show."
        end
      end
      private :coverage_file_class

      def post
        report = coverage_files.map do |file|
          ["#{file.source_file_pathname.realpath}:", file.source_data, ""]
        end.flatten.join("\n")

        store_report(report)
      end

      def store_report(report)
        output_file = 'report.llcov'
        if output_directory
          FileUtils.mkdir_p(output_directory)
          output_file = File.join(output_directory, output_file)
        end
        File.write(output_file, report.to_s)
      end
    end
  end
end
