//
//  BranchesTests.m
//  fixtures
//
//  Created by Julian Krumow on 11.10.14.
//  Copyright (c) 2014 marklarr. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Branches.h"

@interface BranchesTests : XCTestCase

@end

@implementation BranchesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBranchesNoBranches {
    Branches *branches = [[Branches alloc] init];
    [branches branches:NO skipBranches:NO];
}

- (void)testBranchesFirstBranchAndSkip {
    Branches *branches = [[Branches alloc] init];
    [branches branches:YES skipBranches:YES];
}

@end
