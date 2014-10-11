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
        total_project_branch_rates = 0

        create_empty_xml_report
        coverage_node = @doc.root
        source_node = @doc.at_css "source"
        package_node = @doc.at_css "package"
        classes_node = @doc.at_css "classes"
        coverage_node['timestamp'] = DateTime.now.strftime('%s')
        source_node.content = source_directory
        package_node['name'] = File.basename(path) # Project as package name?

        coverage_files.each do |coverage_file|
          next unless coverage_file.gcov_data
          class_node = create_class_node(coverage_file)
          class_node.parent = classes_node
          total_project_lines_rate += coverage_file.num_lines_tested
          total_project_lines += coverage_file.num_lines_testable
          total_project_branch_rates += class_node['branch-rate'].to_f
          coverage_file.branch_coverage_data
        end

        total_line_rate = '%.16f' % (total_project_lines_rate / total_project_lines.to_f)
        total_branch_rate = '%.16f' % (total_project_branch_rates / coverage_files.length.to_f)
        coverage_node['line-rate'] = total_line_rate
        coverage_node['branch-rate'] = total_branch_rate
        package_node['line-rate'] = total_line_rate
        package_node['branch-rate'] = total_branch_rate
        package_node['complexity'] = '---'
        return @doc.to_xml
      end

      def create_class_node(coverage_file)
        filename = coverage_file.source_file_basename
        filepath = coverage_file.source_file_pathname.to_s

        class_node = Nokogiri::XML::Node.new "class", @doc
        class_node['name'] = filename
        class_node['filename'] = filepath
        class_node['line-rate'] = '%.16f' % coverage_file.rate_lines_tested
        class_node['branch-rate'] = '1.0'

        methods_node = Nokogiri::XML::Node.new "methods", @doc
        methods_node.parent = class_node
        lines_node = Nokogiri::XML::Node.new "lines", @doc
        lines_node.parent = class_node
        
        branch_percentages = Array.new
        coverage_file.cleaned_gcov_data.split("\n").each do |line|
          line_segments = line.split(':')
          if coverage_file.coverage_for_line(line) != nil
            line_number = line_segments[1].strip
            line_node = create_line_node(line, coverage_file)
            line_node.parent = lines_node
          end
        end
        class_node['branch-rate'] = '%.16f' % [coverage_file.rate_branches_tested]

        # TODO: calculate complexity
        class_node['complexity'] = '---'
        return class_node
      end

      def create_line_node(line, coverage_file)
        line_number = line.split(':')[1].strip
        line_node = Nokogiri::XML::Node.new "line", @doc
        line_node['number'] = line_number
        line_node['branch'] = "false"
        line_node['hits'] = coverage_file.coverage_for_line(line)
      
        branch_data = coverage_file.branch_coverage_data_for_statement_on_line(line_number)
        if branch_data
          line_node['branch'] = "true"  
          conditions_node = Nokogiri::XML::Node.new "conditions", @doc
          conditions_node.parent = line_node
          condition_node = Nokogiri::XML::Node.new "condition", @doc
          condition_node.parent = conditions_node
          condition_node['number'] = "0"
          condition_node['type'] = "jump"
          branch_hits = coverage_file.branch_hits_for_statement_on_line(line_number)
          condition_coverage = coverage_file.branch_coverage_percentage_for_statement_on_line(line_number)
          condition_node['coverage'] = "#{condition_coverage}%"
          line_node['condition-coverage'] = "#{condition_coverage}% (#{branch_hits}/#{branch_data.length})"
        end
        return line_node
      end

      # TODO: update to DTD version 4.
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
        @doc = builder.doc
      end

    end
  end
end
