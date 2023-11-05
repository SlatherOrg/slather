class SetupCommand < Clamp::Command
  parameter "[PROJECT]", "Path to the .xcodeproj", :attribute_name => :xcodeproj_path

  option ["--format"], "FORMAT", "Type of coverage to use (gcov, clang, auto)"
  option ["--ymlfile"], "YMLFILE", "Relative path to a file used in place of '.slather.yml'"

  def execute
    setup_ymlfile
    xcodeproj_path_to_open = xcodeproj_path || Slather::Project.yml["xcodeproj"]
    unless xcodeproj_path_to_open
      raise StandardError, "Must provide a .xcodeproj either via the 'slather [SUBCOMMAND] [PROJECT].xcodeproj' command or through .slather.yml"
    end
    project = Slather::Project.open(xcodeproj_path_to_open)
    project.setup_for_coverage(format ? format.to_sym : :auto)
    project.save
  end

  def setup_ymlfile
    Slather::Project.yml_filename = ymlfile if ymlfile
  end
end
