require 'slather/coverage_info'
require 'slather/coveralls_coverage'

module Slather
  class CoverageFile

    include CoverageInfo
    include CoverallsCoverage

    attr_accessor :project, :gcno_file_pathname

    def initialize(project, gcno_file_pathname)
      self.project = project
      self.gcno_file_pathname = Pathname(gcno_file_pathname)
    end

    def source_file_pathname
      @source_file_pathname ||= begin
        base_filename = gcno_file_pathname.basename.sub_ext("")
        path = nil
        if project.source_directory
          path = Dir["#{project.source_directory}/**/#{base_filename}.{#{supported_file_extensions.join(",")}}"].first
          path &&= Pathname(path)
        else
          pbx_file = project.files.detect { |pbx_file|
            current_base_filename = pbx_file.real_path.basename
            ext_name = File.extname(current_base_filename.to_s)[1..-1]
            current_base_filename.sub_ext("") == base_filename && supported_file_extensions.include?(ext_name)
          }
          path = pbx_file && pbx_file.real_path
        end
        path
      end
    end

    def source_file
      File.new(source_file_pathname)
    end

    def source_data
      source_file.read
    end

    def gcov_data
      @gcov_data ||= begin
        gcov_data = ""

        Dir.chdir(project.project_dir) do
          gcov_output = `gcov "#{source_file_pathname}" --object-directory "#{gcno_file_pathname.parent}" --branch-probabilities --branch-counts`
          # Sometimes gcov makes gcov files for Cocoa Touch classes, like NSRange. Ignore and delete later.
          gcov_files_created = gcov_output.scan(/creating '(.+\..+\.gcov)'/)

          gcov_file_name = "./#{source_file_pathname.basename}.gcov"
          if File.exist?(gcov_file_name)
            gcov_data = File.new(gcov_file_name).read
          else
            gcov_data = ""
          end

          gcov_files_created.each { |file| FileUtils.rm_f(file) }
        end

        gcov_data
      end
    end

    def all_lines
      unless cleaned_gcov_data.empty?
        first_line_start = cleaned_gcov_data =~ /^\s+(-|#+|[0-9+]):\s+1:/
        cleaned_gcov_data[first_line_start..-1].split("\n").map
      else
        []
      end
    end

    def cleaned_gcov_data
      data = gcov_data.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').gsub(/^function(.*) called [0-9]+ returned [0-9]+% blocks executed(.*)$\r?\n/, '')
      data.gsub(/^branch(.*)$\r?\n/, '')
    end

    def raw_data
      self.gcov_data
    end

    def line_coverage_data
      unless cleaned_gcov_data.empty?
        first_line_start = cleaned_gcov_data =~ /^\s+(-|#+|[0-9+]):\s+1:/

        cleaned_gcov_data[first_line_start..-1].split("\n").map do |line|
          coverage_for_line(line)
        end
      else
        []
      end
    end

    def line_number_in_line(line)
      line.split(':')[1].strip.to_i
    end

    def coverage_for_line(line)
      line =~ /^(.+?):/

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

    def branch_coverage_data
      @branch_coverage_data ||= begin
        branch_coverage_data = Hash.new

        gcov_data.scan(/(^(\s+(-|#+|[0-9]+):\s+[1-9]+:(.*)$\r?\n)(^branch\s+[0-9]+\s+[a-zA-Z0-9]+\s+[a-zA-Z0-9]+$\r?\n)+)+/) do |data|
          lines = data[0].split("\n")
          line_number = lines[0].split(':')[1].strip.to_i
          branch_coverage_data[line_number] = lines[1..-1].map do |line|
            if line.split(' ')[2].strip == "never"
              0
            else
              line.split(' ')[3].strip.to_i
            end
          end
        end
        branch_coverage_data
      end
    end

    def source_file_basename
      File.basename(source_file_pathname, '.m')
    end

    def line_number_separator
      ":"
    end

    def supported_file_extensions
      ["cpp", "mm", "m"]
    end
    private :supported_file_extensions
  end
end
