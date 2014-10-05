module Slather
  class CoberturaCoverageFile < CoverageFile

    def lines_grouped_by_methods
      scanned_methods = Array.new
      current_method = nil
      scanning_for_method = false

      gcov_data.split("\n").each do |line|
        if line.match(/(Data:)/) || line.match(/(Runs:)/) || line.match(/(Programs:)/)
          next
        end

        # TODO: more elegant
        segments = line.split(':')
        if (segments[2] != nil)
          line_of_code = segments[2]
        else
          line_of_code = segments[1]
        end
        
        # scan for instance or class methods TODO: better algoritm
        if line_of_code[0] == '-' || line_of_code[0] == '+'
          current_method = Hash["name" => line_of_code, "lines_of_code" => Array.new]
          scanning_for_method = true
        end
        
        if scanning_for_method == true
          current_method["lines_of_code"].push(line)
        end

        # scan for closing bracket of a method
        if line_of_code[0] == '}'
          scanned_methods.push(current_method)
          scanning_for_method = false
        end
      end
      return scanned_methods
    end

    def rate_lines_tested
      (num_lines_tested / num_lines_testable.to_f)
    end

    def create_class_node(xml_document)
      filename = source_file_pathname.to_s
      filename = filename.sub(Pathname.pwd.to_s, '')[1..-1]

      classNode = Nokogiri::XML::Node.new "class", xml_document
      classNode['name'] = filename
      classNode['filename'] = filename
      classNode['line-rate'] = '%.2f' % [rate_lines_tested]
      classNode['branch-rate'] = '0.0'
      classNode['complexity'] = '1.0'

      methodsNode = Nokogiri::XML::Node.new "methods", xml_document
      methodsNode.parent = classNode
      methods = lines_grouped_by_methods
      methods.each do |method|
        methodNode = create_method_node(method, xml_document)
        methodNode.parent = methodsNode
      end
      return classNode
    end

    def create_method_node(method, xml_document)
      methodNode = Nokogiri::XML::Node.new "method", xml_document
      methodNode['name'] = method["name"]
      methodNode['branch-rate'] = 0.0
      methodNode['signature'] = "()V" # TODO: parse method signature

      linesNode = Nokogiri::XML::Node.new "lines", xml_document
      linesNode.parent = methodNode

      method_lines = 0
      method_lines_tested = 0
      method["lines_of_code"].each do |line|
        line_segments = line.split(':')

        # skip all lines which are not relevant
        if line_segments[0].strip === '-'
          next
        end

        lineNode = Nokogiri::XML::Node.new "line", xml_document
        lineNode.parent = linesNode
        lineNode['number'] = line_segments[1].strip
        hits = coverage_for_line(line)
        lineNode['hits'] = hits
        lineNode['branch'] = "false"

        method_lines += 1
        if hits > 0
          method_lines_tested += 1
        end
      end

      total_method_line_rate = '%.2f' % (method_lines_tested / method_lines.to_f)
      methodNode['line-rate'] = total_method_line_rate
      return methodNode
    end

  end
end
