//
//  RZProxyAssemblageTests.m
//  RZTree
//
//  Created by Brian King on 3/20/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZProxyTree.h"
#import "RZFilterTree.h"

#import "RZTree+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZTestHelpers.h"
#import <XCTest/XCTest.h>

NSUInteger topSongPath[2] = {0,0};
NSUInteger firstWriterPath[3] = {0,0,0};

@interface RZProxyAssemblageTests : XCTestCase<RZTreeObserver>

@property (nonatomic, strong) NSMutableArray *delegateEvents;
@property (nonatomic, strong) RZChangeSet *changeSet;

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

- (void)node:(RZTree *)node didEndUpdatesWithChangeSet:(RZChangeSet *)changeSet
{
    self.changeSet = changeSet;
}

- (void)testSingleKeyProxy
{
    Artist *pf = [Artist pinkFloyd];

    RZProxyTree *a = [[RZProxyTree alloc] initWithObject:pf keypath:@"songs"];
    Artist *rPF = [a objectAtIndexPath:nil];
    XCTAssertNotNil(rPF);
    Song *s = [a objectAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
    XCTAssertNotNil(s);
    XCTAssertTrue([s isKindOfClass:[Song class]]);
    XCTAssertTrue([a children].count == 9);
}

- (void)testMutliKeyProxy
{
    Artist *pf = [Artist pinkFloyd];

    RZProxyTree *a = [[RZProxyTree alloc] initWithObject:pf keypaths:@[@"albumns", @"songs", @"writers"]];
    Albumn *darkSide = [a objectAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
    XCTAssertNotNil(darkSide);
    XCTAssertEqual(darkSide, [a objectAtIndexPath:[NSIndexPath indexPathWithIndex:0]]);
    XCTAssertEqualObjects(darkSide.name, @"Dark Side Of The Moon");
    XCTAssertTrue([a children].count == 2);
    Song *s = [a objectAtIndexPath:[NSIndexPath indexPathWithIndexes:topSongPath length:2]];
    XCTAssertTrue(s && [s isKindOfClass:[Song class]]);
    NSString *w = [a objectAtIndexPath:[NSIndexPath indexPathWithIndexes:firstWriterPath length:3]];
    XCTAssertTrue(w && [w isKindOfClass:[NSString class]]);
}

- (void)testEqualAssemblageExpansion
{
    Artist *pf = [Artist pinkFloyd];
    RZProxyTree *a = [[RZProxyTree alloc] initWithObject:pf keypaths:@[@"albumns", @"songs"]];
    XCTAssertTrue([[a nodeAtIndex:0] isKindOfClass:[RZTree class]]);
    XCTAssertEqual([a nodeAtIndex:0], [a nodeAtIndex:0]);
}

- (void)testExternalProxy
{
    self.testProxyArray = [NSMutableArray array];
    RZProxyTree *pa = [[RZProxyTree alloc] initWithObject:self keypath:@"testProxyArray"];
    [pa addObserver:self];
    NSMutableArray *externalProxy = [self mutableArrayValueForKey:@"testProxyArray"];
    // This only causes the observer change event
    [pa openBatchUpdate];
    [externalProxy addObject:@(0)];
    [externalProxy addObject:@(1)];
    [externalProxy removeObjectAtIndex:0];
    [externalProxy removeObjectAtIndex:0];
    [pa closeBatchUpdate];
}

- (void)testInternalProxy
{
    self.testProxyArray = [NSArray array];
    RZProxyTree *pa = [[RZProxyTree alloc] initWithObject:self keypath:@"testProxyArray"];
    [pa addObserver:self];
    NSMutableArray *proxyArray = [pa mutableChildren];
    [pa openBatchUpdate];
    // This causes double change events (setter + observer)
    [proxyArray addObject:@"0"];
    [proxyArray addObject:@"1"];
    [proxyArray removeObjectAtIndex:0];
    [proxyArray removeObjectAtIndex:0];
    [pa closeBatchUpdate];
    XCTAssertEqual(proxyArray.count, self.testProxyArray.count);
}

- (void)testDirectConfigurationMidChange
{
    self.testProxyArray = [NSArray array];
    RZProxyTree *pa = [[RZProxyTree alloc] initWithObject:self keypath:@"testProxyArray"];
    [pa addObserver:self];
    NSMutableArray *proxyArray = [pa mutableChildren];
    [pa openBatchUpdate];
    // This causes double change events (setter + observer)
    [proxyArray addObject:@"0"];
    [proxyArray addObject:@"1"];
    self.testProxyArray = @[@"2", @"3"];
    [pa closeBatchUpdate];
    XCTAssert(proxyArray.count == self.testProxyArray.count && proxyArray.count == 2);
    XCTAssert(self.changeSet.insertedIndexPaths.count == 2);
    XCTAssert([(NSIndexPath *)self.changeSet.insertedIndexPaths[0] rz_lastIndex] == 0);
    XCTAssert([(NSIndexPath *)self.changeSet.insertedIndexPaths[1] rz_lastIndex] == 1);
    XCTAssert(self.changeSet.removedIndexPaths.count == 0);
}

- (void)testDirectConfiguration
{
    self.testProxyArray = @[@"1", @"2"];
    RZProxyTree *pa = [[RZProxyTree alloc] initWithObject:self keypath:@"testProxyArray"];
    [pa addObserver:self];
    NSMutableArray *proxyArray = [pa mutableChildren];
    [pa openBatchUpdate];
    self.testProxyArray = @[@"2", @"3"];
    [pa closeBatchUpdate];
    XCTAssert(proxyArray.count == self.testProxyArray.count && proxyArray.count == 2);
    XCTAssert(self.changeSet.insertedIndexPaths.count == 2);
    XCTAssert([(NSIndexPath *)self.changeSet.insertedIndexPaths[0] rz_lastIndex] == 0);
    XCTAssert([(NSIndexPath *)self.changeSet.insertedIndexPaths[1] rz_lastIndex] == 1);
    XCTAssert(self.changeSet.removedIndexPaths.count == 2);
    XCTAssert([(NSIndexPath *)self.changeSet.removedIndexPaths[0] rz_lastIndex] == 0);
    XCTAssert([(NSIndexPath *)self.changeSet.removedIndexPaths[1] rz_lastIndex] == 1);
}

- (void)testDirectMutation
{
    NSMutableArray *array = [NSMutableArray array];
    self.testProxyArray = array;
    RZProxyTree *pa = [[RZProxyTree alloc] initWithObject:self keypath:@"testProxyArray"];
    [pa addObserver:self];

    [pa openBatchUpdate];
    [array addObject:@(0)];
    [array addObject:@(1)];
    [array removeObjectAtIndex:0];
    [array removeObjectAtIndex:0];
    [pa closeBatchUpdate];
}

#define ITERATION_TEST_COUNT 1000//00
- (void)testArrayProxyPerformance
{
    self.testProxyArray = [NSArray array];

    [self measureBlock:^{
        NSMutableArray *proxy = [self mutableArrayValueForKey:@"testProxyArray"];
        for ( NSUInteger i = 0; i < ITERATION_TEST_COUNT; i++ ) {
            [proxy addObject:@(i)];
        }
    }];
}

/*
- (void)insertObject:(NSObject *)object inTestProxyArrayAtIndex:(NSUInteger)index
{
    [(NSMutableArray *)self.testProxyArray insertObject:object atIndex:index];
}

- (void)removeObjectFromTestProxyArrayAtIndex:(NSUInteger)index
{
    [(NSMutableArray *)self.testProxyArray removeObjectAtIndex:index];
}
 */
- (void)testMutableArrayProxyPerformance
{
    // performance here is the same, until the above code is un-commented.
    // This should be fixed, but was mostly just to explore performance considerations, not to
    // test it.
    self.testProxyArray = [NSMutableArray array];

    [self measureBlock:^{
        NSMutableArray *proxy = [self mutableArrayValueForKey:@"testProxyArray"];
        for ( NSUInteger i = 0; i < ITERATION_TEST_COUNT; i++ ) {
            [proxy addObject:@(i)];
        }
    }];
}

- (void)testUpdate
{
    NSIndexPath *top = [NSIndexPath indexPathWithIndexes:topSongPath length:2];
    Artist *pf = [Artist pinkFloyd];
    RZProxyTree *a = [[RZProxyTree alloc] initWithObject:pf keypaths:@[@"albumns", @"songs", @"writers"]];
    [a addObserver:self];

    pf.name = @"Pink-ish Floyd";
    XCTAssertTrue(self.changeSet.updatedIndexPaths.count == 1);

    [a openBatchUpdate];
    Albumn *dsom = [a objectAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
    dsom.name = @"Which Side of The Moon?";

    Song *s = [a objectAtIndexPath:top];
    s.name = @"Not Sure";
    NSMutableArray *writers = [[a nodeAtIndexPath:top] mutableChildren];
    [writers removeAllObjects];
    [a closeBatchUpdate];

    XCTAssertTrue(self.changeSet.updatedIndexPaths.count == 2);
    XCTAssertTrue(self.changeSet.removedIndexPaths.count == 1);
}

- (void)testTreeFiltering
{
    Artist *pf = [Artist pinkFloyd];
    RZProxyTree *a = [[RZProxyTree alloc] initWithObject:pf keypaths:@[@"albumns", @"songs", @"writers"]];
    RZTree<RZFilterableTree> *f = [RZTree filterableNodeWithNode:a];
    [f addObserver:self];

    f.filter = [NSPredicate predicateWithBlock:^BOOL(Albumn *albumn, NSDictionary *bindings) {
        BOOL match = YES;
        if ( [albumn isKindOfClass:[Albumn class]] ) {
            match = [albumn.name hasPrefix:@"W"] || [albumn.name hasPrefix:@"T"];
        }
        return match;
    }];

    // Ensure the correct albumn is exposed, and the proper remove event
    XCTAssert([f countOfElements] == 1);
    XCTAssert(self.changeSet.removedIndexPaths.count == 1);

    Albumn *albumn = [f objectAtIndexPath:[NSIndexPath indexPathWithIndex:0]];
    NSIndexPath *removedIndexPath = self.changeSet.removedIndexPaths[0];
    XCTAssert(removedIndexPath.length == 1 && [removedIndexPath indexAtPosition:0] == 0);
    XCTAssert([[albumn name] hasPrefix:@"W"]);

    // Change the filter to songs beginning with W or T
    f.filter = [NSPredicate predicateWithBlock:^BOOL(Song *song, NSDictionary *bindings) {
        BOOL match = YES;
        if ( [song isKindOfClass:[Song class]] ) {
            match = [song.name hasPrefix:@"W"] || [song.name hasPrefix:@"T"];
        }
        return match;
    }];
    XCTAssert([f countOfElements] == 2);
    XCTAssert(self.changeSet.insertedIndexPaths.count == 1);
    XCTAssertEqualObjects(self.changeSet.insertedIndexPaths[0], [NSIndexPath indexPathWithIndex:0]);
    XCTAssert(self.changeSet.removedIndexPaths.count == 5);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[0], [NSIndexPath indexPathForRow:0 inSection:0]);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[1], [NSIndexPath indexPathForRow:1 inSection:0]);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[2], [NSIndexPath indexPathForRow:2 inSection:0]);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[3], [NSIndexPath indexPathForRow:0 inSection:1]);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[4], [NSIndexPath indexPathForRow:2 inSection:1]);

    f.filter = nil;
    f.filter = [NSPredicate predicateWithBlock:^BOOL(Song *song, NSDictionary *bindings) {
        BOOL match = YES;
        if ( [song isKindOfClass:[Song class]] ) {
            match = [song.name hasPrefix:@"W"] || [song.name hasPrefix:@"T"];
        }
        return match;
    }];
    XCTAssert([f countOfElements] == 2);
    XCTAssert(self.changeSet.insertedIndexPaths.count == 0);
    XCTAssert(self.changeSet.removedIndexPaths.count == 5);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[0], [NSIndexPath indexPathForRow:0 inSection:0]);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[1], [NSIndexPath indexPathForRow:1 inSection:0]);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[2], [NSIndexPath indexPathForRow:2 inSection:0]);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[3], [NSIndexPath indexPathForRow:0 inSection:1]);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths[4], [NSIndexPath indexPathForRow:2 inSection:1]);
}

@end
