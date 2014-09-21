module Slather
  module CoverageService
    module GutterJsonOutput

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
            data = line.split(':')

            line_number = data[1].to_i
            next unless line_number > 0

            coverage = data[0].strip

            symbol = {  'line' => line_number,
                        'long_text' => '',
                        'short_text' => coverage }

            if coverage != '-'
              symbol['background_color'] = coverage.to_i > 0 ? '0x35CC4B' : '0xFC635E'
            end

            if symbols.has_key?(filename)
              symbols[filename] << symbol
            else
              symbols[filename] = [ symbol ]
            end
          end
        end

        output['symbols_by_file'] = symbols
        File.open('.gutter.json', 'w') { |file| file.write(output.to_json) }
      end

    end
  end
end
