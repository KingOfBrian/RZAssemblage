//
//  RZAssemblageTests.m
//  RZAssemblageTests
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import UIKit;
#import <XCTest/XCTest.h>
#import "RZAssemblage.h"
#import "RZJoinAssemblage.h"
#import "RZFilterAssemblage.h"
#import "RZAssemblageChangeSet.h"
#import "RZIndexPathSet.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZProxyAssemblage.h"

#define TRACE_DELEGATE_EVENT \
RZAssemblageDelegateEvent *event = [[RZAssemblageDelegateEvent alloc] init]; \
[self.delegateEvents addObject:event]; \
event.delegateSelector = _cmd;\
event.assemblage = assemblage;

typedef NS_ENUM(NSUInteger, RZAssemblageMutationType) {
    RZAssemblageMutationTypeInsert = 0,
    RZAssemblageMutationTypeUpdate,
    RZAssemblageMutationTypeRemove,
    RZAssemblageMutationTypeMove
};

@interface RZAssemblageDelegateEvent : NSObject

@property (strong, nonatomic) RZAssemblage *assemblage;
@property (assign, nonatomic) SEL delegateSelector;
@property (assign, nonatomic) RZAssemblageMutationType type;
@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) NSIndexPath *toIndexPath;

@end

@implementation RZAssemblageDelegateEvent

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@, %p, %@ T=%zd O=%@ I=%@ %@>",
            [super description], self.assemblage,
            NSStringFromSelector(self.delegateSelector),
            self.type,
            self.object,
            [self.indexPath rz_shortDescription],
            self.toIndexPath ? [self.toIndexPath rz_shortDescription] : @""];
}

@end

@interface RZAssemblageTests : XCTestCase <RZAssemblageDelegate>

@property (nonatomic, strong) NSMutableArray *delegateEvents;
@property (nonatomic, strong) RZAssemblageChangeSet *changeSet;

@property (nonatomic, strong) NSArray *testProxyArray;

@end

@implementation RZAssemblageTests

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    return YES;
}

+ (NSArray *)values
{
    NSArray *values = @[@"aa",
                        @"ab",
                        @"ac",
                        @"ad",
                        @"ae",
                        @"af",
                        @"ba",
                        @"bb",
                        @"bc",
                        @"bd",
                        @"be",
                        @"bf",
                        @"ca",
                        @"cb",
                        @"cc",
                        @"cd",
                        @"ce",
                        @"cf",
                        @"da",
                        @"db",
                        @"dc",
                        @"dd",
                        @"de",
                        @"df"];
    return values;
}

- (void)setUp
{
    [super setUp];
    self.delegateEvents = [NSMutableArray array];
}

- (void)tearDown
{
    [super tearDown];
    self.delegateEvents = nil;
}

- (void)willBeginUpdatesForAssemblage:(RZAssemblage *)assemblage
{
}

- (void)assemblage:(RZAssemblage *)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    for ( NSIndexPath *indexPath in changeSet.removedIndexPaths ) {
        TRACE_DELEGATE_EVENT
        event.type = RZAssemblageMutationTypeRemove;
        event.object = [changeSet removedObjectAtIndexPath:indexPath];
        event.indexPath = indexPath;
    }
    for ( NSIndexPath *indexPath in changeSet.insertedIndexPaths ) {
        TRACE_DELEGATE_EVENT
        event.type = RZAssemblageMutationTypeInsert;
        event.object = [assemblage objectAtIndexPath:indexPath];
        event.indexPath = indexPath;
    }
    for ( NSIndexPath *indexPath in changeSet.updatedIndexPaths ) {
        TRACE_DELEGATE_EVENT
        event.type = RZAssemblageMutationTypeUpdate;
        event.object = [assemblage objectAtIndexPath:indexPath];
        event.indexPath = indexPath;
    }
//    [changeSet.moves enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
//        TRACE_DELEGATE_EVENT
//        event.type = RZAssemblageMutationTypeMove;
//        event.object = [assemblage objectAtIndexPath:indexPath];
//        event.indexPath = indexPath;
//    }];
    self.changeSet = changeSet;
}

- (void)didEndUpdatesForEnsemble:(RZAssemblage *)assemblage
{
    TRACE_DELEGATE_EVENT
}

- (RZAssemblageDelegateEvent *)firstEvent
{
    return [self.delegateEvents objectAtIndex:0];
}

- (RZAssemblageDelegateEvent *)secondEvent
{
    return [self.delegateEvents objectAtIndex:1];
}

- (void)testComposition
{
    RZAssemblage *staticValues = [RZAssemblage assemblageForArray:@[@1, @2, @3]];
    XCTAssertEqual([staticValues children].count, 3);
    XCTAssertEqualObjects([staticValues objectAtIndexPath:[NSIndexPath indexPathWithIndex:0]], @1);
    XCTAssertEqualObjects([staticValues objectAtIndexPath:[NSIndexPath indexPathWithIndex:1]], @2);
    XCTAssertEqualObjects([staticValues objectAtIndexPath:[NSIndexPath indexPathWithIndex:2]], @3);
    RZAssemblage *mutableValues = [RZAssemblage assemblageForArray:@[]];
    XCTAssertEqual([mutableValues children].count, 0);

    RZAssemblage *sectioned = [RZAssemblage assemblageForArray:@[staticValues, mutableValues]];

    XCTAssertEqual([sectioned children].count, 2);
    XCTAssertEqual([sectioned assemblageAtIndexPath:[NSIndexPath indexPathWithIndex:0]].children.count, 3);
    XCTAssertEqual([sectioned assemblageAtIndexPath:[NSIndexPath indexPathWithIndex:1]].children.count, 0);
}

- (void)testMutableDelegation
{
    RZAssemblage *mutableAssemblage = [RZAssemblage assemblageForArray:@[]];
    mutableAssemblage.delegate = self;

    NSMutableArray *mutableValues = [mutableAssemblage mutableChildren];
    [mutableValues addObject:@1];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.type, RZAssemblageMutationTypeInsert);
    [self.delegateEvents removeAllObjects];

    [mutableValues removeLastObject];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.type, RZAssemblageMutationTypeRemove);
    [self.delegateEvents removeAllObjects];

    [mutableValues insertObject:@2 atIndex:0];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.type, RZAssemblageMutationTypeInsert);
    [self.delegateEvents removeAllObjects];

    [mutableValues removeObjectAtIndex:0];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.type, RZAssemblageMutationTypeRemove);
    [self.delegateEvents removeAllObjects];

    [mutableValues insertObject:@2 atIndex:0];
    [mutableValues insertObject:@1 atIndex:0];
    XCTAssert(self.delegateEvents.count == 2);
    [self.delegateEvents removeAllObjects];

}

- (void)testGroupedMutableDelegationNoOp
{
    RZAssemblage *mutableAssemblage = [RZAssemblage assemblageForArray:@[]];
    mutableAssemblage.delegate = self;

    NSMutableArray *mutableValues = [mutableAssemblage mutableChildren];
    [mutableAssemblage openBatchUpdate];

    [mutableValues addObject:@1];
    [mutableValues removeLastObject];
    [mutableValues insertObject:@2 atIndex:0];
    [mutableValues removeObjectAtIndex:0];
    [mutableAssemblage closeBatchUpdate];
    XCTAssert(self.delegateEvents.count == 0);
}

- (void)testJoinDelegation
{
    RZAssemblage *m1 = [RZAssemblage assemblageForArray:@[]];
    RZAssemblage *m2 = [RZAssemblage assemblageForArray:@[]];
    RZAssemblage *m3 = [RZAssemblage assemblageForArray:@[]];
    NSArray *assemblages = @[m1, m2, m3];
    RZAssemblage *assemblage = [RZAssemblage joinedAssemblages:@[m1, m2, m3]];
    assemblage.delegate = self;

    [assemblage openBatchUpdate];
    for ( RZAssemblage *assemblage in assemblages ) {
        NSMutableArray *ma = [assemblage mutableChildren];
        [ma addObject:@1];
        [ma removeLastObject];
    }
    [assemblage closeBatchUpdate];
    XCTAssert(self.delegateEvents.count == 0);
    [self.delegateEvents removeAllObjects];

    [assemblage openBatchUpdate];
    for ( RZAssemblage *assemblage in assemblages ) {
        NSMutableArray *ma = [assemblage mutableChildren];
        [ma addObject:@1];
    }
    [assemblage closeBatchUpdate];

    XCTAssert(self.delegateEvents.count == 3);
    [self.delegateEvents removeAllObjects];

}

- (void)testJoinIndexPathMutation
{
    RZAssemblage *m1 = [RZAssemblage assemblageForArray:@[]];
    RZAssemblage *j1m1 = [RZAssemblage assemblageForArray:@[]];
    RZAssemblage *j1m2 = [RZAssemblage assemblageForArray:@[]];
    RZAssemblage *j1 = [RZAssemblage joinedAssemblages:@[j1m1, j1m2]];
    RZAssemblage *assemblage = [RZAssemblage assemblageForArray:@[m1, j1]];
    assemblage.delegate = self;

    for ( RZAssemblage *assemblage in @[m1, j1m1] ) {
        NSMutableArray *ma = [assemblage mutableChildren];
        [ma addObject:@1];
        [ma addObject:@2];
        [ma addObject:@3];
    }
    [assemblage removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [assemblage removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    XCTAssertTrue([m1 children].count == 2);
    XCTAssertTrue([j1 children].count == 2);
    XCTAssertTrue([j1m1 children].count == 2);
    XCTAssertTrue([j1m2 children].count == 0);

    [assemblage moveObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                          toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];

    XCTAssertTrue([m1 children].count == 1);
    XCTAssertTrue([j1 children].count == 3);
    XCTAssertTrue([j1m1 children].count == 3);
    XCTAssertTrue([j1m2 children].count == 0);

    [[j1m2 mutableChildren] addObject:@4];
    XCTAssertTrue([m1 children].count == 1);
    XCTAssertTrue([j1 children].count == 4);
    XCTAssertTrue([j1m1 children].count == 3);
    XCTAssertTrue([j1m2 children].count == 1);

    [assemblage insertObject:@5 atIndexPath:[NSIndexPath indexPathForRow:4 inSection:1]];
    XCTAssertTrue([m1 children].count == 1);
    XCTAssertTrue([j1 children].count == 5);
    XCTAssertTrue([j1m1 children].count == 3);
    XCTAssertTrue([j1m2 children].count == 2);

    [assemblage moveObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]
                          toIndexPath:[NSIndexPath indexPathForRow:4 inSection:1]];
    XCTAssertTrue([m1 children].count == 1);
    XCTAssertTrue([j1 children].count == 5);
    XCTAssertTrue([j1m1 children].count == 2);
    XCTAssertTrue([j1m2 children].count == 3);
    NSMutableArray *proxy = [j1m1 mutableChildren];
    [proxy removeObjectAtIndex:0];
    [proxy removeObjectAtIndex:0];
    XCTAssertTrue([m1 children].count == 1);
    XCTAssertTrue([j1 children].count == 3);
    XCTAssertTrue([j1m1 children].count == 0);
    XCTAssertTrue([j1m2 children].count == 3);

    // The first composed assemblage is empty, and we are removing from the head.
    // Ensure that this results in a removal from f1m2, not a index-violation on f1m1
    [assemblage removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
     XCTAssertTrue([m1 children].count == 1);
     XCTAssertTrue([j1 children].count == 2);
     XCTAssertTrue([j1m1 children].count == 0);
     XCTAssertTrue([j1m2 children].count == 2);
}

- (void)testNestedGroupedMutableDelegation
{
    RZAssemblage *parent = [RZAssemblage assemblageForArray:@[]];
    NSMutableArray *parentproxy = [parent mutableChildren];
    [parentproxy addObject:[RZAssemblage assemblageForArray:@[]]];
    RZAssemblage *mutableValues = [RZAssemblage assemblageForArray:@[]];
    [parentproxy addObject:mutableValues];

    parent.delegate = self;
    [parent openBatchUpdate];
    NSMutableArray *proxy = [mutableValues mutableChildren];
    [proxy addObject:@1];
    [proxy removeLastObject];
    [proxy insertObject:@2 atIndex:0];
    [proxy removeObjectAtIndex:0];
    [proxy insertObject:@2 atIndex:0];
    [proxy insertObject:@1 atIndex:0];
    [parent closeBatchUpdate];
    XCTAssert(self.delegateEvents.count == 2);
    [self.delegateEvents removeAllObjects];

    [parentproxy addObject:[RZAssemblage assemblageForArray:@[@"Only the assemblage is notified"]]];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.type, RZAssemblageMutationTypeInsert);
    XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:2]);
    [self.delegateEvents removeAllObjects];
}

- (void)testFilterNumericA
{
    RZAssemblage *m1 = [RZAssemblage assemblageForArray:@[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12]];
#define START_STOP_EVENT_COUNT 2
#define CHILD_COUNT 12
#define EVEN_CHILD_COUNT 12 / 2
#define THIRD_CHILD_COUNT 12 / 3

    RZFilterAssemblage *f1 = [[RZFilterAssemblage alloc] initWithAssemblage:m1];

    NSMutableArray *f1proxy = [f1 mutableChildren];
    f1.delegate = self;
    XCTAssertEqual([f1 children].count, CHILD_COUNT);
    f1.filter = [NSPredicate predicateWithBlock:^BOOL(NSNumber *n, NSDictionary *bindings) {
        return [n unsignedIntegerValue] % 2 == 0;
    }];
    XCTAssertEqual([f1 children].count, EVEN_CHILD_COUNT);
    XCTAssert(self.delegateEvents.count == EVEN_CHILD_COUNT);
    for ( NSUInteger i = 0; i < EVEN_CHILD_COUNT; i++ ) {
        RZAssemblageDelegateEvent *ev = self.delegateEvents[i];
        XCTAssertEqual(ev.type, RZAssemblageMutationTypeRemove);
    }
    [self.delegateEvents removeAllObjects];


    f1.filter = [NSPredicate predicateWithBlock:^BOOL(NSNumber *n, NSDictionary *bindings) {
        return [n unsignedIntegerValue] % 3 == 0;
    }];
    XCTAssert([[f1proxy objectAtIndex:0] integerValue] == 3);
    XCTAssert([[f1proxy objectAtIndex:1] integerValue] == 6);
    XCTAssert([[f1proxy objectAtIndex:2] integerValue] == 9);
    XCTAssert([[f1proxy objectAtIndex:3] integerValue] == 12);

    XCTAssertEqual([f1 children].count, THIRD_CHILD_COUNT);

    [self.delegateEvents removeAllObjects];
}

- (void)testFilterUpdate
{
    RZAssemblage *m1 = [RZAssemblage assemblageForArray:@[@1, @2, @3, @4, @5]];
    RZFilterAssemblage *f1 = [[RZFilterAssemblage alloc] initWithAssemblage:m1];

    f1.delegate = self;
    XCTAssertEqual([f1 children].count, 5);
    XCTAssertEqualObjects([f1 children], (@[@1, @2, @3, @4, @5]));
    f1.filter = [NSPredicate predicateWithBlock:^BOOL(NSNumber *n, NSDictionary *bindings) {
        return [n unsignedIntegerValue] % 2 == 0;
    }];
    XCTAssertEqual([f1 children].count, 2);
    XCTAssertEqualObjects([f1 children], (@[@2, @4]));
    XCTAssertEqual(self.changeSet.removedIndexPaths.count, 3);
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths, (@[[NSIndexPath indexPathWithIndex:0],
                                                               [NSIndexPath indexPathWithIndex:2],
                                                               [NSIndexPath indexPathWithIndex:4]]));
    f1.filter = [NSPredicate predicateWithBlock:^BOOL(NSNumber *n, NSDictionary *bindings) {
        return [n unsignedIntegerValue] % 3 == 0;
    }];
    XCTAssertEqual([f1 children].count, 1);
    XCTAssertEqualObjects([f1 children], (@[@3]));
    XCTAssertEqual(self.changeSet.insertedIndexPaths.count, 1);
    XCTAssertEqual(self.changeSet.removedIndexPaths.count, 2);
    XCTAssertEqualObjects(self.changeSet.insertedIndexPaths, (@[[NSIndexPath indexPathWithIndex:0]]));
    XCTAssertEqualObjects(self.changeSet.removedIndexPaths, (@[[NSIndexPath indexPathWithIndex:0],
                                                               [NSIndexPath indexPathWithIndex:1]]));


}

- (void)testFilteredRealIndex
{
    NSArray *values = [self.class values];
    RZFilterAssemblage *f1 = [[RZFilterAssemblage alloc] initWithAssemblage:[RZAssemblage assemblageForArray:values]];

    NSMutableArray *s1proxy = [f1 mutableChildren];
    f1.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasPrefix:@"b"] == NO;
    }];
    for ( NSUInteger i = 0; i < 6; i++ ) {
        XCTAssert([[s1proxy objectAtIndex:i] hasPrefix:@"a"]);
    }
    for ( NSUInteger i = 6; i < 12; i++ ) {
        XCTAssert([[s1proxy objectAtIndex:i] hasPrefix:@"c"]);
    }
    NSArray *objects = [f1 mutableChildren];
    for ( NSUInteger i = 0; i < [f1 children].count; i++ ) {
        XCTAssertEqual([s1proxy objectAtIndex:i], objects[i]);
    }
    f1.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasSuffix:@"b"] || [s hasSuffix:@"d"] || [s hasSuffix:@"f"];
    }];
    objects = [f1 mutableChildren];
    for ( NSUInteger i = 0; i < [f1 children].count; i++ ) {
        XCTAssertEqual([s1proxy objectAtIndex:i], objects[i]);
    }
}

- (void)testSort
{
    NSArray *values = [self.class values];
    RZAssemblage *a1 = [RZAssemblage assemblageForArray:values];
    a1.delegate = self;

    NSArray *array = [a1 mutableChildren];
    [a1 openBatchUpdate];
    [[a1 mutableChildren] sortUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2) {
        return [[s1 substringFromIndex:1] compare:[s2 substringFromIndex:1]];
    }];
    [a1 closeBatchUpdate];
    NSArray *expected = @[@"aa",@"ba",@"ca",@"da",@"ab",@"bb",@"cb",@"db",@"ac",@"bc",@"cc",@"dc",@"ad",@"bd",@"cd",@"dd",@"ae",@"be",@"ce",@"de",@"af",@"bf",@"cf",@"df"];
    XCTAssertEqualObjects(array, expected);

    XCTAssert(self.changeSet.insertedIndexPaths.count == expected.count);
    XCTAssert(self.changeSet.removedIndexPaths.count == expected.count);
    [self.changeSet generateMoveEventsFromAssemblage:a1];
    XCTAssert(self.changeSet.insertedIndexPaths.count == 0);
    XCTAssert(self.changeSet.removedIndexPaths.count == 0);
    XCTAssert(self.changeSet.moveFromToIndexPaths.count == expected.count);
}

- (void)testFilteredSort
{
    NSArray *values = [self.class values];
    RZAssemblage *a1 = [RZAssemblage assemblageForArray:values];
    RZFilterAssemblage *f1 = [[RZFilterAssemblage alloc] initWithAssemblage:a1];

    f1.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasPrefix:@"b"] == NO;
    }];
    NSArray *array = [f1 mutableChildren];
    f1.delegate = self;
    [a1 openBatchUpdate];
    [[a1 mutableChildren] sortUsingComparator:^NSComparisonResult(NSString *s1, NSString *s2) {
        return [[s1 substringFromIndex:1] compare:[s2 substringFromIndex:1]];
    }];
    [a1 closeBatchUpdate];
    NSArray *filteredArray = [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasPrefix:@"b"];
    }]];
    XCTAssert(filteredArray.count == 0);
    NSArray *expected = @[@"aa",@"ca",@"da",@"ab",@"cb",@"db",@"ac",@"cc",@"dc",@"ad",@"cd",@"dd",@"ae",@"ce",@"de",@"af",@"cf",@"df"];
    XCTAssertEqualObjects(array, expected);
    XCTAssert(self.changeSet.insertedIndexPaths.count == expected.count);
    XCTAssert(self.changeSet.removedIndexPaths.count == expected.count);
    XCTAssert(self.changeSet.moveFromToIndexPaths.count == 0);
    [self.changeSet generateMoveEventsFromAssemblage:f1];
    XCTAssert(self.changeSet.insertedIndexPaths.count == 0);
    XCTAssert(self.changeSet.removedIndexPaths.count == 0);
    XCTAssert(self.changeSet.moveFromToIndexPaths.count == expected.count);

}

- (void)testFilterJoin
{
    NSArray *values = [self.class values];
    NSPredicate *aFilter = [NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasPrefix:@"a"];
    }];
    NSArray *aValues = [values filteredArrayUsingPredicate:aFilter];

    NSArray *assemblages = @[[RZAssemblage assemblageForArray:values],
                             [RZAssemblage assemblageForArray:values],
                             [RZAssemblage assemblageForArray:values],
                             [RZAssemblage assemblageForArray:values]];
    RZAssemblage *j1 = [RZAssemblage joinedAssemblages:assemblages];
    RZFilterAssemblage *f1 = [[RZFilterAssemblage alloc] initWithAssemblage:j1];
    NSMutableArray *f1proxy = [f1 mutableChildren];
    f1.delegate = self;
    XCTAssertEqual([f1 children].count, values.count * assemblages.count);
    f1.filter = aFilter;

    NSUInteger removeInAssemblageCount = (values.count - aValues.count);
    XCTAssertEqual(self.delegateEvents.count, removeInAssemblageCount * assemblages.count);
    XCTAssertEqual([f1 children].count, aValues.count * assemblages.count);
    for ( NSUInteger assemblageIndex = 0; assemblageIndex < assemblages.count; assemblageIndex++ ) {
        for ( NSUInteger i = 0; i < aValues.count; i++ ) {
            NSUInteger indexInAssemblage = i + assemblageIndex * aValues.count;
            XCTAssertEqual([f1proxy objectAtIndex:indexInAssemblage], [aValues objectAtIndex:i]);
        }
        for ( NSUInteger i = 0; i < removeInAssemblageCount; i++ ) {
            NSUInteger eventIndex = i + assemblageIndex * removeInAssemblageCount;
            NSUInteger valueIndex = i + aValues.count;
            RZAssemblageDelegateEvent *event = self.delegateEvents[eventIndex];
            XCTAssertEqual(event.type, RZAssemblageMutationTypeRemove);
            XCTAssertEqual(event.object, values[valueIndex], @"Event at %zd[%@] != %zd[%@] ", eventIndex, event.object, valueIndex, values[valueIndex]);
        }
    }
    [self.delegateEvents removeAllObjects];

    NSPredicate *bFilter = [NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasPrefix:@"b"];
    }];
    NSArray *bValues = [values filteredArrayUsingPredicate:bFilter];

    f1.filter = bFilter;

    for ( NSUInteger assemblageIndex = 0; assemblageIndex < assemblages.count; assemblageIndex++ ) {
        // Ensure all A values were removed
        for ( NSUInteger i = 0; i < aValues.count; i++ ) {
            NSUInteger removeIndex = i + assemblageIndex * aValues.count;
            RZAssemblageDelegateEvent *event = self.delegateEvents[removeIndex];
            XCTAssertEqual(event.object, [aValues objectAtIndex:i]);
            XCTAssertEqual(event.type, RZAssemblageMutationTypeRemove);
        }
    }
    NSUInteger offset = aValues.count * assemblages.count;
    for ( NSUInteger assemblageIndex = 0; assemblageIndex < assemblages.count; assemblageIndex++ ) {
        // Ensure all B values were added.
        for ( NSUInteger i = 0; i < bValues.count; i++ ) {
            NSUInteger indexInAssemblage = i + assemblageIndex * bValues.count;
            RZAssemblageDelegateEvent *event = self.delegateEvents[i + offset];
            XCTAssertEqual([f1proxy objectAtIndex:indexInAssemblage], [bValues objectAtIndex:i]);
            XCTAssertEqual(event.type, RZAssemblageMutationTypeInsert);
        }
    }

    [self.delegateEvents removeAllObjects];
}

- (void)testFilteredRemoval
{
    RZAssemblage *m = [RZAssemblage assemblageForArray:@[@"7", @"8", @"9", @"10", @"11", @"12"]];
    NSMutableArray *mproxy = [m mutableChildren];
    RZFilterAssemblage *filtered = [[RZFilterAssemblage alloc] initWithAssemblage:m];
    NSMutableArray *filteredproxy = [filtered mutableChildren];

    filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *numberString, NSDictionary *bindings) {
        return [numberString integerValue] % 2;
    }];
    filtered.delegate = self;

    XCTAssert([filtered children].count == 3);
    [mproxy removeObjectAtIndex:2]; // 9
    XCTAssert([filtered children].count == 2);
    XCTAssert([[filteredproxy objectAtIndex:0] isEqual:@"7"]);
    XCTAssert([[filteredproxy objectAtIndex:1] isEqual:@"11"]);
}

- (void)testFilteredAddition
{
    RZAssemblage *m = [RZAssemblage assemblageForArray:@[]];
    NSMutableArray *mproxy = [m mutableChildren];
    RZFilterAssemblage *filtered = [[RZFilterAssemblage alloc] initWithAssemblage:m];

    filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *numberString, NSDictionary *bindings) {
        return [numberString integerValue] % 2;
    }];

    XCTAssert([filtered children].count == 0);
    for ( NSUInteger i = 0; i < 5; i++ ) {
        [mproxy addObject:@(i)];
    }
    XCTAssert([filtered children].count == 2);
    for ( NSUInteger i = 0; i < 5; i++ ) {
        [mproxy addObject:@(i)];
    }
    XCTAssert([filtered children].count == 4);

    [m openBatchUpdate];
    [mproxy removeAllObjects];
    [m closeBatchUpdate];

    XCTAssert([filtered children].count == 0);
}

- (void)testMutation
{
    RZAssemblage *m1 = [RZAssemblage assemblageForArray:@[@"1", @"2", @"3", ]];
    RZAssemblage *m2 = [RZAssemblage assemblageForArray:@[@"4", @"5", @"6", ]];
    RZAssemblage *m3 = [RZAssemblage assemblageForArray:@[@"7", @"8", @"9", ]];
    RZAssemblage *m4 = [RZAssemblage assemblageForArray:@[@"10", @"11", @"12", ]];
    RZAssemblage *j1 = [RZAssemblage joinedAssemblages:@[m3, m4]];
    RZFilterAssemblage *filtered = [[RZFilterAssemblage alloc] initWithAssemblage:j1];

    NSMutableArray *filteredproxy = [filtered mutableChildren];

    filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *numberString, NSDictionary *bindings) {
        return [numberString integerValue] % 2;
    }];
    RZAssemblage *assemblage = [RZAssemblage assemblageForArray:@[m1, m2, filtered]];

    assemblage.delegate = self;

    [assemblage removeObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

    // This is @ 2:2
    [[m3 mutableChildren] addObject:@"9"];
    XCTAssert([[filteredproxy objectAtIndex:2] isEqualToString:@"9"]);
    [self.delegateEvents removeAllObjects];
    id obj = [assemblage objectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
    [assemblage moveObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]
                          toIndexPath:[NSIndexPath indexPathForRow:3 inSection:2]];
    XCTAssertEqual(obj, [assemblage objectAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:2]]);
}

- (void)testFilterRemoval
{
    RZAssemblage *m1 = [RZAssemblage assemblageForArray:@[@"1", @"2", @"3", @"4", @"5", @"6"]];
    RZFilterAssemblage *filtered = [[RZFilterAssemblage alloc] initWithAssemblage:m1];
    NSMutableArray *filteredproxy = [filtered mutableChildren];
    filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *numberString, NSDictionary *bindings) {
        return [numberString integerValue] % 2;
    }];
    filtered.delegate = self;

    XCTAssert([filtered children].count == 3);
    for ( NSUInteger i = 0; i < 3; i++ ) {
        XCTAssert([[filteredproxy objectAtIndex:i] integerValue] % 2 == 1);
    }
    NSMutableArray *m1proxy = [m1 mutableChildren];
    [m1proxy removeObjectAtIndex:1];
    XCTAssert([filtered children].count == 3);
    for ( NSUInteger i = 0; i < 3; i++ ) {
        XCTAssert([[filteredproxy objectAtIndex:i] integerValue] % 2 == 1);
    }
    XCTAssert(self.delegateEvents.count == 0);

    [m1proxy removeObjectAtIndex:2];
    XCTAssert([filtered children].count == 3);
    for ( NSUInteger i = 0; i < 3; i++ ) {
        XCTAssert([[filteredproxy objectAtIndex:i] integerValue] % 2 == 1);
    }
    XCTAssert(self.delegateEvents.count == 0);

    [m1proxy removeObjectAtIndex:3];
    XCTAssert([filtered children].count == 3);
    for ( NSUInteger i = 0; i < 3; i++ ) {
        XCTAssert([[filteredproxy objectAtIndex:i] integerValue] % 2 == 1);
    }
    XCTAssert(self.delegateEvents.count == 0);
}

- (void)testMoveWithIndexConcerns1
{
    RZAssemblage *m1 = [RZAssemblage assemblageForArray:@[@"1", @"2", @"3", @"4"]];
    NSMutableArray *m1proxy = [m1 mutableChildren];

    m1.delegate = self;
    [m1 openBatchUpdate];
    [m1proxy removeObjectAtIndex:0];
    [m1proxy removeObjectAtIndex:0];
    [m1proxy addObject:@"2"];
    [m1proxy removeObjectAtIndex:0];
    [m1 closeBatchUpdate];
    [self.changeSet generateMoveEventsFromAssemblage:m1];
}

- (void)testMoveWithIndexConcerns2
{
    RZAssemblage *m1 = [RZAssemblage assemblageForArray:@[@"1", @"2", @"3"]];
    NSMutableArray *m1proxy = [m1 mutableChildren];

    m1.delegate = self;
    [m1 openBatchUpdate];
    [m1proxy removeObjectAtIndex:0];
    [m1proxy removeObjectAtIndex:0];
    [m1proxy addObject:@"2"];
    [m1 closeBatchUpdate];
    [self.changeSet generateMoveEventsFromAssemblage:m1];
}

- (void)testBatchingA
{
    RZAssemblage *m1 = [RZAssemblage assemblageForArray:@[]];
    NSMutableArray *m1proxy = [m1 mutableChildren];
    m1.delegate = self;
    [m1 openBatchUpdate];
    [m1proxy addObject:@"2"];
    [m1proxy addObject:@"2"];
    [m1proxy removeObjectAtIndex:0];
    [m1proxy removeObjectAtIndex:0];
    [m1 closeBatchUpdate];
    [self.changeSet generateMoveEventsFromAssemblage:m1];
}

@end
