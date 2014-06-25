module Slather
  class CoverageFile

    attr_accessor :project, :gcno_file_pathname

    def initialize(project, gcno_file_pathname)
      self.project = project
      self.gcno_file_pathname = Pathname(gcno_file_pathname)
    end

    def source_file_pathname
      @source_file_pathname ||= begin
        base_filename = gcno_file_pathname.basename.sub_ext("")
        # TODO: Handle Swift
        pbx_file = project.files.detect { |pbx_file| pbx_file.real_path.basename.to_s == "#{base_filename}.m" }        
        pbx_file && pbx_file.real_path
      end
    end

    def source_file
      File.new(source_file_pathname)
    end

    def source_data
      source_file.read
    end

    def source_file_pathname_relative_to_repo_root
      source_file_pathname.relative_path_from(Pathname("./").realpath)
    end

    def gcov_data
      @gcov_data ||= begin
        gcov_output = `gcov #{source_file_pathname} --object-directory #{gcno_file_pathname.parent}`
        # Sometimes gcov makes gcov files for Cocoa Touch classes, like NSRange. Ignore and delete later.
        gcov_files_created = gcov_output.scan(/creating '(.+\..+\.gcov)'/)

        gcov_file = File.new("./#{source_file_pathname.basename}.gcov")
        gcov_data = gcov_file.read

        gcov_files_created.each { |file| FileUtils.rm(file) }
        
        gcov_data
      end
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

    def ignored?
      project.ignore_list.any? do |ignore|
        File.fnmatch(ignore, source_file_pathname_relative_to_repo_root)
      end
    end

  end
end