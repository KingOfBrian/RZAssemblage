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
#import "RZMutableAssemblage.h"
#import "RZJoinAssemblage.h"
#import "RZFilteredAssemblage.h"
#import "RZAssemblageChangeSet.h"
#import "RZMutableIndexPathSet.h"
#import "NSIndexPath+RZAssemblage.h"

#define TRACE_DELEGATE_EVENT \
RZAssemblageDelegateEvent *event = [[RZAssemblageDelegateEvent alloc] init]; \
[self.delegateEvents addObject:event]; \
event.delegateSelector = _cmd;\
event.assemblage = assemblage;


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

@end

@implementation RZAssemblageTests

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
    TRACE_DELEGATE_EVENT
}

- (void)assemblage:(id<RZAssemblage>)assemblage didChange:(RZAssemblageChangeSet *)changeSet
{
    [changeSet.removes enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        TRACE_DELEGATE_EVENT
        event.type = RZAssemblageMutationTypeRemove;
        event.object = [changeSet.startingAssemblage objectAtIndexPath:indexPath];
        event.indexPath = indexPath;
    }];
    [changeSet.inserts enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        TRACE_DELEGATE_EVENT
        event.type = RZAssemblageMutationTypeInsert;
        event.object = [assemblage objectAtIndexPath:indexPath];
        event.indexPath = indexPath;
    }];
    [changeSet.updates enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        TRACE_DELEGATE_EVENT
        event.type = RZAssemblageMutationTypeUpdate;
        event.object = [assemblage objectAtIndexPath:indexPath];
        event.indexPath = indexPath;
    }];
    [changeSet.moves enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        TRACE_DELEGATE_EVENT
        event.type = RZAssemblageMutationTypeMove;
        event.object = [assemblage objectAtIndexPath:indexPath];
        event.indexPath = indexPath;
    }];
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

- (void)testMutableDelegation
{
    RZMutableAssemblage *mutableValues = [[RZMutableAssemblage alloc] initWithArray:@[]];
    mutableValues.delegate = self;

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
    RZMutableAssemblage *mutableValues = [[RZMutableAssemblage alloc] initWithArray:@[]];
    mutableValues.delegate = self;
    [mutableValues beginUpdates];

    [mutableValues addObject:@1];
    [mutableValues removeLastObject];
    [mutableValues insertObject:@2 atIndex:0];
    [mutableValues removeObjectAtIndex:0];
    [mutableValues endUpdates];
    XCTAssert(self.delegateEvents.count == 0);
}

- (void)testJoinDelegation
{
    RZMutableAssemblage *m1 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZMutableAssemblage *m2 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZMutableAssemblage *m3 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    NSArray *assemblages = @[m1, m2, m3];
    RZJoinAssemblage *assemblage = [[RZJoinAssemblage alloc] initWithArray:@[m1, m2, m3]];
    assemblage.delegate = self;

    [assemblage beginUpdates];
    for ( RZMutableAssemblage *ma in assemblages ) {
        [ma addObject:@1];
        [ma removeLastObject];
    }
    [assemblage endUpdates];
    XCTAssert(self.delegateEvents.count == 0);
    [self.delegateEvents removeAllObjects];

    [assemblage beginUpdates];
    for ( RZMutableAssemblage *ma in assemblages ) {
        [ma addObject:@1];
    }
    [assemblage endUpdates];

    XCTAssert(self.delegateEvents.count == 3);
    [self.delegateEvents removeAllObjects];

}

- (void)testJoinIndexPathMutation
{
    RZMutableAssemblage *m1 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZMutableAssemblage *f1m1 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZMutableAssemblage *f1m2 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZJoinAssemblage *f1 = [[RZJoinAssemblage alloc] initWithArray:@[f1m1, f1m2]];
    RZMutableAssemblage *assemblage = [[RZMutableAssemblage alloc] initWithArray:@[m1, f1]];
    assemblage.delegate = self;

    for ( RZMutableAssemblage *ma in @[m1, f1m1] ) {
        [ma addObject:@1];
        [ma addObject:@2];
        [ma addObject:@3];
    }

    [assemblage removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [assemblage removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    XCTAssertTrue([m1 numberOfChildren] == 2);
    XCTAssertTrue([f1 numberOfChildren] == 2);
    XCTAssertTrue([f1m1 numberOfChildren] == 2);
    XCTAssertTrue([f1m2 numberOfChildren] == 0);

    [assemblage moveObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                          toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];

    XCTAssertTrue([m1 numberOfChildren] == 1);
    XCTAssertTrue([f1 numberOfChildren] == 3);
    XCTAssertTrue([f1m1 numberOfChildren] == 3);
    XCTAssertTrue([f1m2 numberOfChildren] == 0);

    [f1m2 addObject:@4];
    XCTAssertTrue([m1 numberOfChildren] == 1);
    XCTAssertTrue([f1 numberOfChildren] == 4);
    XCTAssertTrue([f1m1 numberOfChildren] == 3);
    XCTAssertTrue([f1m2 numberOfChildren] == 1);

    [assemblage insertObject:@5 atIndexPath:[NSIndexPath indexPathForRow:4 inSection:1]];
    XCTAssertTrue([m1 numberOfChildren] == 1);
    XCTAssertTrue([f1 numberOfChildren] == 5);
    XCTAssertTrue([f1m1 numberOfChildren] == 3);
    XCTAssertTrue([f1m2 numberOfChildren] == 2);

    [assemblage moveObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]
                          toIndexPath:[NSIndexPath indexPathForRow:4 inSection:1]];
    XCTAssertTrue([m1 numberOfChildren] == 1);
    XCTAssertTrue([f1 numberOfChildren] == 5);
    XCTAssertTrue([f1m1 numberOfChildren] == 2);
    XCTAssertTrue([f1m2 numberOfChildren] == 3);

    [f1m1 removeObjectAtIndex:0];
    [f1m1 removeObjectAtIndex:0];
    XCTAssertTrue([m1 numberOfChildren] == 1);
    XCTAssertTrue([f1 numberOfChildren] == 3);
    XCTAssertTrue([f1m1 numberOfChildren] == 0);
    XCTAssertTrue([f1m2 numberOfChildren] == 3);

    // The first composed assemblage is empty, and we are removing from the head.
    // Ensure that this results in a removal from f1m2, not a index-violation on f1m1
    [assemblage removeObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
     XCTAssertTrue([m1 numberOfChildren] == 1);
     XCTAssertTrue([f1 numberOfChildren] == 2);
     XCTAssertTrue([f1m1 numberOfChildren] == 0);
     XCTAssertTrue([f1m2 numberOfChildren] == 2);
}

- (void)testNestedGroupedMutableDelegation
{
    RZMutableAssemblage *parent = [[RZMutableAssemblage alloc] initWithArray:@[]];
    [parent addObject:[[RZAssemblage alloc] initWithArray:@[]]];
    RZMutableAssemblage *mutableValues = [[RZMutableAssemblage alloc] initWithArray:@[]];
    [parent addObject:mutableValues];

    parent.delegate = self;
    [parent beginUpdates];
    [mutableValues addObject:@1];
    [mutableValues removeLastObject];
    [mutableValues insertObject:@2 atIndex:0];
    [mutableValues removeObjectAtIndex:0];
    [mutableValues insertObject:@2 atIndex:0];
    [mutableValues insertObject:@1 atIndex:0];
    [parent endUpdates];
    XCTAssert(self.delegateEvents.count == 2);
    [self.delegateEvents removeAllObjects];

    [parent addObject:[[RZAssemblage alloc] initWithArray:@[@"Only the assemblage is notified"]]];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.type, RZAssemblageMutationTypeInsert);
    XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:2]);
    [self.delegateEvents removeAllObjects];
}

- (void)testFilterNumericA
{
    RZMutableAssemblage *m1 = [[RZMutableAssemblage alloc] initWithArray:@[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12]];
#define START_STOP_EVENT_COUNT 2
#define CHILD_COUNT 12
#define EVEN_CHILD_COUNT 12 / 2
#define THIRD_CHILD_COUNT 12 / 3

    RZFilteredAssemblage *s1 = [[RZFilteredAssemblage alloc] initWithAssemblage:m1];
    s1.delegate = self;
    [s1 beginUpdates];
    XCTAssertEqual([s1 numberOfChildren], CHILD_COUNT);
    s1.filter = [NSPredicate predicateWithBlock:^BOOL(NSNumber *n, NSDictionary *bindings) {
        return [n unsignedIntegerValue] % 2 == 0;
    }];
    [s1 endUpdates];
    XCTAssertEqual([s1 numberOfChildren], EVEN_CHILD_COUNT);
    XCTAssert(self.delegateEvents.count == EVEN_CHILD_COUNT);
    for ( NSUInteger i = 0; i < EVEN_CHILD_COUNT; i++ ) {
        RZAssemblageDelegateEvent *ev = self.delegateEvents[i];
        XCTAssertEqual(ev.type, RZAssemblageMutationTypeRemove);
    }
    [self.delegateEvents removeAllObjects];


    [s1 beginUpdates];
    s1.filter = [NSPredicate predicateWithBlock:^BOOL(NSNumber *n, NSDictionary *bindings) {
        return [n unsignedIntegerValue] % 3 == 0;
    }];
    [s1 endUpdates];
    XCTAssert([[s1 objectAtIndex:0] integerValue] == 3);
    XCTAssert([[s1 objectAtIndex:1] integerValue] == 6);
    XCTAssert([[s1 objectAtIndex:2] integerValue] == 9);
    XCTAssert([[s1 objectAtIndex:3] integerValue] == 12);

    XCTAssertEqual([s1 numberOfChildren], THIRD_CHILD_COUNT);

    [self.delegateEvents removeAllObjects];
}

- (void)testFilteredRealIndex
{
    NSArray *values = [self.class values];
    RZFilteredAssemblage *s1 = [[RZFilteredAssemblage alloc] initWithAssemblage:[[RZAssemblage alloc] initWithArray:values]];
    s1.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasPrefix:@"b"] == NO;
    }];
    for ( NSUInteger i = 0; i < 6; i++ ) {
        XCTAssert([[s1 objectAtIndex:i] hasPrefix:@"a"]);
    }
    for ( NSUInteger i = 6; i < 12; i++ ) {
        XCTAssert([[s1 objectAtIndex:i] hasPrefix:@"c"]);
    }
    for ( NSUInteger i = 0; i < [s1 numberOfChildren]; i++ ) {
        XCTAssertEqual([s1 objectAtIndex:i], [s1 allObjects][i]);
    }
    s1.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasSuffix:@"b"] || [s hasSuffix:@"d"] || [s hasSuffix:@"f"];
    }];
    for ( NSUInteger i = 0; i < [s1 numberOfChildren]; i++ ) {
        XCTAssertEqual([s1 objectAtIndex:i], [s1 allObjects][i]);
    }
}

- (void)testFilterJoin
{
    NSArray *values = [self.class values];
    NSPredicate *aFilter = [NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasPrefix:@"a"];
    }];
    NSArray *aValues = [values filteredArrayUsingPredicate:aFilter];

    NSArray *assemblages = @[[[RZAssemblage alloc] initWithArray:values],
                             [[RZAssemblage alloc] initWithArray:values],
                             [[RZAssemblage alloc] initWithArray:values],
                             [[RZAssemblage alloc] initWithArray:values]];
    RZJoinAssemblage *f1 = [[RZJoinAssemblage alloc] initWithArray:assemblages];
    RZFilteredAssemblage *s1 = [[RZFilteredAssemblage alloc] initWithAssemblage:f1];
    s1.delegate = self;
    [s1 beginUpdates];
    XCTAssertEqual([s1 numberOfChildren], values.count * assemblages.count);
    s1.filter = aFilter;
    [s1 endUpdates];
    NSUInteger removeInAssemblageCount = (values.count - aValues.count);
    XCTAssertEqual(self.delegateEvents.count, removeInAssemblageCount * assemblages.count);
    XCTAssertEqual([s1 numberOfChildren], aValues.count * assemblages.count);
    for ( NSUInteger assemblageIndex = 0; assemblageIndex < assemblages.count; assemblageIndex++ ) {
        for ( NSUInteger i = 0; i < aValues.count; i++ ) {
            NSUInteger indexInAssemblage = i + assemblageIndex * aValues.count;
            XCTAssertEqual([s1 objectAtIndex:indexInAssemblage], [aValues objectAtIndex:i]);
        }
        for ( NSUInteger i = 0; i < removeInAssemblageCount; i++ ) {
            NSUInteger eventIndex = i + assemblageIndex * removeInAssemblageCount;
            NSUInteger valueIndex = i + aValues.count;
            RZAssemblageDelegateEvent *event = self.delegateEvents[eventIndex];
            XCTAssertEqual(event.type, RZAssemblageMutationTypeRemove);
            XCTAssertEqual(event.object, values[valueIndex]);
        }
    }
    [self.delegateEvents removeAllObjects];

    NSPredicate *bFilter = [NSPredicate predicateWithBlock:^BOOL(NSString *s, NSDictionary *bindings) {
        return [s hasPrefix:@"b"];
    }];
    NSArray *bValues = [values filteredArrayUsingPredicate:bFilter];

    [s1 beginUpdates];
    s1.filter = bFilter;
    [s1 endUpdates];

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
            XCTAssertEqual([s1 objectAtIndex:indexInAssemblage], [bValues objectAtIndex:i]);
            XCTAssertEqual(event.type, RZAssemblageMutationTypeInsert);
        }
    }

    [self.delegateEvents removeAllObjects];
}

- (void)testMutation
{
    RZMutableAssemblage *m1 = [[RZMutableAssemblage alloc] initWithArray:@[@"1", @"2", @"3", ]];
    RZMutableAssemblage *m2 = [[RZMutableAssemblage alloc] initWithArray:@[@"4", @"5", @"6", ]];
    RZMutableAssemblage *m3 = [[RZMutableAssemblage alloc] initWithArray:@[@"7", @"8", @"9", ]];
    RZMutableAssemblage *m4 = [[RZMutableAssemblage alloc] initWithArray:@[@"10", @"11", @"12", ]];
    RZJoinAssemblage *f1 = [[RZJoinAssemblage alloc] initWithArray:@[m3, m4]];
    RZFilteredAssemblage *filtered = [[RZFilteredAssemblage alloc] initWithAssemblage:f1];
    filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *numberString, NSDictionary *bindings) {
        return [numberString integerValue] % 2;
    }];
    RZMutableAssemblage *assemblage = [[RZMutableAssemblage alloc] initWithArray:@[m1, m2, filtered]];

    assemblage.delegate = self;

    [assemblage removeObjectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

}

@end
