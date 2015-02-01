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
#import "RZFlatAssemblage.h"
#import "RZFilteredAssemblage.h"

#define TRACE_DELEGATE_EVENT \
RZAssemblageDelegateEvent *event = [[RZAssemblageDelegateEvent alloc] init]; \
[self.delegateEvents addObject:event]; \
event.assemblage = assemblage; \
event.delegateSelector = _cmd; \


@interface RZAssemblageDelegateEvent : NSObject

@property (strong, nonatomic) RZAssemblage *assemblage;
@property (assign, nonatomic) SEL delegateSelector;
@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) NSIndexPath *toIndexPath;

@end

@implementation RZAssemblageDelegateEvent

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@, %p %@ %@ %@ %@>", [super description], self.assemblage, NSStringFromSelector(self.delegateSelector), self.object, self.indexPath, self.toIndexPath ? self.toIndexPath : @""];
}

@end

@interface RZAssemblageTests : XCTestCase <RZAssemblageDelegate>

@property (nonatomic, strong) NSMutableArray *delegateEvents;

@end

@implementation RZAssemblageTests

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

- (void)assemblage:(RZAssemblage *)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    TRACE_DELEGATE_EVENT
    event.object = object;
    event.indexPath = indexPath;
}

- (void)assemblage:(RZAssemblage *)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    TRACE_DELEGATE_EVENT
    event.object = object;
    event.indexPath = indexPath;
}

- (void)assemblage:(RZAssemblage *)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    TRACE_DELEGATE_EVENT
    event.object = object;
    event.indexPath = indexPath;
}

- (void)assemblage:(RZAssemblage *)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    TRACE_DELEGATE_EVENT
    event.object = object;
    event.indexPath = fromIndexPath;
    event.toIndexPath = toIndexPath;
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
    XCTAssert(self.delegateEvents.count == 3);
    XCTAssertEqual(self.secondEvent.delegateSelector, @selector(assemblage:didInsertObject:atIndexPath:));
    [self.delegateEvents removeAllObjects];

    [mutableValues removeLastObject];
    XCTAssert(self.delegateEvents.count == 3);
    XCTAssertEqual(self.secondEvent.delegateSelector, @selector(assemblage:didRemoveObject:atIndexPath:));
    [self.delegateEvents removeAllObjects];

    [mutableValues insertObject:@2 atIndex:0];
    XCTAssert(self.delegateEvents.count == 3);
    XCTAssertEqual(self.secondEvent.delegateSelector, @selector(assemblage:didInsertObject:atIndexPath:));
    [self.delegateEvents removeAllObjects];

    [mutableValues removeObjectAtIndex:0];
    XCTAssert(self.delegateEvents.count == 3);
    XCTAssertEqual(self.secondEvent.delegateSelector, @selector(assemblage:didRemoveObject:atIndexPath:));
    [self.delegateEvents removeAllObjects];

    [mutableValues insertObject:@2 atIndex:0];
    [mutableValues insertObject:@1 atIndex:0];
    XCTAssert(self.delegateEvents.count == 6);
    [self.delegateEvents removeAllObjects];

}

- (void)testGroupedMutableDelegation
{
    RZMutableAssemblage *mutableValues = [[RZMutableAssemblage alloc] initWithArray:@[]];
    mutableValues.delegate = self;
    [mutableValues beginUpdates];
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(willBeginUpdatesForAssemblage:));
    [self.delegateEvents removeAllObjects];

    [mutableValues addObject:@1];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didInsertObject:atIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:0]);
    [self.delegateEvents removeAllObjects];

    [mutableValues removeLastObject];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didRemoveObject:atIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:0]);
    [self.delegateEvents removeAllObjects];

    [mutableValues insertObject:@2 atIndex:0];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didInsertObject:atIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:0]);
    [self.delegateEvents removeAllObjects];

    [mutableValues removeObjectAtIndex:0];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didRemoveObject:atIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:0]);
    [self.delegateEvents removeAllObjects];

    [mutableValues insertObject:@2 atIndex:0];
    [mutableValues insertObject:@1 atIndex:0];
    XCTAssert(self.delegateEvents.count == 2);
    [self.delegateEvents removeAllObjects];


    [mutableValues endUpdates];
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(didEndUpdatesForEnsemble:));
    [self.delegateEvents removeAllObjects];
}

- (void)testFlatDelegation
{
    RZMutableAssemblage *m1 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZMutableAssemblage *m2 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZMutableAssemblage *m3 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    NSArray *assemblages = @[m1, m2, m3];
    RZFlatAssemblage *assemblage = [[RZFlatAssemblage alloc] initWithArray:@[m1, m2, m3]];
    assemblage.delegate = self;

    [assemblage beginUpdates];
    [self.delegateEvents removeAllObjects];

    for ( RZMutableAssemblage *ma in assemblages ) {
        [ma addObject:@1];
        XCTAssert(self.delegateEvents.count == 1);
        XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didInsertObject:atIndexPath:));
        XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:0]);
        [self.delegateEvents removeAllObjects];

        [ma removeLastObject];
        XCTAssert(self.delegateEvents.count == 1);
        XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didRemoveObject:atIndexPath:));
        XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:0]);
        [self.delegateEvents removeAllObjects];
    }

    for ( RZMutableAssemblage *ma in assemblages ) {
        [ma addObject:@1];
        XCTAssert(self.delegateEvents.count == 1);
        XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didInsertObject:atIndexPath:));
        XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:[assemblages indexOfObject:ma]]);
        [self.delegateEvents removeAllObjects];
    }

    [assemblage endUpdates];
}

- (void)testFlatIndexPathMutation
{
    RZMutableAssemblage *m1 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZMutableAssemblage *f1m1 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZMutableAssemblage *f1m2 = [[RZMutableAssemblage alloc] initWithArray:@[]];
    RZFlatAssemblage *f1 = [[RZFlatAssemblage alloc] initWithArray:@[f1m1, f1m2]];
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
    NSIndexPath *firstIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    RZMutableAssemblage *parent = [[RZMutableAssemblage alloc] initWithArray:@[]];
    parent.delegate = self;
    [parent addObject:[[RZAssemblage alloc] initWithArray:@[]]];


    RZMutableAssemblage *mutableValues = [[RZMutableAssemblage alloc] initWithArray:@[]];
    [parent addObject:mutableValues];

    [mutableValues beginUpdates];
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(willBeginUpdatesForAssemblage:));
    [self.delegateEvents removeAllObjects];

    [mutableValues addObject:@1];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didInsertObject:atIndexPath:));

    XCTAssertEqualObjects(self.firstEvent.indexPath, firstIndexPath);
    [self.delegateEvents removeAllObjects];

    [mutableValues removeLastObject];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didRemoveObject:atIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.indexPath, firstIndexPath);
    [self.delegateEvents removeAllObjects];

    [mutableValues insertObject:@2 atIndex:0];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didInsertObject:atIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.indexPath, firstIndexPath);
    [self.delegateEvents removeAllObjects];

    [mutableValues removeObjectAtIndex:0];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didRemoveObject:atIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.indexPath, firstIndexPath);
    [self.delegateEvents removeAllObjects];

    [mutableValues insertObject:@2 atIndex:0];
    [mutableValues insertObject:@1 atIndex:0];
    XCTAssert(self.delegateEvents.count == 2);
    [self.delegateEvents removeAllObjects];

    [parent addObject:[[RZAssemblage alloc] initWithArray:@[@"Only the assemblage is notified"]]];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didInsertObject:atIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:2]);
    [self.delegateEvents removeAllObjects];

    [mutableValues endUpdates];
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(didEndUpdatesForEnsemble:));
    [self.delegateEvents removeAllObjects];
}

- (void)testSorting
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
    XCTAssert(self.delegateEvents.count == START_STOP_EVENT_COUNT + EVEN_CHILD_COUNT);
    for ( NSUInteger i = 1; i <= EVEN_CHILD_COUNT; i++ ) {
        XCTAssertEqual([[self.delegateEvents objectAtIndex:i] delegateSelector],
                       @selector(assemblage:didRemoveObject:atIndexPath:));
    }
    [self.delegateEvents removeAllObjects];


    [s1 beginUpdates];
    s1.filter = [NSPredicate predicateWithBlock:^BOOL(NSNumber *n, NSDictionary *bindings) {
        return [n unsignedIntegerValue] % 3 == 0;
    }];
    [s1 endUpdates];

    XCTAssertEqual([s1 numberOfChildren], THIRD_CHILD_COUNT);

    [self.delegateEvents removeAllObjects];
}

@end
