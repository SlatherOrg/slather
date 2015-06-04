require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'nokogiri'

describe Slather::CoverageService::HtmlOutput do

  OUTPUT_DIR_PATH = "html"

  let(:fixture_html_files) do
    ["index",
    "fixtures.m",
    "peekaview.m",
    "fixtures_cpp.cpp",
    "fixtures_mm.mm",
    "fixtures_m.m",
    "Branches.m",
    "Empty.m",
    "fixturesTests.m",
    "peekaviewTests.m",
    "BranchesTests.m"].map { |file| "#{file}.html"}
  end

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::HtmlOutput)
  end

  describe '#coverage_file_class' do
    it "should return CoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverageFile)
    end
  end

  describe '#post' do
    before(:each) {
      fixtures_project.stub(:print_path_coverage)
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
      fixtures_project.stub(:open_coverage)

      fixtures_project.show_html = true
      fixtures_project.post

      expect(fixtures_project).to have_received(:open_coverage).with("html/index.html")
    end

    it "should create index html with correct coverage information" do
      def extract_title(doc)
        doc.at_css('#coverage > h2').text
      end

      def extract_coverage_text(doc)
        doc.at_css('#total_coverage').text
      end

      def extract_coverage_class(doc)
        doc.at_css('#total_coverage').attribute("class").to_s
      end

      def extract_cov_index(doc)
        doc.css("table.table > tbody > tr").map { |tr|
          tr.css("td").map { |td|
            td.text
            if span = td.at_css("span"); td.text + "-" + span.attribute("class") end
          }.join(", ")
        }
      end

      fixtures_project.post

      file = File.open(File.join(FIXTURES_HTML_FOLDER_PATH, "index.html"))
      fixture_doc = Nokogiri::HTML(file)
      file.close

      file = File.open(File.join(OUTPUT_DIR_PATH, "index.html"))
      current_doc = Nokogiri::HTML(file)
      file.close

      expect(extract_header_title(fixture_doc)).to eq(extract_header_title(current_doc))
      expect(extract_title(fixture_doc)).to eq(extract_title(current_doc))
      expect(extract_coverage_text(fixture_doc)).to eq(extract_coverage_text(current_doc))
      expect(extract_coverage_class(fixture_doc)).to eq(extract_coverage_class(current_doc))
      expect(extract_cov_index(fixture_doc)).to eq(extract_cov_index(current_doc))
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

  end
end
