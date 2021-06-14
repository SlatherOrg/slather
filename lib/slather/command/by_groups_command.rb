class ByGroupsCommand < Clamp::Command

  parameter "[PROJECT]", "Path to the xcodeproj", :attribute_name => :xcodeproj_path

  option ["--build-directory", "-b"], "BUILD_DIRECTORY", "The directory where gcno files will be written to. Defaults to derived data."
  option ["--source-directory"], "SOURCE_DIRECTORY", "The directory where your source files are located."
  option ["--verbose", "-v"], :flag, "Enable verbose mode"

  option ["--input-format"], "INPUT_FORMAT", "Input format (gcov, profdata)"
  option ["--scheme"], "SCHEME", "The scheme for which the coverage was generated"
  option ["--workspace"], "WORKSPACE", "The workspace that the project was built in"
  option ["--binary-file"], "BINARY_FILE", "The binary file against the which the coverage will be run", :multivalued => true
  option ["--binary-basename"], "BINARY_BASENAME", "Basename of the file against which the coverage will be run", :multivalued => true
  option ["--decimals"], "DECIMALS", "The amount of decimals to use for % coverage reporting"

  attr_accessor :coverage_files_hash

  def coverage_files_hash
    @coverage_files_hash ||= Hash[project.coverage_files.collect { |file| [file.source_file_pathname.to_s.downcase, file] }]
  end

  def execute
    puts "Slathering by groups..."

    setup_build_directory
    setup_source_directory
    setup_verbose_mode
    setup_input_format
    setup_scheme
    setup_workspace
    setup_binary_file
    setup_binary_basename
    setup_decimals

    project.configure

    output_coverage_by_groups

    puts "Slathered"
  end

  def setup_build_directory
    project.build_directory = build_directory if build_directory
  end

  def setup_source_directory
    project.source_directory = source_directory if source_directory
  end

  def project
    @project ||= begin
      xcodeproj_path_to_open = xcodeproj_path || Slather::Project.yml["xcodeproj"]
      if xcodeproj_path_to_open
        project = Slather::Project.open(xcodeproj_path_to_open)
      else
        raise StandardError, "Must provide an xcodeproj either via the 'slather [SUBCOMMAND] [PROJECT].xcodeproj' command or through .slather.yml"
      end
    end
  end

  def setup_verbose_mode
    project.verbose_mode = verbose?
  end

  def setup_input_format
    project.input_format = input_format
  end

  def setup_scheme
    project.scheme = scheme
  end

  def setup_workspace
    project.workspace = workspace
  end

  def setup_binary_file
    project.binary_file = binary_file_list if !binary_file_list.empty?
  end

  def setup_binary_basename
    project.binary_basename = binary_basename_list if !binary_basename_list.empty?
  end

  def setup_decimals
    project.decimals = decimals if decimals
  end

  def output_coverage_by_groups
    project.groups.each do |groups|
      post_all_groups(groups, "Root")
    end
  end

  def post_all_groups(group, name)
    post_group(group, name)
    group.groups.each do |child|
      post_all_groups(child, "#{name}/#{group.display_name}")
    end
  end

  def post_group(group, parent_name)
    puts "#{parent_name}/#{group.display_name} - #{coverage_from_group(group)}"
  end

  def coverage_from_group(group)
    files = all_files_from_group(group)

    total_project_lines = 0
    total_project_lines_tested = 0

    files_with_coverage = files.select do |file|
      file.real_path.to_s.end_with?(".m") || file.real_path.to_s.end_with?(".swift")
    end.map do |file|
      self.coverage_files_hash[file.real_path.to_s.downcase]
    end.compact

    files_with_coverage.each do |coverage_file|
      # ignore lines that don't count towards coverage (comments, whitespace, etc). These are nil in the array.
      lines_tested = coverage_file.num_lines_tested
      total_lines = coverage_file.num_lines_testable
      percentage = project.decimal_f([coverage_file.percentage_lines_tested])

      total_project_lines_tested += lines_tested
      total_project_lines += total_lines
    end

    total_percentage = "No testable file"
    if total_project_lines > 0
      total_percentage = project.decimal_f([(total_project_lines_tested / total_project_lines.to_f) * 100.0])
    end

    total_percentage
  end

  def all_files_from_group(group)
      child_files = group.groups.flat_map { |child|
        all_files_from_group(child)
      }
      group.files + child_files
  end

end
