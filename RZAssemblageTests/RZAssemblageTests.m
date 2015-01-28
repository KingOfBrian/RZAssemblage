//
//  RZAssemblageTests.m
//  RZAssemblageTests
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RZAssemblage.h"
#import "RZMutableAssemblage.h"

@interface RZAssemblageTests : XCTestCase

@end

@implementation RZAssemblageTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testComposition
{
    RZAssemblage *staticValues = [[RZAssemblage alloc] initWithArray:@[@1, @2, @3]];
    XCTAssertEqual([staticValues numberOfChildrenAtIndexPath:nil], 3);
    XCTAssertEqualObjects([staticValues objectAtIndexPath:[NSIndexPath indexPathWithIndex:0]], @1);
    XCTAssertEqualObjects([staticValues objectAtIndexPath:[NSIndexPath indexPathWithIndex:1]], @2);
    XCTAssertEqualObjects([staticValues objectAtIndexPath:[NSIndexPath indexPathWithIndex:2]], @3);
    RZAssemblage *mutableValues = [[RZMutableAssemblage alloc] initWithArray:@[]];
    XCTAssertEqual([mutableValues numberOfChildrenAtIndexPath:nil], 0);

    RZAssemblage *sectioned = [[RZAssemblage alloc] initWithArray:@[staticValues, mutableValues]];

    XCTAssertEqual([sectioned numberOfChildrenAtIndexPath:nil], 2);
    XCTAssertEqual([sectioned numberOfChildrenAtIndexPath:[NSIndexPath indexPathWithIndex:0]], 3);
    XCTAssertEqual([sectioned numberOfChildrenAtIndexPath:[NSIndexPath indexPathWithIndex:1]], 0);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
