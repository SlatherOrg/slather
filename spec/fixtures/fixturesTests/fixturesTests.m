//
//  fixturesTests.m
//  fixturesTests
//
//  Created by Mark Larsen on 6/24/14.
//  Copyright (c) 2014 marklarr. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "fixtures.h"
#import "fixturesTwo.h"

@interface fixturesTests : XCTestCase

@end

@implementation fixturesTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    fixtures *f = [[fixtures alloc] init];
    [f testedMethod];
}

- (void)testFixturesTwo
{
    fixturesTwo *f2 = [[fixturesTwo alloc] init];

    XCTAssertEqual([f2 doSomething], 11);
}

@end
