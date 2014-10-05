require 'nokogiri'

module Slather
  module CoverageService
    module CoberturaXmlOutput

      def coverage_file_class
        Slather::CoberturaCoverageFile
      end
      private :coverage_file_class

      def post
        cobertura_xml_report = create_xml_report(coverage_files)
        File.open('cobertura.xml', 'w') { |file| file.write(cobertura_xml_report.to_s) }
      end

      def create_xml_report(coverage_files)
        total_project_lines = 0
        total_project_lines_rate = 0

        @doc = create_empty_xml_report
        coverageNode = @doc.at_css "coverage"
        sourceNode = @doc.at_css "source"
        packageNode = @doc.at_css "package"
        classesNode = @doc.at_css "classes"
        coverageNode['timestamp'] = DateTime.now.strftime('%s')
        sourceNode.content = "TODO"
        packageNode['name'] = "TODO"

        coverage_files.each do |coverage_file|
          next unless coverage_file.gcov_data
          classNode = coverage_file.create_class_node(@doc)
          classNode.parent = classesNode
          total_project_lines_rate += coverage_file.num_lines_tested
          total_project_lines += coverage_file.num_lines_testable
        end

        total_line_rate = '%.2f' % (total_project_lines_rate / total_project_lines.to_f)
        coverageNode['line-rate'] = total_line_rate
        coverageNode['branch-rate'] = '0.0'
        packageNode['line-rate'] = total_line_rate
        packageNode['branch-rate'] = '0.0'
        packageNode['complexity'] = '1.0'
        return @doc.to_xml
      end

      def create_empty_xml_report
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.doc.create_internal_subset(
            'coverage',
            nil,
            "http://cobertura.sourceforge.net/xml/coverage-03.dtd"
          )
          xml.coverage do
            xml.sources do
              xml.source
            end
            xml.packages do 
              xml.package do
                xml.classes
              end
            end
          end
        end
        return builder.doc
      end

    end
  end
end
