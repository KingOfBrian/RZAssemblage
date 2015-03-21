//
//  RZProxyAssemblageTests.m
//  RZAssemblage
//
//  Created by Brian King on 3/20/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZProxyAssemblage.h"
#import "RZAssemblage+Private.h"
#import "TestModels.h"
#import <XCTest/XCTest.h>

NSUInteger topSongPath[2] = {0,0};
NSUInteger firstWriterPath[3] = {0,0,0};

@interface RZProxyAssemblageTests : XCTestCase<RZAssemblageDelegate>

@property (nonatomic, strong) NSMutableArray *delegateEvents;
@property (nonatomic, strong) RZAssemblageChangeSet *changeSet;

@property (nonatomic, strong) NSArray *testProxyArray;


@end

@implementation RZProxyAssemblageTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    self.changeSet = changeSet;
}

- (void)testSingleKeyProxy
{
    Artist *pf = [Artist pinkFloyd];

    RZProxyAssemblage *a = [[RZProxyAssemblage alloc] initWithObject:pf keypath:@"songs"];
    Artist *rPF = [a childAtIndexPath:nil];
    XCTAssertNotNil(rPF);
    Song *s = [a childAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
    XCTAssertNotNil(s);
    XCTAssertTrue([s isKindOfClass:[Song class]]);
    XCTAssertTrue([a childCountAtIndexPath:nil] == 9);
}

- (void)testMutliKeyProxy
{
    Artist *pf = [Artist pinkFloyd];

    RZProxyAssemblage *a = [[RZProxyAssemblage alloc] initWithObject:pf keypaths:@[@"albumns", @"songs", @"writers"]];
    Albumn *darkSide = [a childAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
    XCTAssertNotNil(darkSide);
    XCTAssertEqual(darkSide, [a childAtIndexPath:[NSIndexPath indexPathWithIndex:0]]);
    XCTAssertEqualObjects(darkSide.name, @"Dark Side Of The Moon");
    XCTAssertTrue([a childCountAtIndexPath:nil] == 2);
    Song *s = [a childAtIndexPath:[NSIndexPath indexPathWithIndexes:topSongPath length:2]];
    XCTAssertTrue(s && [s isKindOfClass:[Song class]]);
    NSString *w = [a childAtIndexPath:[NSIndexPath indexPathWithIndexes:firstWriterPath length:3]];
    XCTAssertTrue(w && [w isKindOfClass:[NSString class]]);
}

- (void)testEqualAssemblageExpansion
{
    Artist *pf = [Artist pinkFloyd];
    RZProxyAssemblage *a = [[RZProxyAssemblage alloc] initWithObject:pf keypaths:@[@"albumns", @"songs"]];
    XCTAssertTrue([[a nodeInChildrenAtIndex:0] conformsToProtocol:@protocol(RZAssemblage)]);
    XCTAssertEqual([a nodeInChildrenAtIndex:0], [a nodeInChildrenAtIndex:0]);
}

- (void)testUpdate
{
    NSIndexPath *top = [NSIndexPath indexPathWithIndexes:topSongPath length:2];
    Artist *pf = [Artist pinkFloyd];
    RZProxyAssemblage *a = [[RZProxyAssemblage alloc] initWithObject:pf keypaths:@[@"albumns", @"songs", @"writers"]];
    a.delegate = self;

    pf.name = @"Pink-ish Floyd";
    XCTAssertTrue(self.changeSet.updatedIndexPaths.count == 1);

    [a openBatchUpdate];
    Albumn *dsom = [a childAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
    dsom.name = @"Which Side of The Moon?";

    Song *s = [a childAtIndexPath:top];
    s.name = @"Not Sure";
    NSMutableArray *writers = [a mutableArrayForIndexPath:top];
    [writers removeAllObjects];
    [a closeBatchUpdate];

    XCTAssertTrue(self.changeSet.updatedIndexPaths.count == 2);
    XCTAssertTrue(self.changeSet.removedIndexPaths.count == 1);
}

@end
