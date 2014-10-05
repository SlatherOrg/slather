module Slather
  class CoberturaCoverageFile < CoverageFile

    def methods

      scanned_methods = Array.new
      current_method = nil
      scanning_for_method = false

      gcov_data.split("\n").each do |line|

        if line.match(/(Data:)/) || line.match(/(Runs:)/) || line.match(/(Programs:)/)
          next
        end

        segments = line.split(':')
        if (segments[2] != nil)
          line_of_code = segments[2].strip
        else
          line_of_code = segments[1].strip
        end
        
        # scan for instance or class methods
        if line_of_code[0] == '-' || line_of_code[0] == '+'
          current_method = Hash["method_name" => line_of_code, "lines_of_code" => Array.new]
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

  end
end
