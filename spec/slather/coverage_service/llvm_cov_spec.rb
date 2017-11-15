require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Slather::CoverageService::LlvmCovOutput do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.build_directory = TEMP_DERIVED_DATA_PATH
    proj.binary_basename = ["fixturesTests", "libfixturesTwo"]
    proj.input_format = "profdata"
    proj.coverage_service = "llvm_cov"
    proj.configure
    proj
  end

  describe '#coverage_file_class' do
    it "should return ProfdataCoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::ProfdataCoverageFile)
    end
  end

  describe '#post' do
    it "should create an llvm-cov report spanning all coverage files" do
      fixtures_project.post

      output_llcov = File.read('report.llcov')
      fixture_llcov = File.read(FIXTURES_LLCOV_PATH)

      expect(output_llcov).to eq(fixture_llcov)
      FileUtils.rm('report.llcov')
    end

    it "should create an llvm-cov report in the given output directory" do
      fixtures_project.output_directory = "./output"
      fixtures_project.post

      filepath = "#{fixtures_project.output_directory}/report.llcov"
      expect(File.exists?(filepath)).to be_truthy

      FileUtils.rm_rf(fixtures_project.output_directory)
    end
  end
end
