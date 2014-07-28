require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe Slather::CoverageService::Coveralls do

  let(:fixtures_project) do
    proj = Slather::Project.open(FIXTURES_PROJECT_PATH)
    proj.extend(Slather::CoverageService::Coveralls)
  end

  describe "#coverage_file_class" do
    it "should return CoverallsCoverageFile" do
      expect(fixtures_project.send(:coverage_file_class)).to eq(Slather::CoverallsCoverageFile)
    end
  end

  describe "#travis_job_id" do
    it "should return the TRAVIS_JOB_ID environment variable" do
      ENV['TRAVIS_JOB_ID'] = "9182"
      expect(fixtures_project.send(:travis_job_id)).to eq("9182")
    end
  end

  describe '#coveralls_coverage_data' do

    context "coverage_service is :travis_ci" do
      before(:each) { fixtures_project.ci_service = :travis_ci }

      it "should return valid json for coveralls coverage data" do
        fixtures_project.stub(:travis_job_id).and_return("9182")
        expect(fixtures_project.send(:coveralls_coverage_data)).to eq("{\"service_job_id\":\"9182\",\"service_name\":\"travis-ci\",\"source_files\":[{\"name\":\"spec/fixtures/fixtures/fixtures.m\",\"source\":\"//\\n//  fixtures.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"fixtures.h\\\"\\n\\n@implementation fixtures\\n\\n- (void)testedMethod\\n{\\n    NSLog(@\\\"tested\\\");\\n}\\n\\n- (void)untestedMethod\\n{\\n    NSLog(@\\\"untested\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,1,null,null,null,0,0,null,null]},{\"name\":\"spec/fixtures/fixtures/more_files/peekaview.m\",\"source\":\"//\\n//  peekaview.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"peekaview.h\\\"\\n\\n@implementation peekaview\\n\\n- (id)initWithFrame:(CGRect)frame\\n{\\n    self = [super initWithFrame:frame];\\n    if (self) {\\n        // Initialization code\\n    }\\n    return self;\\n}\\n\\n/*\\n// Only override drawRect: if you perform custom drawing.\\n// An empty implementation adversely affects performance during animation.\\n- (void)drawRect:(CGRect)rect\\n{\\n    // Drawing code\\n}\\n*/\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,0,null,0,0,null,0,0,0,null,null,null,null,null,null,null,null,null,null,null]},{\"name\":\"spec/fixtures/fixturesTests/fixturesTests.m\",\"source\":\"//\\n//  fixturesTests.m\\n//  fixturesTests\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n#import \\\"fixtures.h\\\"\\n\\n@interface fixturesTests : XCTestCase\\n\\n@end\\n\\n@implementation fixturesTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    fixtures *f = [[fixtures alloc] init];\\n    [f testedMethod];\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,1,1,1,null,null]},{\"name\":\"spec/fixtures/fixturesTests/peekaviewTests.m\",\"source\":\"//\\n//  peekaviewTests.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n\\n@interface peekaviewTests : XCTestCase\\n\\n@end\\n\\n@implementation peekaviewTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    XCTAssert(YES, @\\\"woot\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,2,1,null,null]}]}")
      end

      it "should raise an error if there is no TRAVIS_JOB_ID" do
        fixtures_project.stub(:travis_job_id).and_return(nil)
        expect { fixtures_project.send(:coveralls_coverage_data) }.to raise_error(StandardError)
      end
    end

    context "coverage_service is :travis_pro" do
      before(:each) { fixtures_project.ci_service = :travis_pro }

      it "should return valid json for coveralls coverage data" do
        fixtures_project.stub(:travis_job_id).and_return("9182")
        fixtures_project.stub(:ci_access_token).and_return("abc123")
        expect(fixtures_project.send(:coveralls_coverage_data)).to eq("{\"service_job_id\":\"9182\",\"service_name\":\"travis-pro\",\"repo_token\":\"abc123\",\"source_files\":[{\"name\":\"spec/fixtures/fixtures/fixtures.m\",\"source\":\"//\\n//  fixtures.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"fixtures.h\\\"\\n\\n@implementation fixtures\\n\\n- (void)testedMethod\\n{\\n    NSLog(@\\\"tested\\\");\\n}\\n\\n- (void)untestedMethod\\n{\\n    NSLog(@\\\"untested\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,1,null,null,null,0,0,null,null]},{\"name\":\"spec/fixtures/fixtures/more_files/peekaview.m\",\"source\":\"//\\n//  peekaview.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"peekaview.h\\\"\\n\\n@implementation peekaview\\n\\n- (id)initWithFrame:(CGRect)frame\\n{\\n    self = [super initWithFrame:frame];\\n    if (self) {\\n        // Initialization code\\n    }\\n    return self;\\n}\\n\\n/*\\n// Only override drawRect: if you perform custom drawing.\\n// An empty implementation adversely affects performance during animation.\\n- (void)drawRect:(CGRect)rect\\n{\\n    // Drawing code\\n}\\n*/\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,0,null,0,0,null,0,0,0,null,null,null,null,null,null,null,null,null,null,null]},{\"name\":\"spec/fixtures/fixturesTests/fixturesTests.m\",\"source\":\"//\\n//  fixturesTests.m\\n//  fixturesTests\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n#import \\\"fixtures.h\\\"\\n\\n@interface fixturesTests : XCTestCase\\n\\n@end\\n\\n@implementation fixturesTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    fixtures *f = [[fixtures alloc] init];\\n    [f testedMethod];\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,1,1,1,null,null]},{\"name\":\"spec/fixtures/fixturesTests/peekaviewTests.m\",\"source\":\"//\\n//  peekaviewTests.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n\\n@interface peekaviewTests : XCTestCase\\n\\n@end\\n\\n@implementation peekaviewTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    XCTAssert(YES, @\\\"woot\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,2,1,null,null]}]}")
      end

      it "should raise an error if there is no TRAVIS_JOB_ID" do
        fixtures_project.stub(:travis_job_id).and_return(nil)
        expect { fixtures_project.send(:coveralls_coverage_data) }.to raise_error(StandardError)
      end
    end

    it "should raise an error if it does not recognize the ci_service" do
      fixtures_project.ci_service = :jenkins_ci
      expect { fixtures_project.send(:coveralls_coverage_data) }.to raise_error(StandardError)
    end
  end

  describe '#post' do
    it "should save the coveralls_coverage_data to a file and post it to coveralls" do
      fixtures_project.stub(:travis_job_id).and_return("9182")
      expect(fixtures_project).to receive(:`) do |cmd|
        expect(cmd).to eq("curl -s --form json_file=@coveralls_json_file https://coveralls.io/api/v1/jobs")
        expect(File.open('coveralls_json_file', 'r').read).to eq("{\"service_job_id\":\"9182\",\"service_name\":\"travis-ci\",\"source_files\":[{\"name\":\"spec/fixtures/fixtures/fixtures.m\",\"source\":\"//\\n//  fixtures.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"fixtures.h\\\"\\n\\n@implementation fixtures\\n\\n- (void)testedMethod\\n{\\n    NSLog(@\\\"tested\\\");\\n}\\n\\n- (void)untestedMethod\\n{\\n    NSLog(@\\\"untested\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,1,null,null,null,0,0,null,null]},{\"name\":\"spec/fixtures/fixtures/more_files/peekaview.m\",\"source\":\"//\\n//  peekaview.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import \\\"peekaview.h\\\"\\n\\n@implementation peekaview\\n\\n- (id)initWithFrame:(CGRect)frame\\n{\\n    self = [super initWithFrame:frame];\\n    if (self) {\\n        // Initialization code\\n    }\\n    return self;\\n}\\n\\n/*\\n// Only override drawRect: if you perform custom drawing.\\n// An empty implementation adversely affects performance during animation.\\n- (void)drawRect:(CGRect)rect\\n{\\n    // Drawing code\\n}\\n*/\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,0,null,0,0,null,0,0,0,null,null,null,null,null,null,null,null,null,null,null]},{\"name\":\"spec/fixtures/fixturesTests/fixturesTests.m\",\"source\":\"//\\n//  fixturesTests.m\\n//  fixturesTests\\n//\\n//  Created by Mark Larsen on 6/24/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n#import \\\"fixtures.h\\\"\\n\\n@interface fixturesTests : XCTestCase\\n\\n@end\\n\\n@implementation fixturesTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    fixtures *f = [[fixtures alloc] init];\\n    [f testedMethod];\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,1,1,1,null,null]},{\"name\":\"spec/fixtures/fixturesTests/peekaviewTests.m\",\"source\":\"//\\n//  peekaviewTests.m\\n//  fixtures\\n//\\n//  Created by Mark Larsen on 6/25/14.\\n//  Copyright (c) 2014 marklarr. All rights reserved.\\n//\\n\\n#import <XCTest/XCTest.h>\\n\\n@interface peekaviewTests : XCTestCase\\n\\n@end\\n\\n@implementation peekaviewTests\\n\\n- (void)setUp\\n{\\n    [super setUp];\\n    // Put setup code here. This method is called before the invocation of each test method in the class.\\n}\\n\\n- (void)tearDown\\n{\\n    // Put teardown code here. This method is called after the invocation of each test method in the class.\\n    [super tearDown];\\n}\\n\\n- (void)testExample\\n{\\n    XCTAssert(YES, @\\\"woot\\\");\\n}\\n\\n@end\\n\",\"coverage\":[null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,1,null,null,null,null,1,1,null,null,null,2,1,null,null]}]}")
      end.once
      fixtures_project.post
    end

    it "should always remove the coveralls_json_file after it's done" do
      fixtures_project.stub(:`)

      fixtures_project.stub(:travis_job_id).and_return("9182")
      fixtures_project.post
      expect(File.exist?("coveralls_json_file")).to be_falsy
      fixtures_project.stub(:travis_job_id).and_return(nil)
      expect { fixtures_project.post }.to raise_error
      expect(File.exist?("coveralls_json_file")).to be_falsy
    end
  end
end
