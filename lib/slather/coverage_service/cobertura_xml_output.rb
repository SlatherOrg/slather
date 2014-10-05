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
        puts cobertura_xml_report

        File.open('cobertura.xml', 'w') { |file| file.write(cobertura_xml_report.to_s) }
      end

      def create_xml_report(coverage_files)
        
        total_project_lines = 0
        total_project_lines_rate = 0

        @doc = create_empty_xml_report

        coverageNode = @doc.at_css "coverage"
        packageNode = @doc.at_css "package"
        
        coverage_files.each do |coverage_file|
          next unless coverage_file.gcov_data

          classNode = coverage_file.create_class_node(@doc)
          classNode.parent = packageNode

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
        @doc = Nokogiri::XML "<coverage version='1.9'></coverage>"
        coverageNode = @doc.root
        sourcesNode = Nokogiri::XML::Node.new "sources", @doc
        sourcesNode.parent = coverageNode
        packagesNode = Nokogiri::XML::Node.new "packages", @doc
        packagesNode.parent = coverageNode
        packageNode = Nokogiri::XML::Node.new "package", @doc
        packageNode.parent = packagesNode
        classesNode = Nokogiri::XML::Node.new "classes", @doc
        classesNode.parent = packageNode
        sourceNode  = Nokogiri::XML::Node.new "source", @doc
        sourceNode.parent = sourcesNode
        coverageNode['timestamp'] = DateTime.now.strftime('%s')
        sourceNode.content = "TODO" # add project path
        packageNode['name'] = "TODO" # add package name equivalent
        return @doc
      end

    end
  end
end


# builder = Nokogiri::XML::Builder.new do |xml|
#   xml.doc.create_internal_subset(
#     'html',
#     "-//W3C//DTD HTML 4.01 Transitional//EN",
#     "http://www.w3.org/TR/html4/loose.dtd"
#   )
#   xml.root do
#     xml.foo
#   end
# end

# puts builder.to_xml
