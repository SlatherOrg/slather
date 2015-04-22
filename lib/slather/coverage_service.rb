module Slather
  class CoverageService

    attr_reader :project

    def initialize(project)
      @project = project
    end

    def coverage_file_class
      Slather::CoverageFile
    end

    def post
      raise NotImplementedError
    end

  end
end
