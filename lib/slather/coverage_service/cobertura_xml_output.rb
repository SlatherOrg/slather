require 'nokogiri'

module Slather
  module CoverageService
    module CoberturaXmlOutput

      def coverage_file_class
        Slather::CoberturaCoverageFile
      end
      private :coverage_file_class

      def post
        output = { 'meta' => { 'timestamp' => DateTime.now.strftime('%Y-%m-%d %H:%M:%S.%6N') } }

        @doc = Nokogiri::XML "<coverage></coverage>"
        @doc.to_xml
        
        coverage = @doc.at_css "coverage"
        coverage['line-rate'] = '20.0'
        coverage['branch-rate'] = "0.0" 
        coverage['version'] = "1.9"
        coverage['timestamp'] = "1187353747005"

        sources  = Nokogiri::XML::Node.new "sources", @doc
        packages = Nokogiri::XML::Node.new "packages", @doc
        classes  = Nokogiri::XML::Node.new "classes", @doc
        methods  = Nokogiri::XML::Node.new "methods", @doc
        lines    = Nokogiri::XML::Node.new "lines", @doc

        sources.parent = coverage
        packages.parent = coverage
        classes.parent = coverage
        methods.parent = coverage
        lines.parent = coverage

        # <sources>
        #   <source>C:/local/mvn-coverage-example/src/main/java</source>
        # </sources>
        
        @doc.to_xml

        puts @doc.to_xml



        coverage_files.each do |coverage_file|
          next unless coverage_file.gcov_data

          filename = coverage_file.source_file_pathname.to_s
          filename = filename.sub(Pathname.pwd.to_s, '')[1..-1]

          coverage_file.gcov_data.split("\n").each do |line|
            

          end
        end

        File.open('cobertura.xml', 'w') { |file| file.write(output.to_s) }
      end

    end
  end
end
