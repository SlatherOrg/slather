require 'nokogiri'
require "cgi"

module Slather
  module CoverageService
    module HtmlOutput

      attr_reader :docs

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

        FileUtils.cp(File.join(gem_root_path, "docs/logo.jpg"), directory_path)
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
        total_relevant_branches = 0
        total_branches_tested = 0
        coverage_files.each { |coverage_file|
          total_tested_lines += coverage_file.num_lines_tested
          total_relevant_lines += coverage_file.num_lines_testable

          total_relevant_branches += coverage_file.num_branches_testable
          total_branches_tested += coverage_file.num_branches_tested
        }

        builder = Nokogiri::HTML::Builder.with(template.at('#reports')) { |cov|
          cov.h2 "Files for \"#{project_name}\""

          cov.h4 {
            percentage = (total_tested_lines / total_relevant_lines.to_f) * 100.0
            cov.span "Total Coverage : "
            cov.span decimal_f(percentage) + '%', :class => class_for_coverage_percentage(percentage), :id => "total_coverage"
            cov.span " ("
            cov.span total_tested_lines, :id => "total_tested_lines"
            cov.span " of "
            cov.span total_relevant_lines, :id => "total_relevant_lines"
            cov.span " lines)"
          }

          cov.h4 {
            percentage = (total_branches_tested / total_relevant_branches.to_f) * 100.0
            cov.span "Total Branch Coverage : "
            cov.span decimal_f(percentage) + '%', :class => class_for_coverage_percentage(percentage), :id => "total_coverage"
            cov.span " ("
            cov.span total_branches_tested, :id => "total_branches_tested"
            cov.span " of "
            cov.span total_relevant_branches, :id => "total_relevant_branches"
            cov.span " lines)"
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
                filename_link = CGI.escape(filename) + ".html"

                cov.tr {
                  percentage = coverage_file.percentage_lines_tested

                  cov.td { cov.span decimal_f(percentage), :class => "percentage #{class_for_coverage_percentage(percentage)} data_percentage" }
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
        branch_percentage = coverage_file.rate_branches_tested * 100

        cleaned_gcov_lines = coverage_file.cleaned_gcov_data.split("\n")
        is_file_empty = (cleaned_gcov_lines.count <= 0)

        template = generate_html_template(filename, false, is_file_empty)

        builder = Nokogiri::HTML::Builder.with(template.at('#reports')) { |cov|
          cov.h2(:class => "cov_title") {
            cov.span("Coverage for \"#{filename}\"" + (!is_file_empty ? " : " : ""))
            cov.span("Lines: ") unless is_file_empty
            cov.span("#{decimal_f(percentage)}%", :class => class_for_coverage_percentage(percentage)) unless is_file_empty
            cov.span(" Branches: ") unless is_file_empty
            cov.span("#{decimal_f(branch_percentage)}%", :class => class_for_coverage_percentage(branch_percentage)) unless is_file_empty
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
              line_number = coverage_file.line_number_in_line(line)
              missed_regions = coverage_file.branch_region_data[line_number]
              hits = coverage_file.coverage_for_line(line)
              next unless line_number > 0

              line_source = line.split(line_number_separator, 3)[2]
              line_data = [line_number, line_source, hits_for_coverage_line(coverage_file, line)]
              classes = ["num", "src", "coverage"]

              cov.tr(:class => class_for_coverage_line(coverage_file,line)) {
                line_data.each_with_index { |line, idx|
                  if idx != 1
                    cov.td(line, :class => classes[idx])
                  else
                    cov.td(:class => classes[idx]) {
                      cov.pre {
                        # If the line has coverage and missed regions, split up
                        # the line to show regions that weren't covered
                        if missed_regions != nil && hits != nil && hits > 0
                          regions = missed_regions.map do |region|
                            region_start, region_length = region
                            if region_length != nil
                              line[region_start, region_length]
                            else
                              line[region_start, line.length - region_start]
                            end
                          end
                          current_line = line
                          regions.each do |region|
                            covered, remainder = current_line.split(region, 2)
                            cov.code(covered, :class => "objc")
                            cov.code(region, :class => "objc missed")
                            current_line = remainder
                          end
                          cov.code(current_line, :class => "objc")
                        else
                          cov.code(line, :class => "objc")
                        end
                      }
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
        logo_path = "logo.jpg"
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
                  doc.a(:href => "index.html") { doc.img(:src => logo_path, :alt => "Slather logo") }
                }
              }
              doc.div(:class => "row") { doc.div(:id => "reports") }
              doc.footer {
                doc.div(:class => "row") {
                  doc.p { doc.a("Fork me on Github", :href => "https://github.com/SlatherOrg/slather") }
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

      def class_for_coverage_line(coverage_file, coverage_line)
        hits = coverage_file.coverage_for_line(coverage_line)
        case
        when hits == nil then "never"
        when hits > 0 then "covered"
        else "missed"
        end
      end

      def hits_for_coverage_line(coverage_file, coverage_line)
        hits = coverage_file.coverage_for_line(coverage_line)
        case
        when hits == nil then ""
        when hits > 0 then "#{hits}x"
        else "!"
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
