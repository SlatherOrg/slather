require 'nokogiri'
require 'date'

module Slather
  module CoverageService
    module CoberturaXmlOutput

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
        output_file = 'cobertura.xml'
        if output_directory
          FileUtils.mkdir_p(output_directory)
          output_file = File.join(output_directory, output_file)
        end
        File.write(output_file, report.to_s)
      end

      def grouped_coverage_files(coverage_files)
        groups = Hash.new
        coverage_files.each do |coverage_file|
          next if coverage_file == nil
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
        total_project_line_rate = '%.16f' % 1.0
        total_project_branches = 0
        total_project_branches_tested = 0
        total_project_branch_rate = '%.16f' % 1.0

        create_empty_xml_report
        coverage_node = @doc.root
        source_node = @doc.at_css "source" 
        source_node.content = Pathname.pwd.to_s
        packages_node = @doc.at_css "packages"

        # group files by path
          grouped_coverage_files(coverage_files).each do |path , package_coverage_files|
          package_node = Nokogiri::XML::Node.new "package", @doc
          package_node.parent = packages_node
          classes_node = Nokogiri::XML::Node.new "classes", @doc
          classes_node.parent = package_node
          package_node['name'] = path.gsub(/\//, '.')

          total_package_lines = 0
          total_package_lines_tested = 0
          total_package_lines_rate = '%.16f' % 1.0
          total_package_branches = 0
          total_package_branches_tested = 0
          total_package_branch_rate = '%.16f' % 1.0

          package_coverage_files.each do |package_coverage_file|
            class_node = create_class_node(package_coverage_file)
            class_node.parent = classes_node
            total_package_lines += package_coverage_file.num_lines_testable
            total_package_lines_tested += package_coverage_file.num_lines_tested
            total_package_branches += package_coverage_file.num_branches_testable
            total_package_branches_tested += package_coverage_file.num_branches_tested
          end

          if (total_package_lines > 0)
            total_package_line_rate = '%.16f' % (total_package_lines_tested / total_package_lines.to_f)
          end

          if (total_package_branches > 0)
            total_package_branch_rate = '%.16f' % (total_package_branches_tested / total_package_branches.to_f)
          end

          package_node['line-rate'] = total_package_line_rate
          package_node['branch-rate'] = total_package_branch_rate
          package_node['complexity'] = '0.0'

          total_project_lines += total_package_lines
          total_project_lines_tested += total_package_lines_tested
          total_project_branches += total_package_branches
          total_project_branches_tested += total_package_branches_tested
        end

        if (total_project_lines > 0)
          total_project_line_rate = '%.16f' % (total_project_lines_tested / total_project_lines.to_f)
        end

        if (total_project_branches > 0)
          total_project_branch_rate = '%.16f' % (total_project_branches_tested / total_project_branches.to_f)
        end

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
        filepath = coverage_file.source_file_pathname_relative_to_repo_root.to_s

        class_node = Nokogiri::XML::Node.new "class", @doc
        class_node['name'] = filename
        class_node['filename'] = filepath
        class_node['line-rate'] = '%.16f' %  [(coverage_file.num_lines_testable > 0) ? coverage_file.rate_lines_tested : 1.0]
        class_node['branch-rate'] = '%.16f' % [(coverage_file.num_branches_testable > 0) ? coverage_file.rate_branches_tested : 1.0]
        class_node['complexity'] = '0.0'

        methods_node = Nokogiri::XML::Node.new "methods", @doc
        methods_node.parent = class_node
        lines_node = Nokogiri::XML::Node.new "lines", @doc
        lines_node.parent = class_node
        
        coverage_file.all_lines.each do |line|
          if coverage_file.coverage_for_line(line)
            line_node = create_line_node(line, coverage_file)
            line_node.parent = lines_node
          end
        end
        class_node
      end

      def create_line_node(line, coverage_file)
        line_number = coverage_file.line_number_in_line(line)
        line_node = Nokogiri::XML::Node.new "line", @doc
        line_node['number'] = line_number
        line_node['branch'] = "false"
        line_node['hits'] = coverage_file.coverage_for_line(line)
      
        unless coverage_file.branch_coverage_data_for_statement_on_line(line_number).empty?
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
