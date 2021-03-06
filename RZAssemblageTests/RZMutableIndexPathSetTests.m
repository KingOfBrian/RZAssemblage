//
//  RZMutableIndexPathSet.m
//  RZTree
//
//  Created by Brian King on 2/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTestHelpers.h"
#import <XCTest/XCTest.h>
#import "RZIndexPathSet.h"

@interface RZMutableIndexPathSetTests : XCTestCase

@end

@implementation RZMutableIndexPathSetTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (id)indexSetWithRange:(NSRange)range
{
//#define TEST_FOUNDATION
#ifdef TEST_FOUNDATION
    return [[NSMutableIndexSet alloc] initWithIndexesInRange:range];
#else
    NSMutableSet *set = [NSMutableSet set];
    for ( NSUInteger i = range.location; i < range.location + range.length; i++ ) {
        [set addObject:[NSIndexPath indexPathWithIndex:i]];
    }
    return [RZMutableIndexPathSet setWithIndexPaths:set];
#endif
}

- (void)testIndexSetPositiveShift
{
    NSMutableIndexSet *indexSet = [self indexSetWithRange:NSMakeRange(1, 2)];
    [indexSet shiftIndexesStartingAtIndex:1 by:1];
    [indexSet shiftIndexesStartingAtIndex:3 by:1];
    [indexSet shiftIndexesStartingAtIndex:1 by:1];
    XCTAssert([indexSet count] == 2);
    XCTAssert([indexSet containsIndex:3]);
    XCTAssert([indexSet containsIndex:5]);
}

- (void)testIndexSetNegativeShift
{
    NSMutableIndexSet *indexSet = [self indexSetWithRange:NSMakeRange(3, 2)];
    // If the shift starts at an index that is contained, and the previous index is contained, grow the range
    [indexSet shiftIndexesStartingAtIndex:2 by:-1];
    [indexSet shiftIndexesStartingAtIndex:2 by:-1];
    XCTAssert([indexSet count] == 2);
    XCTAssert([indexSet containsIndex:1]);
    XCTAssert([indexSet containsIndex:2]);

    // Shift Range does not enter indexSet
    // _ X X
    // -
    indexSet = [self indexSetWithRange:NSMakeRange(1, 2)];
    [indexSet shiftIndexesStartingAtIndex:0 by:-1];
    XCTAssert([indexSet count] == 2);
    XCTAssert([indexSet containsIndex:0]);
    XCTAssert([indexSet containsIndex:1]);

    // Shift Range specifies the start of the index range, it does not collapse any indexes
    // _ X X
    // _ -
    indexSet = [self indexSetWithRange:NSMakeRange(1, 2)];
    [indexSet shiftIndexesStartingAtIndex:1 by:-1];
    XCTAssert([indexSet count] == 2);
    XCTAssert([indexSet containsIndex:0]);
    XCTAssert([indexSet containsIndex:1]);

    // Shift lands inside the index set, trim the range
    // _ X X
    // _ _ -
    indexSet = [self indexSetWithRange:NSMakeRange(1, 2)];
    [indexSet shiftIndexesStartingAtIndex:2 by:-1];
    XCTAssert([indexSet count] == 1);
    XCTAssert([indexSet containsIndex:1]);

    // Shift lands inside the index set, trim the range
    // _ X X
    // _ _ _ -
    indexSet = [self indexSetWithRange:NSMakeRange(1, 2)];
    [indexSet shiftIndexesStartingAtIndex:3 by:-1];
    XCTAssert([indexSet count] == 1);
    XCTAssert([indexSet containsIndex:1]);

    // Shift lands inside the index set, trim the range
    // _ X X
    // _ _ _ - -
    indexSet = [self indexSetWithRange:NSMakeRange(1, 2)];
    [indexSet shiftIndexesStartingAtIndex:3 by:-2];
    XCTAssert([indexSet count] == 0);

    // Shift Range below zero
    // X X
    // -
    indexSet = [self indexSetWithRange:NSMakeRange(0, 2)];
    [indexSet shiftIndexesStartingAtIndex:0 by:-1];
    XCTAssert([indexSet count] == 1);
    XCTAssert([indexSet containsIndex:0]);

    // Shift Range below zero
    // X X
    // - -
    indexSet = [self indexSetWithRange:NSMakeRange(0, 2)];
    [indexSet shiftIndexesStartingAtIndex:0 by:-2];
    XCTAssert([indexSet count] == 0);
}

- (void)testAddRemove
{
    RZMutableIndexPathSet *indexPathSet = [self indexSetWithRange:NSMakeRange(1, 2)];
    XCTAssert(indexPathSet.sortedIndexPaths.count == 2);
    [indexPathSet removeIndexPath:[NSIndexPath indexPathWithIndex:0]];
    XCTAssert(indexPathSet.sortedIndexPaths.count == 2);
    [indexPathSet removeIndexPath:[NSIndexPath indexPathWithIndex:1]];
    XCTAssert(indexPathSet.sortedIndexPaths.count == 1);
    [indexPathSet removeIndexPath:[NSIndexPath indexPathWithIndex:2]];
    XCTAssert(indexPathSet.sortedIndexPaths.count == 0);
}

@end
