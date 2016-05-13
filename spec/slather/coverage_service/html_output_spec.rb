require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'nokogiri'

describe Slather::CoverageService::HtmlOutput do

  OUTPUT_DIR_PATH = "html"

  let(:fixture_html_files) do
    ["index",
    "fixtures.m",
    "Branches.m",
    "fixturesTests.m",
    "peekaviewTests.m",
    "BranchesTests.m"].map { |file| "#{file}.html"}
  end

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.build_directory = TEMP_DERIVED_DATA_PATH
    proj.input_format = "profdata"
    proj.coverage_service = "html"
    proj
  end

  describe '#coverage_file_class' do
    it "should return CoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::ProfdataCoverageFile)
    end

    it "should allow accessing docs via attribute" do
      expect(fixtures_project.docs).to eq(nil)
    end
  end

  describe '#post' do
    before(:each) {
      allow(fixtures_project).to receive(:print_path_coverage)
      fixtures_project.send(:configure)
    }

    after(:each) {
      FileUtils.rm_rf(OUTPUT_DIR_PATH) if Dir.exist?(OUTPUT_DIR_PATH)
    }

    def extract_header_title(doc)
      doc.at_css('title').text
    end

    it "should create all coverage as static html files" do
      fixtures_project.post

      fixture_html_files.map { |filename|
        File.join(OUTPUT_DIR_PATH, filename)
      }.each { |filepath|
        expect(File.exist?(filepath)).to be_truthy
      }
    end

    it "should print out the path of the html folder by default" do
      fixtures_project.post

      expect(fixtures_project).to have_received(:print_path_coverage).with("html/index.html")
    end

    it "should open the index.html automatically if --show is flagged" do
      allow(fixtures_project).to receive(:open_coverage)

      fixtures_project.show_html = true
      fixtures_project.post

      expect(fixtures_project).to have_received(:open_coverage).with("html/index.html")
    end

    it "should create index html with correct coverage information" do
      def extract_title(doc)
        doc.at_css('#reports > h2').text
      end

      def extract_coverage_text(doc)
        doc.at_css('#total_coverage').text
      end

      def extract_coverage_class(doc)
        doc.at_css('#total_coverage').attribute("class").to_s
      end

      def extract_cov_header(doc)
        doc.css("table.coverage_list > thead > tr > th").map { |header|
          [header.text, header.attribute("data-sort")].join(", ")
        }.join("; ")
      end

      def extract_cov_index(doc)
        coverages = doc.css("table.coverage_list > tbody > tr").map { |tr|
          tr.css("td").map { |td|
            if td.attribute("class")
              td.attribute("class").to_s.split.join(", ") + ", #{td.text}"
            elsif span = td.at_css("span")
              span.attribute("class").to_s.split.join(", ")  + ", #{td.text}"
            else
              td.text
            end
          }.join("; ")
        }

        list = doc.css("table.coverage_list > tbody").attribute("class")
        coverages.append(list.to_s)
      end

      fixtures_project.post

      file = File.open(File.join(FIXTURES_HTML_FOLDER_PATH, "index.html"))
      fixture_doc = Nokogiri::HTML(file)
      file.close

      file = File.open(File.join(OUTPUT_DIR_PATH, "index.html"))
      current_doc = Nokogiri::HTML(file)
      file.close

      expect(extract_header_title(current_doc)).to eq(extract_header_title(fixture_doc))
      expect(extract_title(current_doc)).to eq(extract_title(fixture_doc))
      expect(extract_coverage_text(current_doc)).to eq(extract_coverage_text(fixture_doc))
      expect(extract_coverage_class(current_doc)).to eq(extract_coverage_class(fixture_doc))
      expect(extract_cov_header(current_doc)).to eq(extract_cov_header(fixture_doc))
      expect(extract_cov_index(current_doc)).to eq(extract_cov_index(fixture_doc))
    end

    it "should create html coverage for each file with correct coverage" do
      def extract_title(doc)
        doc.css('#coverage > h2 > span').map{ |x| x.text.strip }.join(", ")
      end

      def extract_subtitle(doc)
        (sub = doc.at_css('h4.cov_subtitle')) ? sub.text : ""
      end

      def extract_filepath(doc)
        (path = doc.at_css('h4.cov_filepath'))? path.text : ""
      end

      def extract_cov_data(doc)
        doc.css("table.source_code > tr").map { |tr|
          ([tr.attribute("class")] + tr.css('td').map(&:text)).join(",")
        }
      end

      fixtures_project.post

      fixture_html_files.each { |filename|
        file = File.open(File.join(FIXTURES_HTML_FOLDER_PATH, filename))
        fixture_doc = Nokogiri::HTML(file)
        file.close

        file = File.open(File.join(OUTPUT_DIR_PATH, filename))
        current_doc = Nokogiri::HTML(file)
        file.close

        expect(extract_title(fixture_doc)).to eq(extract_title(current_doc))
        expect(extract_subtitle(fixture_doc)).to eq(extract_subtitle(current_doc))
        expect(extract_filepath(fixture_doc)).to eq(extract_filepath(current_doc))
        expect(extract_cov_data(fixture_doc)).to eq(extract_cov_data(current_doc))
      }
    end

    it "should create an HTML report directory in the given output directory" do
      fixtures_project.output_directory = "./output"
      fixtures_project.post

      expect(Dir.exist?(fixtures_project.output_directory)).to be_truthy

      FileUtils.rm_rf(fixtures_project.output_directory) if Dir.exist?(fixtures_project.output_directory)
    end

    it "should create the default directory (html) if output directory is faulty" do
      fixtures_project.output_directory = "  "
      fixtures_project.post

      expect(Dir.exist?(OUTPUT_DIR_PATH)).to be_truthy
    end

    it "should create a valid report when using profdata format" do

      def extract_filepath(doc)
        (path = doc.at_css('h4.cov_filepath'))? path.text : ""
      end

      allow(fixtures_project).to receive(:input_format).and_return("profdata")
      allow(fixtures_project).to receive(:profdata_llvm_cov_output).and_return("./spec/fixtures/fixtures/other_fixtures.m:
     |    1|//
     |    2|//  other_fixtures.m
     |    3|//  fixtures
     |    4|//
     |    5|//  Created by Mark Larsen on 6/24/14.
     |    6|//  Copyright (c) 2014 marklarr. All rights reserved.
     |    7|//
     |    8|
     |    9|#import \"other_fixtures.h\"
     |   10|
     |   11|@implementation other_fixtures
     |   12|
     |   13|- (void)testedMethod
    1|   14|{
    1|   15|    NSLog(@\"tested\");
    1|   16|}
     |   17|
     |   18|- (void)untestedMethod
    0|   19|{
    0|   20|    NSLog(@\"untested\");
    0|   21|}
     |   22|
     |   23|@end
")
      fixtures_project.post

      file = File.open(File.join(OUTPUT_DIR_PATH, "other_fixtures.m.html"))
      doc = Nokogiri::HTML(file)
      file.close

      expect(extract_header_title(doc)).to eq("other_fixtures.m - Slather")
      expect(extract_filepath(doc)).to eq("spec/fixtures/fixtures/other_fixtures.m")
    end

  end
end
