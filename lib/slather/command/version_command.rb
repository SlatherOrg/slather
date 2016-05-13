class VersionCommand < Clamp::Command

  def execute
    puts "slather #{Slather::VERSION}"
  end
end
