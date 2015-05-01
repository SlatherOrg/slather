require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'nokogiri'

describe Slather::CoverageService::HtmlOutput do

  let(:output_directorypath) { "html" }

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
        File.join(output_directorypath, "#{filename}.html")
      }.each { |filepath|
        expect(File.exists?(filepath)).to be_truthy
      }

      FileUtils.rm_rf output_directorypath if File.exists? output_directorypath
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

      fixtures_project.post

      fixture_doc = Nokogiri::HTML(open(File.join(FIXTURES_HTML_FOLDER_PATH, "index.html")))
      current_doc = Nokogiri::HTML(open(File.join(output_directorypath, "index.html")))

      fixture_title = fixture_doc.at_css('#coverage > h2').text
      current_title = current_doc.at_css('#coverage > h2').text
      expect(current_title).to eq(fixture_title)

      fixture_coverage = fixture_doc.at_css('#total_coverage')
      current_coverage = current_doc.at_css('#total_coverage')
      expect(current_coverage.text).to eq(fixture_coverage.text)
      expect(current_coverage["class"]).to eq(fixture_coverage["class"])

      fixture_data = extract_table(fixture_doc)
      current_data = extract_table(current_doc)
      expect(current_data).to eq(fixture_data)

      FileUtils.rm_rf output_directorypath if File.exists? output_directorypath
    end

    it "should create html coverage for each file with correct coverage" do

      fixtures_project.post

      filename = "Branches.m.html"

      fixture_doc = Nokogiri::HTML(open(File.join(FIXTURES_HTML_FOLDER_PATH, filename)))
      current_doc = Nokogiri::HTML(open(File.join(output_directorypath, filename)))

      fixture_title = fixture_doc.at_css('#coverage > h2 > span').text
      current_title = current_doc.at_css('#coverage > h2 > span').text
      expect(current_title).to eq(fixture_title)

      fixture_title = fixture_doc.at_css('#coverage > h4').text
      current_title = current_doc.at_css('#coverage > h4').text
      expect(current_title).to eq(fixture_title)

      # FileUtils.rm_rf output_directorypath if File.exists? output_directorypath
    end

    it "should create an HTML report directory in the given output directory" do
      fixtures_project.output_directory = "./output"
      fixtures_project.post

      directorypath = File.join(fixtures_project.output_directory, output_directorypath)
      expect(File.exists?(directorypath)).to be_truthy

      FileUtils.rm_rf(fixtures_project.output_directory)
    end

  end
end
