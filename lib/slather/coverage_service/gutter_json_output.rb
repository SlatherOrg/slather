module Slather
  module CoverageService
    module GutterJsonOutput

      def coverage_file_class
        if input_format == "profdata"
          Slather::ProfdataCoverageFile
        else
          Slather::CoverageFile
        end
      end
      private :coverage_file_class

      def post
        output = { 'meta' => { 'timestamp' => DateTime.now.strftime('%Y-%m-%d %H:%M:%S.%6N') } }
        symbols = {}

        coverage_files.each do |coverage_file|
          next unless coverage_file.raw_data

          filename = coverage_file.source_file_pathname.to_s
          filename = filename.sub(Pathname.pwd.to_s, '').reverse.chomp("/").reverse

          coverage_file.all_lines.each do |line|

            line_number = coverage_file.line_number_in_line(line)
            next unless line_number > 0

            coverage = coverage_file.coverage_for_line(line)
            short_text = coverage != nil ? coverage.to_s : "-"

            symbol = {  'line' => line_number,
                        'long_text' => '',
                        'short_text' => short_text }

            if coverage != nil
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
