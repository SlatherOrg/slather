require 'nokogiri'

module Slather
  module CoverageService
    module HtmlOutput

      def coverage_file_class
        if input_format == "profdata"
          Slather::ProfdataCoverageFile
        else
          Slather::CoverageFile
        end
      end
      private :coverage_file_class

      def directory_path
        is_path_valid = !output_directory.nil? && !output_directory.strip.eql?("")
        is_path_valid ? File.expand_path(output_directory) : "html"
      end
      private :directory_path

      def post
        create_html_reports(coverage_files)
        generate_reports(@docs)

        index_html_path = File.join(directory_path, "index.html")
        if show_html
          open_coverage index_html_path
        else
          print_path_coverage index_html_path
        end
      end

      def print_path_coverage(index_html)
        path = File.expand_path index_html
        puts "\nTo open the html reports, use \n\nopen '#{path}'\n\nor use '--show' flag to open it automatically.\n\n"
      end

      def open_coverage(index_html)
        path = File.expand_path index_html
        `open '#{path}'` if File.exist?(path)
      end

      def create_html_reports(coverage_files)
        create_index_html(coverage_files)
        create_htmls_from_files(coverage_files)
      end

      def generate_reports(reports)
        FileUtils.rm_rf(directory_path) if Dir.exist?(directory_path)
        FileUtils.mkdir_p(directory_path)

        FileUtils.cp(File.join(gem_root_path, "docs/hudl.jpg"), directory_path)
        FileUtils.cp(File.join(gem_root_path, "assets/slather.css"), directory_path)
        FileUtils.cp(File.join(gem_root_path, "assets/highlight.pack.js"), directory_path)
        FileUtils.cp(File.join(gem_root_path, "assets/list.min.js"), directory_path)

        reports.each do |name, doc|
          html_file = File.join(directory_path, "#{name}.html")
          File.write(html_file, doc.to_html)
        end
      end

      def create_index_html(coverage_files)
        project_name = File.basename(self.xcodeproj)
        template = generate_html_template(project_name, true, false)

        total_relevant_lines = 0
        total_tested_lines = 0
        coverage_files.each { |coverage_file|
          total_tested_lines += coverage_file.num_lines_tested
          total_relevant_lines += coverage_file.num_lines_testable
        }

        builder = Nokogiri::HTML::Builder.with(template.at('#reports')) { |cov|
          cov.h2 "Files for \"#{project_name}\""

          cov.h4 {
            percentage = (total_tested_lines / total_relevant_lines.to_f) * 100.0
            puts "Total Coverage : #{'%.2f%%' % percentage}"
            cov.span "Total Coverage : "
            cov.span '%.2f%%' % percentage, :class => class_for_coverage_percentage(percentage), :id => "total_coverage"
          }

          cov.input(:class => "search", :placeholder => "Search")

          cov.table(:class => "coverage_list", :cellspacing => 0,  :cellpadding => 0) {

            cov.thead {
              cov.tr {
                cov.th "%", :class => "col_num sort", "data-sort" => "data_percentage"
                cov.th "File", :class => "sort", "data-sort" => "data_filename"
                cov.th "Lines", :class => "col_percent sort", "data-sort" => "data_lines"
                cov.th "Relevant", :class => "col_percent sort", "data-sort" => "data_relevant"
                cov.th "Covered", :class => "col_percent sort", "data-sort" => "data_covered"
                cov.th "Missed", :class => "col_percent sort", "data-sort" => "data_missed"
              }
            }

            cov.tbody(:class => "list") {
              coverage_files.each { |coverage_file|
                filename = File.basename(coverage_file.source_file_pathname_relative_to_repo_root)
                filename_link = "#{filename}.html"

                cov.tr {
                  percentage = coverage_file.percentage_lines_tested

                  cov.td { cov.span '%.2f' % percentage, :class => "percentage #{class_for_coverage_percentage(percentage)} data_percentage" }
                  cov.td(:class => "data_filename") {
                    cov.a filename, :href => filename_link
                  }
                  cov.td "#{coverage_file.line_coverage_data.count}", :class => "data_lines"
                  cov.td "#{coverage_file.num_lines_testable}", :class => "data_relevant"
                  cov.td "#{coverage_file.num_lines_tested}", :class => "data_covered"
                  cov.td "#{(coverage_file.num_lines_testable - coverage_file.num_lines_tested)}", :class => "data_missed"
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
        percentage = coverage_file.percentage_lines_tested

        cleaned_gcov_lines = coverage_file.cleaned_gcov_data.split("\n")
        is_file_empty = (cleaned_gcov_lines.count <= 0)

        template = generate_html_template(filename, false, is_file_empty)

        builder = Nokogiri::HTML::Builder.with(template.at('#reports')) { |cov|
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

          line_number_separator = coverage_file.line_number_separator

          cov.table(:class => "source_code") {
            cleaned_gcov_lines.each do |line|
              data = line.split(line_number_separator, 3)

              line_number = data[1].to_i
              next unless line_number > 0

              coverage_data = data[0].strip
              line_data = [line_number, data[2], hits_for_coverage_data(coverage_data)]
              classes = ["num", "src", "coverage"]

              cov.tr(:class => class_for_coverage_data(coverage_data)) {
                line_data.each_with_index { |line, idx|
                  if idx != 1
                    cov.td(line, :class => classes[idx])
                  else
                    cov.td(:class => classes[idx]) {
                      cov.pre { cov.code(line, :class => "objc") }
                    }
                  end
                }
              }
            end
          }
        }

        @docs[filename] = builder.doc
      end

      def generate_html_template(title, is_index, is_file_empty)
        logo_path = "hudl.jpg"
        css_path = "slather.css"
        highlight_js_path = "highlight.pack.js"
        list_js_path = "list.min.js"

        builder = Nokogiri::HTML::Builder.new do |doc|
          doc.html {
            doc.head {
              doc.title "#{title} - Slather"
              doc.link :href => css_path, :media => "all", :rel => "stylesheet"
            }
            doc.body {
              doc.header {
                doc.div(:class => "row") {
                  doc.a(:href => "index.html") { doc.img(:src => logo_path, :alt => "Hudl logo") }
                }
              }
              doc.div(:class => "row") { doc.div(:id => "reports") }
              doc.footer {
                doc.div(:class => "row") {
                  doc.p("© #{Date.today.year} Slather")
                }
              }

              if is_index
                doc.script :src => list_js_path
                doc.script "var reports = new List('reports', { valueNames: [ 'data_percentage', 'data_filename', 'data_lines', 'data_relevant', 'data_covered', 'data_missed' ]});"
              else
                unless is_file_empty
                  doc.script :src => highlight_js_path
                  doc.script "hljs.initHighlightingOnLoad();"
                end
              end
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
