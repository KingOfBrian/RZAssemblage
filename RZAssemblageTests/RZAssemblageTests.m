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

    [mutableValues exchangeObjectAtIndex:0 withObjectAtIndex:1];
    XCTAssert(self.delegateEvents.count == 3);
    XCTAssertEqual(self.secondEvent.delegateSelector, @selector(assemblage:didMoveObject:fromIndexPath:toIndexPath:));
    XCTAssertEqualObjects(self.secondEvent.object, @1);
    XCTAssertEqualObjects(self.secondEvent.indexPath, [NSIndexPath indexPathWithIndex:0]);
    XCTAssertEqualObjects(self.secondEvent.toIndexPath, [NSIndexPath indexPathWithIndex:1]);
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

    [mutableValues exchangeObjectAtIndex:0 withObjectAtIndex:1];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didMoveObject:fromIndexPath:toIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.object, @1);
    XCTAssertEqualObjects(self.firstEvent.indexPath, [NSIndexPath indexPathWithIndex:0]);
    XCTAssertEqualObjects(self.firstEvent.toIndexPath, [NSIndexPath indexPathWithIndex:1]);
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

- (void)testNestedGroupedMutableDelegation
{
    const NSUInteger firstPath[2] = {1, 0};
    const NSUInteger secondPath[2] = {1, 1};
    NSIndexPath *firstIndexPath = [NSIndexPath indexPathWithIndexes:firstPath length:2];
    NSIndexPath *secondIndexPath = [NSIndexPath indexPathWithIndexes:secondPath length:2];
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

    [mutableValues exchangeObjectAtIndex:0 withObjectAtIndex:1];
    XCTAssert(self.delegateEvents.count == 1);
    XCTAssertEqual(self.firstEvent.delegateSelector, @selector(assemblage:didMoveObject:fromIndexPath:toIndexPath:));
    XCTAssertEqualObjects(self.firstEvent.object, @1);
    XCTAssertEqualObjects(self.firstEvent.indexPath, firstIndexPath);
    XCTAssertEqualObjects(self.firstEvent.toIndexPath, secondIndexPath);
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

@end
