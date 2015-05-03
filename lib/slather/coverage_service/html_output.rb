require 'nokogiri'

module Slather
  module CoverageService
    module HtmlOutput

      def coverage_file_class
        Slather::CoverageFile
      end
      private :coverage_file_class

      def html_directory
        "html"
      end
      private :html_directory

      def post
        create_html_reports(coverage_files)
        generate_reports(@docs)
      end

      def create_html_reports(coverage_files)
        create_index_html(coverage_files)
        create_htmls_from_files(coverage_files)
      end

      def generate_reports(reports)
        directory_path = html_directory
        if output_directory
          directory_path = File.join(output_directory, html_directory)
        end

        FileUtils.rm_rf(directory_path) if File.exists?(directory_path)
        FileUtils.mkdir_p(directory_path)

        reports.each do |name, doc|
          html_file = File.join(directory_path, "#{name}.html")
          File.write(html_file, doc.to_html)
        end

        index_html = File.join(directory_path, "index.html")
        puts "HTML files are generated, index at #{index_html}"

        # Alternatively we could open 'index.html' automatically, although I don't know how to disable it for testing
        # unless ENV["CI"]
        #   index_html = File.join(directory_path, "index.html")
        #   `open #{index_html}` if File.exists?(index_html)
        # end
      end

      def create_index_html(coverage_files)
        project_name = File.basename(self.xcodeproj)
        template = generate_html_template(project_name)

        total_relevant_lines = 0
        total_tested_lines = 0
        coverage_files.each { |coverage_file|
          total_tested_lines += coverage_file.num_lines_tested
          total_relevant_lines += coverage_file.num_lines_testable
        }

        builder = Nokogiri::HTML::Builder.with(template.at('#coverage')) { |cov|
          cov.h2 "Files for \"#{project_name}\""

          cov.h4 {
            percentage = (total_tested_lines / total_relevant_lines.to_f) * 100.0
            cov.span "Total Coverage : "
            cov.span '%.2f%%' % percentage, :class => class_for_coverage_percentage(percentage), :id => "total_coverage"
          }

          cov.table(:class => "table", :cellspacing => 0,  :cellpadding => 0) {

            cov.thead {
              cov.tr {
                cov.th "%", :class => "col_num"
                cov.th "File"
                cov.th "Lines", :class => "col_percent"
                cov.th "Relevant", :class => "col_percent"
                cov.th "Covered", :class => "col_percent"
                cov.th "Missed", :class => "col_percent"
              }
            }

            cov.tbody {
              coverage_files.each { |coverage_file|
                filename = File.basename(coverage_file.source_file_pathname_relative_to_repo_root)
                filename_link = "#{filename}.html"

                cov.tr {
                  percentage = coverage_file.percentage_lines_tested
                  cov.td { cov.span '%.2f' % percentage, :class => "percentage #{class_for_coverage_percentage(percentage)}" }
                  cov.td { cov.a filename, :href => filename_link }
                  cov.td "#{coverage_file.line_coverage_data.count}"
                  cov.td "#{coverage_file.num_lines_testable}"
                  cov.td "#{coverage_file.num_lines_tested}"
                  cov.td "#{(coverage_file.num_lines_testable - coverage_file.num_lines_tested)}"
                }
              }
            }
          }
        }

        @docs = Hash.new
        @docs[:index] = builder.doc
      end

      def create_htmls_from_files(coverage_files)
        coverage_files.map { |file| create_html_from_file file }
      end

      def create_html_from_file(coverage_file)
        filepath = coverage_file.source_file_pathname_relative_to_repo_root
        filename = File.basename(filepath)
        template = generate_html_template(filename)
        percentage = coverage_file.percentage_lines_tested
        cleaned_gcov_lines = coverage_file.cleaned_gcov_data.split("\n")
        is_file_empty = (cleaned_gcov_lines.count <= 0)

        builder = Nokogiri::HTML::Builder.with(template.at('#coverage')) { |cov|
          cov.h2(:class => "cov_title") {
            cov.span("Coverage for \"#{filename}\"" + (!is_file_empty ? " : " : ""))
            cov.span("#{'%.2f' % percentage}%", :class => class_for_coverage_percentage(percentage)) unless is_file_empty
          }

          cov.h4("(#{coverage_file.num_lines_tested} of #{coverage_file.num_lines_testable} relevant lines covered)", :class => "cov_subtitle")
          cov.h4(filepath, :class => "cov_filepath")

          if is_file_empty
            cov.p "¯\\_(ツ)_/¯"
            next
          end

          cov.table(:class => "source_code") {
            cleaned_gcov_lines.each do |line|
              data = line.split(':', 3)

              line_number = data[1].to_i
              next unless line_number > 0

              coverage_data = data[0].strip
              line_data = [line_number, data[2], hits_for_coverage_data(coverage_data)]
              classes = ["num", "src", "coverage"]

              cov.tr(:class => class_for_coverage_data(coverage_data)) {
                line_data.each_with_index { |line, idx|
                  if idx != 1 then cov.td(line, :class => classes[idx])
                  else cov.td(:class => classes[idx]) { cov.pre line }
                  end
                }
              }
            end
          }
        }

        @docs[filename] = builder.doc
      end

      def generate_html_template(title)
        logo_path = File.join(gem_root_path, "docs/logo.jpg")
        css_path = File.join(gem_root_path, "css/slather.css")

        builder = Nokogiri::HTML::Builder.new do |doc|
          doc.html {
            doc.head {
              doc.title "#{title} - Slather"
              doc.link :href => css_path, :media => "all", :rel => "stylesheet"
            }
            doc.body {
              doc.header {
                doc.div(:class => "row") {
                  doc.a(:href => "index.html") { doc.img(:src => logo_path, :alt => "Slather logo") }
                }
              }
              doc.div(:class => "row") { doc.div(:id => "coverage") }
              doc.footer {
                doc.div(:class => "row") {
                  doc.p { doc.a("Fork me on Github", :href => "https://github.com/venmo/slather") }
                  doc.p("© #{Date.today.year} Slather")
                }
              }
            }
          }
        end
        builder.doc
      end

      def gem_root_path
        File.expand_path File.join(File.dirname(__dir__), "../..")
      end

      def class_for_coverage_data(coverage_data)
        case coverage_data
        when /\d/ then "covered"
        when /#/ then "missed"
        else "never"
        end
      end

      def hits_for_coverage_data(coverage_data)
        case coverage_data
        when /\d/ then (coverage_data.to_i > 0) ? "#{coverage_data}x" : ""
        when /#/ then "!"
        else ""
        end
      end

      def class_for_coverage_percentage(percentage)
        case
        when percentage > 85 then "cov_high"
        when percentage > 70 then "cov_medium"
        else "cov_low"
        end
      end

    end
  end
end
