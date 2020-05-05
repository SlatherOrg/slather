require 'nokogiri'
require 'date'

module Slather
  module CoverageService
    module SonarqubeXmlOutput

      def coverage_file_class
        if input_format == "profdata"
          Slather::ProfdataCoverageFile
        else
          Slather::CoverageFile
        end
      end
      private :coverage_file_class

      def post
        cobertura_xml_report = create_xml_report(coverage_files)
        store_report(cobertura_xml_report)
      end

      def store_report(report)
        output_file = 'sonarqube-generic-coverage.xml'
        if output_directory
          FileUtils.mkdir_p(output_directory)
          output_file = File.join(output_directory, output_file)
        end
        File.write(output_file, report.to_s)
      end

      def create_xml_report(coverage_files)
        create_empty_xml_report
        coverage_node = @doc.root
        coverage_node['version'] = "1"

        coverage_files.each do |coverage_file|
          file_node = Nokogiri::XML::Node.new "file", @doc
          file_node.parent = coverage_node
          file_node['path'] = coverage_file.source_file_pathname_relative_to_repo_root.to_s
          coverage_file.all_lines.each do |line|
            if coverage_file.coverage_for_line(line)
              line_node = Nokogiri::XML::Node.new "lineToCover", @doc
              line_node['lineNumber'] = coverage_file.line_number_in_line(line)
              line_node['covered'] = coverage_file.coverage_for_line(line) == 0 ? "false" : "true"
              line_node.parent = file_node
            end
          end
        end
        @doc.to_xml
      end

      def create_empty_xml_report
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.coverage
        end
        @doc = builder.doc
      end

    end
  end
end
