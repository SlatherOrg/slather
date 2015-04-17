require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Slather::CoverageService::Hardcover do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::Hardcover)
  end

  describe "#coverage_file_class" do
    it "should return CoverallsCoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverallsCoverageFile)
    end
  end

  describe "#job_id" do
    it "should return the TRAVIS_JOB_ID environment variable" do
      ENV['TRAVIS_JOB_ID'] = "9182"
      expect(fixtures_project.send(:travis_job_id)).to eq("9182")
    end

    it "should return the Jenkins JOB_NAME and BUILD_NUMBER environment variables" do
      ENV['BUILD_NUMBER'] = "9182"
      ENV['JOB_NAME'] = "slather-master"
      expect(fixtures_project.send(:jenkins_job_id)).to eq("slather-master/9182")
    end
  end

  describe '#hardcover_coverage_data' do

    context "coverage_service is :travis_ci" do
      before(:each) do
        fixtures_project.ci_service = :travis_ci
        fixtures_project.stub(:yml).and_return({})
      end

      it "should return valid json for hardcover coverage data" do
        fixtures_project.stub(:travis_job_id).and_return("9182")
        expect(fixtures_project.send(:hardcover_coverage_data)).to eq("{\"service_job_id\":\"9182\",\"service_name\":\"travis-ci\",\"repo_token\":null,\"source_files\":[{\"name\":\"spec/fixtures/fixtures/more_files/Branches.m\",\"source\":\"//\\n//  Branches.m\\n//  fixtures\\n//\\n//  Created by Julian Krumow on 11.10.14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"Branches.h\\\"\\n\\n@implementation Branches\\n\\n- (void)branches:(BOOL)goIf skipBranches:(BOOL)skipBranches\\n{\\n    if (goIf) {\\n        NSLog(@\\\"foo.\\\");\\n        \\n        if (!skipBranches) {\\n            NSLog(@\\\"not skipped.\\\");\\n        }\\n    } else {\\n        NSLog(@\\\"bar.\\\");\\n    }\\n    \\n    int i = 5;\\n    if (i == 5) {\\n        return;\\n    }\\n    switch (i) {\\n        case 0:\\n            NSLog(@\\\"0\\\");\\n            break;\\n            \\n        case 1:\\n            NSLog(@\\\"1\\\");\\n            break;\\n        case 5:\\n            NSLog(@\\\"5\\\");\\n            break;\\n        default:\\n            break;\\n    }\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,2,null,2,1,null,1,0,0,1,1,null,null,2,2,2,null,0,null,0,0,null,null,0,0,null,0,0,null,0,null,2,null,null]},{\"name\":\"spec/fixtures/fixtures/more_files/Empty.m\",\"source\":\"//\\n//  Empty.m\\n//  fixtures\\n//\\n//  Created by Julian Krumow on 27.10.14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"Empty.h\\\"\\n\\n@implementation Empty\\n\\n@end\\n\",\"coverage\":[]},{\"name\":\"spec/fixtures/fixtures/fixtures.m\",\"source\":\"//\\n//  fixtures.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"fixtures.h\\\"\\n\\n@implementation fixtures\\n\\n- (void)testedMethod\\n{\\n    NSLog(@\\\"tested\\\");\\n}\\n\\n- (void)untestedMethod\\n{\\n    NSLog(@\\\"untested\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,1,null,null,null,0,0,null,null]},{\"name\":\"spec/fixtures/fixtures/more_files/peekaview.m\",\"source\":\"//\\n//  peekaview.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"peekaview.h\\\"\\n\\n@implementation peekaview\\n\\n- (id)initWithFrame:(CGRect)frame\\n{\\n    self = [super initWithFrame:frame];\\n    if (self) {\\n        // Initialization code\\n    }\\n    return self;\\n}\\n\\n/*\\n// Only override drawRect: if you perform custom drawing.\\n// An empty implementation adversely affects performance during animation.\\n- (void)drawRect:(CGRect)rect\\n{\\n    // Drawing code\\n}\\n*/\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,0,null,0,0,null,0,0,0,null,null,null,null,null,null,null,null,null,null,null]},{\"name\":\"spec/fixtures/fixturesTests/BranchesTests.m\",\"source\":\"//\\n//  BranchesTests.m\\n//  fixtures\\n//\\n//  Created by Julian Krumow on 11.10.14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n#import \\\"Branches.h\\\"\\n\\n@interface BranchesTests : XCTestCase\\n\\n@end\\n\\n@implementation BranchesTests\\n\\n- (void)setUp {\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown {\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testBranchesNoBranches {\\n    Branches *branches = [[Branches alloc] init];\\n    [branches branches:NO skipBranches:NO];\\n}\\n\\n- (void)testBranchesFirstBranchAndSkip {\\n    Branches *branches = [[Branches alloc] init];\\n    [branches branches:YES skipBranches:YES];\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,2,null,2,null,null,null,2,2,null,null,1,1,1,null,null,1,1,1,null,null]},{\"name\":\"spec/fixtures/fixturesTests/fixturesTests.m\",\"source\":\"//\\n//  fixturesTests.m\\n//  fixturesTests\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n#import \\\"fixtures.h\\\"\\n\\n@interface fixturesTests : XCTestCase\\n\\n@end\\n\\n@implementation fixturesTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    fixtures *f = [[fixtures alloc] init];\\n    [f testedMethod];\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,1,1,1,null,null]},{\"name\":\"spec/fixtures/fixturesTests/peekaviewTests.m\",\"source\":\"//\\n//  peekaviewTests.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n\\n@interface peekaviewTests : XCTestCase\\n\\n@end\\n\\n@implementation peekaviewTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    XCTAssert(YES, @\\\"woot\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,2,1,null,null]}]}")
      end

      it "should raise an error if there is no TRAVIS_JOB_ID" do
        fixtures_project.stub(:jenkins_job_id).and_return(nil)
        fixtures_project.stub(:travis_job_id).and_return(nil)
        expect { fixtures_project.send(:hardcover_coverage_data) }.to raise_error(StandardError)
      end

      it "should raise an error if there is no BUILD_NUMBER or JOB_NAME" do
        fixtures_project.stub(:travis_job_id).and_return(nil)
        fixtures_project.stub(:jenkins_job_id).and_return(nil)
        expect { fixtures_project.send(:hardcover_coverage_data) }.to raise_error(StandardError)
      end
    end

    it "should raise an error if it does not recognize the ci_service" do
      fixtures_project.ci_service = :non_existing_ci
      expect { fixtures_project.send(:hardcover_coverage_data) }.to raise_error(StandardError)
    end
  end

  describe '#post' do
    before(:each) do
      yaml_text = <<-EOF
        repo_token: "27dd855e706b22126ec6daaaf7bb40b5"
        base_url: "http://api.hardcover.io"
      EOF
      yaml = YAML.load(yaml_text)
      fixtures_project.stub(:yml).and_return(yaml)
    end

    it "should save the hardcover_coverage_data to a file and post it to hardcover" do
      fixtures_project.stub(:travis_job_id).and_return("9182")
      fixtures_project.stub(:coverage_service_url).and_return("http://api.hardcover.io")
      expect(fixtures_project).to receive(:`) do |cmd|
        expect(cmd).to eq("curl --form json_file=@hardcover_json_file http://api.hardcover.io/v1/jobs")
        expect(File.open('hardcover_json_file', 'r').read).to eq("{\"service_job_id\":\"9182\",\"service_name\":\"travis-ci\",\"repo_token\":\"27dd855e706b22126ec6daaaf7bb40b5\",\"source_files\":[{\"name\":\"spec/fixtures/fixtures/more_files/Branches.m\",\"source\":\"//\\n//  Branches.m\\n//  fixtures\\n//\\n//  Created by Julian Krumow on 11.10.14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"Branches.h\\\"\\n\\n@implementation Branches\\n\\n- (void)branches:(BOOL)goIf skipBranches:(BOOL)skipBranches\\n{\\n    if (goIf) {\\n        NSLog(@\\\"foo.\\\");\\n        \\n        if (!skipBranches) {\\n            NSLog(@\\\"not skipped.\\\");\\n        }\\n    } else {\\n        NSLog(@\\\"bar.\\\");\\n    }\\n    \\n    int i = 5;\\n    if (i == 5) {\\n        return;\\n    }\\n    switch (i) {\\n        case 0:\\n            NSLog(@\\\"0\\\");\\n            break;\\n            \\n        case 1:\\n            NSLog(@\\\"1\\\");\\n            break;\\n        case 5:\\n            NSLog(@\\\"5\\\");\\n            break;\\n        default:\\n            break;\\n    }\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,2,null,2,1,null,1,0,0,1,1,null,null,2,2,2,null,0,null,0,0,null,null,0,0,null,0,0,null,0,null,2,null,null]},{\"name\":\"spec/fixtures/fixtures/more_files/Empty.m\",\"source\":\"//\\n//  Empty.m\\n//  fixtures\\n//\\n//  Created by Julian Krumow on 27.10.14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"Empty.h\\\"\\n\\n@implementation Empty\\n\\n@end\\n\",\"coverage\":[]},{\"name\":\"spec/fixtures/fixtures/fixtures.m\",\"source\":\"//\\n//  fixtures.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"fixtures.h\\\"\\n\\n@implementation fixtures\\n\\n- (void)testedMethod\\n{\\n    NSLog(@\\\"tested\\\");\\n}\\n\\n- (void)untestedMethod\\n{\\n    NSLog(@\\\"untested\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,1,null,null,null,0,0,null,null]},{\"name\":\"spec/fixtures/fixtures/more_files/peekaview.m\",\"source\":\"//\\n//  peekaview.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"peekaview.h\\\"\\n\\n@implementation peekaview\\n\\n- (id)initWithFrame:(CGRect)frame\\n{\\n    self = [super initWithFrame:frame];\\n    if (self) {\\n        // Initialization code\\n    }\\n    return self;\\n}\\n\\n/*\\n// Only override drawRect: if you perform custom drawing.\\n// An empty implementation adversely affects performance during animation.\\n- (void)drawRect:(CGRect)rect\\n{\\n    // Drawing code\\n}\\n*/\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,0,null,0,0,null,0,0,0,null,null,null,null,null,null,null,null,null,null,null]},{\"name\":\"spec/fixtures/fixturesTests/BranchesTests.m\",\"source\":\"//\\n//  BranchesTests.m\\n//  fixtures\\n//\\n//  Created by Julian Krumow on 11.10.14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n#import \\\"Branches.h\\\"\\n\\n@interface BranchesTests : XCTestCase\\n\\n@end\\n\\n@implementation BranchesTests\\n\\n- (void)setUp {\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown {\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testBranchesNoBranches {\\n    Branches *branches = [[Branches alloc] init];\\n    [branches branches:NO skipBranches:NO];\\n}\\n\\n- (void)testBranchesFirstBranchAndSkip {\\n    Branches *branches = [[Branches alloc] init];\\n    [branches branches:YES skipBranches:YES];\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,2,null,2,null,null,null,2,2,null,null,1,1,1,null,null,1,1,1,null,null]},{\"name\":\"spec/fixtures/fixturesTests/fixturesTests.m\",\"source\":\"//\\n//  fixturesTests.m\\n//  fixturesTests\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n#import \\\"fixtures.h\\\"\\n\\n@interface fixturesTests : XCTestCase\\n\\n@end\\n\\n@implementation fixturesTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    fixtures *f = [[fixtures alloc] init];\\n    [f testedMethod];\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,1,1,1,null,null]},{\"name\":\"spec/fixtures/fixturesTests/peekaviewTests.m\",\"source\":\"//\\n//  peekaviewTests.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n\\n@interface peekaviewTests : XCTestCase\\n\\n@end\\n\\n@implementation peekaviewTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    XCTAssert(YES, @\\\"woot\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,2,1,null,null]}]}")
      end.once
      fixtures_project.post
    end

    it "should always remove the hardcover_json_file after it's done" do
      fixtures_project.stub(:`)

      fixtures_project.stub(:travis_job_id).and_return("9182")
      fixtures_project.stub(:coverage_service_url).and_return("http://api.hardcover.io")
      fixtures_project.post
      expect(File.exist?("hardcover_json_file")).to be_falsy
      fixtures_project.stub(:travis_job_id).and_return(nil)
      expect { fixtures_project.post }.to raise_error
      expect(File.exist?("hardcover_json_file")).to be_falsy
    end
  end
end
