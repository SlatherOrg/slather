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
        File.open('cobertura.xml', 'w') { |file|
          file.write(cobertura_xml_report.to_s)
        }
      end

      def grouped_coverage_files
        groups = Hash.new
        coverage_files.each do |coverage_file|
          path = File.dirname(coverage_file.source_file_pathname_relative_to_repo_root)
          if groups[path] == nil
            groups[path] = Array.new
          end
          groups[path].push(coverage_file)
        end
        groups
      end

      def create_xml_report(coverage_files)
        total_project_lines = 0
        total_project_lines_tested = 0
        total_project_line_rate = 0.0
        total_project_branches = 0
        total_project_branches_tested = 0

        create_empty_xml_report
        coverage_node = @doc.root
        source_node = @doc.at_css "source"
        source_node.content = source_directory
        packages_node = @doc.at_css "packages"

        # group files by path
        grouped_coverage_files.each do |path , package_coverage_files|
          package_node = Nokogiri::XML::Node.new "package", @doc
          package_node.parent = packages_node
          classes_node = Nokogiri::XML::Node.new "classes", @doc
          classes_node.parent = package_node
          package_node['name'] = path.gsub(/\//, '.')

          total_package_lines = 0
          total_package_lines_tested = 0
          total_package_lines_rate = 0.0
          total_package_branches = 0
          total_package_branches_tested = 0

          package_coverage_files.each do |package_coverage_file|
            next unless package_coverage_file.gcov_data
            class_node = create_class_node(package_coverage_file)
            class_node.parent = classes_node
            total_package_lines += package_coverage_file.num_lines_testable
            total_package_lines_tested += package_coverage_file.num_lines_tested
            total_package_branches += package_coverage_file.num_branches_testable
            total_package_branches_tested += package_coverage_file.num_branches_tested
          end

          total_package_line_rate = '%.16f' % (total_package_lines_tested / total_package_lines.to_f)
          total_package_branch_rate = '%.16f' % (total_package_branches_tested / total_package_branches.to_f)

          package_node['line-rate'] = total_package_line_rate
          package_node['branch-rate'] = total_package_branch_rate
          package_node['complexity'] = '0.0'

          total_project_lines += total_package_lines
          total_project_lines_tested += total_package_lines_tested
          total_project_branches += total_package_branches
          total_project_branches_tested += total_package_branches_tested

        end

        total_project_line_rate = '%.16f' % (total_project_lines_tested / total_project_lines.to_f)
        total_project_branch_rate = '%.16f' % (total_project_branches_tested / total_project_branches.to_f)

        coverage_node['line-rate'] = total_project_line_rate
        coverage_node['branch-rate'] = total_project_branch_rate
        coverage_node['lines-covered'] = total_project_lines_tested
        coverage_node['lines-valid'] = total_project_lines
        coverage_node['branches-covered'] = total_project_branches_tested
        coverage_node['branches-valid'] = total_project_branches
        coverage_node['complexity'] = "0.0"
        coverage_node['timestamp'] = DateTime.now.strftime('%s')
        coverage_node['version'] = "Slather #{Slather::VERSION}"
        @doc.to_xml
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
        coverage_file.gcov_data.split("\n").each do |line|
          line_segments = line.split(':')
          if coverage_file.coverage_for_line(line)
            line_number = line_segments[1].strip
            line_node = create_line_node(line, coverage_file)
            line_node.parent = lines_node
          end
        end
        class_node['branch-rate'] = '%.16f' % [coverage_file.rate_branches_tested]
        class_node['complexity'] = '0.0'
        class_node
      end

      def create_line_node(line, coverage_file)
        line_number = line.split(':')[1].strip
        line_node = Nokogiri::XML::Node.new "line", @doc
        line_node['number'] = line_number
        line_node['branch'] = "false"
        line_node['hits'] = coverage_file.coverage_for_line(line)
      
        if coverage_file.branch_coverage_data_for_statement_on_line(line_number)
          line_node['branch'] = "true"  
          conditions_node = Nokogiri::XML::Node.new "conditions", @doc
          conditions_node.parent = line_node
          condition_node = Nokogiri::XML::Node.new "condition", @doc
          condition_node.parent = conditions_node
          condition_node['number'] = "0"
          condition_node['type'] = "jump"
          branches_testable = coverage_file.num_branches_for_statement_on_line(line_number)
          branch_hits = coverage_file.num_branch_hits_for_statement_on_line(line_number)
          condition_coverage = coverage_file.percentage_branch_coverage_for_statement_on_line(line_number)
          condition_node['coverage'] = "#{condition_coverage.to_i}%"
          line_node['condition-coverage'] = "#{condition_coverage.to_i}% (#{branch_hits}/#{branches_testable})"
        end
        line_node
      end

      def create_empty_xml_report
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.doc.create_internal_subset(
            'coverage',
            nil,
            "http://cobertura.sourceforge.net/xml/coverage-04.dtd"
          )
          xml.coverage do
            xml.sources do
              xml.source
            end
            xml.packages
          end
        end
        @doc = builder.doc
      end

    end
  end
end
