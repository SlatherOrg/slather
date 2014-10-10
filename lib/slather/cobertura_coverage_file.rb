module Slather
  class CoberturaCoverageFile < CoverageFile

    def gcov_data
      @gcov_data ||= begin
        gcov_output = `gcov "#{source_file_pathname}" --object-directory "#{gcno_file_pathname.parent}" --branch-probabilities`
        # Sometimes gcov makes gcov files for Cocoa Touch classes, like NSRange. Ignore and delete later.
        gcov_files_created = gcov_output.scan(/creating '(.+\..+\.gcov)'/)

        gcov_file_name = "./#{source_file_pathname.basename}.gcov"
        if File.exists?(gcov_file_name)
          gcov_data = File.new(gcov_file_name).read
        end

        gcov_files_created.each { |file| FileUtils.rm_f(file) }

        gcov_data
      end
    end

    def coverage_for_line(line)
      line =~ /^(.+?):/

      # skip lines with annotations
      if line === nil || $1 === nil
        return nil
      end

      match = $1.strip
      case match
      when /[0-9]+/
        match.to_i
      when /#+/
        0
      when "-"
        nil
      end
    end

    def rate_lines_tested
      (num_lines_tested / num_lines_testable.to_f)
    end

    def source_file_basename
      return File.basename(source_file_pathname, '.m')
    end

    def cleaned_gcov_data
      cleaned_data = gcov_data.gsub(/^.*?:.*?:\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*\/(.)*\s/, '')
      return cleaned_data.gsub(/^function(.*) called [0-9]+ returned [0-9]+% blocks executed(.*)$/, '')
    end

    def create_class_node(xml_document)
      filename = source_file_basename
      filepath = source_file_pathname.to_s

      class_node = Nokogiri::XML::Node.new "class", xml_document
      class_node['name'] = filename
      class_node['filename'] = filepath
      class_node['line-rate'] = '%.16f' % rate_lines_tested
      class_node['branch-rate'] = '1.0'

      # create empty methods node
      methods_node = Nokogiri::XML::Node.new "methods", xml_document
      methods_node.parent = class_node

      # lines node will be filled
      lines_node = Nokogiri::XML::Node.new "lines", xml_document
      lines_node.parent = class_node
      
      branch_rates = 0
      branches_tested = 0

      line_node = nil
      branches = Array.new
      
      # remove lines that are commented out
      cleaned_gcov_data.split("\n").each do |line|

        # extract code after second colon
        line_of_code = line.sub(/.*?:.*?:/, '')
        
        # skip lines with meta data
        if line_of_code.match(/(^Source:)/) ||
          line_of_code.match(/(^Graph:)/) ||
          line_of_code.match(/(^Data:)/) ||
          line_of_code.match(/(^Runs:)/) ||
          line_of_code.match(/(^Programs:)/)
          next
        end

        # process lines
        line_segments = line.split(':')

        # skip all lines which are not relevant
        if line_segments.length === 0 || line_segments[0].strip === '-'
          next
        end

        # process lines with branch information
        if line_segments[0].match(/^branch(.*)/)
          line_node['branch'] = "true"
          branches.push(branch_coverage_for_line(line))
        else
          # process collected branch data from previous line
          if !branches.empty?
            conditions_node = Nokogiri::XML::Node.new "conditions", xml_document
            conditions_node.parent = line_node
            condition_node = Nokogiri::XML::Node.new "condition", xml_document
            condition_node.parent = conditions_node
            condition_node['number'] = "0"
            condition_node['type'] = "jump"

            condition_coverage = 0
            branch_hits = 0
            branches.each do |branch|
              condition_coverage += branch
              if branch > 0
                branch_hits += 1
              end
            end
            condition_coverage = (branches.inject(:+) / branches.length)
            condition_node['coverage'] = "#{condition_coverage}%"
            line_node['condition-coverage'] = "#{condition_coverage}% (#{branch_hits}/#{branches.length})"
            branches_tested += 1
            branch_rates += condition_coverage
            branches.clear
          end
          line_node = Nokogiri::XML::Node.new "line", xml_document
          line_node.parent = lines_node
          line_node['number'] = line_segments[1].strip
          hits = coverage_for_line(line)
          line_node['hits'] = hits
          line_node['branch'] = "false"
        end
      end
      if branches_tested > 0
        total_method_branch_rate = '%.16f' % [(branch_rates / branches_tested.to_f) / 100.0]
        class_node['branch-rate'] = total_method_branch_rate
      end
      # TODO: calculate complexity
      class_node['complexity'] = '---'
      return class_node
    end

    def branch_coverage_for_line(block)
      return block.split(' ')[3].strip.gsub(/%/, '').to_i
    end

  end
end
