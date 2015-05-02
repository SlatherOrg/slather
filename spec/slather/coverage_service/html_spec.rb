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
    "BranchesTests.m"].map { |filename|
      File.join(OUTPUT_DIR_PATH, "#{filename}.html")
    }
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
    it "should create all coverage as static html files" do
      fixtures_project.post

      fixture_html_files.each { |filepath| expect(File.exists?(filepath)).to be_truthy }

      FileUtils.rm_rf OUTPUT_DIR_PATH if File.exists? OUTPUT_DIR_PATH
    end

    it "should create index html with correct coverage information" do
      def extract_table(doc)
        doc.css("table.table > tbody > tr").map { |tr|
          tr.css("td").map { |td|
            if span = td.at_css("span")
              td.text + "-" + span["class"]
            else
              td.text
            end
          }.join(", ")
        }
      end

      def extract_title(doc)
        doc.at_css('#coverage > h2').text
      end

      def extract_coverage_text(doc)
        doc.at_css('#total_coverage').text
      end

      def extract_coverage_class(doc)
        doc.at_css('#total_coverage')['class']
      end

      fixtures_project.post

      fixture_doc = Nokogiri::HTML(open(File.join(FIXTURES_HTML_FOLDER_PATH, "index.html")))
      current_doc = Nokogiri::HTML(open(File.join(OUTPUT_DIR_PATH, "index.html")))

      expect(extract_title(fixture_doc)).to eq(extract_title(current_doc))
      expect(extract_coverage_text(fixture_doc)).to eq(extract_coverage_text(current_doc))
      expect(extract_coverage_class(fixture_doc)).to eq(extract_coverage_class(current_doc))
      expect(extract_table(fixture_doc)).to eq(extract_table(current_doc))

      FileUtils.rm_rf OUTPUT_DIR_PATH if File.exists? OUTPUT_DIR_PATH
    end

    it "should create html coverage for each file with correct coverage" do
      def extract_title(doc)
        doc.css('#coverage > h2 > span').map{ |x| x.text.strip }.join(", ")
      end

      def extract_subtitle(doc)
        if subtitle = doc.at_css('h4.cov_subtitle')
          subtitle.text
        else
          ""
        end
      end

      def extract_filepath(doc)
        if filepath = doc.at_css('h4.cov_filepath')
          filepath.text
        else
          ""
        end
      end

      fixtures_project.post

      filename = "Branches.m.html"

      fixture_doc = Nokogiri::HTML(open(File.join(FIXTURES_HTML_FOLDER_PATH, filename)))
      current_doc = Nokogiri::HTML(open(File.join(OUTPUT_DIR_PATH, filename)))

      expect(extract_title(fixture_doc)).to eq(extract_title(current_doc))
      expect(extract_subtitle(fixture_doc)).to eq(extract_subtitle(current_doc))
      expect(extract_filepath(fixture_doc)).to eq(extract_filepath(current_doc))

      # fixture_title = fixture_doc.at_css('#coverage > h4').text
      # current_title = current_doc.at_css('#coverage > h4').text
      # expect(current_title).to eq(fixture_title)

      # TODO: Comparing data inside the table
      # TODO: Instead of one file, traverse to all of them

      # FileUtils.rm_rf OUTPUT_DIR_PATH if File.exists? OUTPUT_DIR_PATH
    end

    it "should create an HTML report directory in the given output directory" do
      fixtures_project.output_directory = "./output"
      fixtures_project.post

      directorypath = File.join(fixtures_project.output_directory, OUTPUT_DIR_PATH)
      expect(File.exists?(directorypath)).to be_truthy

      FileUtils.rm_rf(fixtures_project.output_directory)
    end

  end
end
