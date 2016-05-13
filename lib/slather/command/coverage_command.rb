class CoverageCommand < Clamp::Command

  parameter "[PROJECT]", "Path to the xcodeproj", :attribute_name => :xcodeproj_path

  option ["--travis", "-t"], :flag, "Indicate that the builds are running on Travis CI"
  option ["--circleci"], :flag, "Indicate that the builds are running on CircleCI"
  option ["--jenkins"], :flag, "Indicate that the builds are running on Jenkins"
  option ["--buildkite"], :flag, "Indicate that the builds are running on Buildkite"
  option ["--teamcity"], :flag, "Indicate that the builds are running on TeamCity"

  option ["--coveralls", "-c"], :flag, "Post coverage results to coveralls"
  option ["--simple-output", "-s"], :flag, "Output coverage results to the terminal"
  option ["--gutter-json", "-g"], :flag, "Output coverage results as Gutter JSON format"
  option ["--cobertura-xml", "-x"], :flag, "Output coverage results as Cobertura XML format"
  option ["--html"], :flag, "Output coverage results as static html pages"
  option ["--show"], :flag, "Indicate that the static html pages will open automatically"

  option ["--build-directory", "-b"], "BUILD_DIRECTORY", "The directory where gcno files will be written to. Defaults to derived data."
  option ["--source-directory"], "SOURCE_DIRECTORY", "The directory where your source files are located."
  option ["--output-directory"], "OUTPUT_DIRECTORY", "The directory where your Cobertura XML report will be written to."
  option ["--ignore", "-i"], "IGNORE", "ignore files conforming to a path", :multivalued => true
  option ["--verbose", "-v"], :flag, "Enable verbose mode"

  option ["--input-format"], "INPUT_FORMAT", "Input format (gcov, profdata)"
  option ["--scheme"], "SCHEME", "The scheme for which the coverage was generated"
  option ["--workspace"], "WORKSPACE", "The workspace that the project was built in"
  option ["--binary-file"], "BINARY_FILE", "The binary file against the which the coverage will be run", :multivalued => true
  option ["--binary-basename"], "BINARY_BASENAME", "Basename of the file against which the coverage will be run", :multivalued => true
  option ["--source-files"], "SOURCE_FILES", "A Dir.glob compatible pattern used to limit the lookup to specific source files. Ignored in gcov mode.", :multivalued => true
  option ["--decimals"], "DECIMALS", "The amount of decimals to use for % coverage reporting"

  def execute
    puts "Slathering..."

    setup_service_name
    setup_ignore_list
    setup_build_directory
    setup_source_directory
    setup_output_directory
    setup_coverage_service
    setup_verbose_mode
    setup_input_format
    setup_scheme
    setup_workspace
    setup_binary_file
    setup_binary_basename
    setup_source_files
    setup_decimals

    project.configure

    post

    puts "Slathered"
  end

  def setup_build_directory
    project.build_directory = build_directory if build_directory
  end

  def setup_source_directory
    project.source_directory = source_directory if source_directory
  end

  def setup_output_directory
    project.output_directory = output_directory if output_directory
  end

  def setup_ignore_list
    project.ignore_list = ignore_list if !ignore_list.empty?
  end

  def setup_service_name
    if travis?
      project.ci_service = :travis_ci
    elsif circleci?
      project.ci_service = :circleci
    elsif jenkins?
      project.ci_service = :jenkins
    elsif buildkite?
      project.ci_service = :buildkite
    elsif teamcity?
      project.ci_service = :teamcity
    end
  end

  def post
    project.post
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

  def setup_coverage_service
    if coveralls?
      project.coverage_service = :coveralls
    elsif simple_output?
      project.coverage_service = :terminal
    elsif gutter_json?
      project.coverage_service = :gutter_json
    elsif cobertura_xml?
      project.coverage_service = :cobertura_xml
    elsif html?
      project.coverage_service = :html
      project.show_html = show?
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

  def setup_source_files
    project.source_files = source_files_list if !source_files_list.empty?
  end

  def setup_decimals
    project.decimals = decimals if decimals
  end
end
