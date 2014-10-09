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

        doc = create_empty_xml_report
        coverage_node = doc.at_css "coverage"
        source_node = doc.at_css "source"
        package_node = doc.at_css "package"
        classes_node = doc.at_css "classes"
        coverage_node['timestamp'] = DateTime.now.strftime('%s')
        source_node.content = source_directory
        package_node['name'] = File.basename(path) # Project as package name?

        coverage_files.each do |coverage_file|
          next unless coverage_file.gcov_data
          class_node = coverage_file.create_class_node(doc)
          class_node.parent = classes_node
          total_project_lines_rate += coverage_file.num_lines_tested
          total_project_lines += coverage_file.num_lines_testable
        end

        total_line_rate = '%.2f' % (total_project_lines_rate / total_project_lines.to_f)
        coverage_node['line-rate'] = total_line_rate
        coverage_node['branch-rate'] = '1.0' # TODO: calculate branch coverage rate
        package_node['line-rate'] = total_line_rate
        package_node['branch-rate'] = '1.0' # TODO: calculate branch coverage rate
        package_node['complexity'] = '1.0' # TODO: calculate complexity
        return doc.to_xml
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
