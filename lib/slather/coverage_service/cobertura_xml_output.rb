module Slather
  module CoverageService
    module CoberturaXmlOutput

      def coverage_file_class
        Slather::CoverageFile
      end
      private :coverage_file_class

      def post
        output = { 'meta' => { 'timestamp' => DateTime.now.strftime('%Y-%m-%d %H:%M:%S.%6N') } }
        symbols = {}

        coverage_files.each do |coverage_file|
          next unless coverage_file.gcov_data

          filename = coverage_file.source_file_pathname.to_s
          filename = filename.sub(Pathname.pwd.to_s, '')[1..-1]

          coverage_file.gcov_data.split("\n").each do |line|
            
            # assemble XML


          end
        end

        output['symbols_by_file'] = symbols
        File.open('cobertura.xml', 'w') { |file| file.write(output.to_s) }
      end

    end
  end
end
