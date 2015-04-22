//
//  RZFRCTests.m
//  RZTree
//
//  Created by Brian King on 4/18/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@import RZAssemblage;

#import "RZAssemblageTestData.h"
#import "NSIndexPath+RZAssemblage.h"

@interface RZFRCTests : XCTestCase<RZTreeObserver>

@property (nonatomic, strong) RZChangeSet *changeSet;

@end

@implementation RZFRCTests

- (void)node:(RZTree *)node didEndUpdatesWithChangeSet:(RZChangeSet *)changeSet;
{
    self.changeSet = changeSet;
}

- (void)setUp
{
    [super setUp];
    [[RZAssemblageTestData shared] reset];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)ensureChangeSetChangesAreSequential
{
    // Ensure that all of the index paths are sequental
    NSIndexPath *indexPathCursor = [NSIndexPath indexPathWithIndex:0];
    for ( NSIndexPath *indexPath in self.changeSet.insertedIndexPaths ) {
        for ( NSUInteger depth = 0; depth < indexPath.length; depth++ ) {
            if ( indexPathCursor.length <= depth ) {
                indexPathCursor = [indexPathCursor indexPathByAddingIndex:0];
            }
            NSUInteger cursor = [indexPathCursor indexAtPosition:depth];
            NSUInteger index = [indexPath indexAtPosition:depth];
            XCTAssert(index == cursor || index == cursor + 1 || index == 0);
            indexPathCursor = [indexPathCursor rz_indexPathByReplacingIndexAtPosition:depth withIndex:index];
        }
    }
}

- (void)ensureRowsBeginWithJFor:(RZTree *)node
{
    for ( NSIndexPath *indexPath in self.changeSet.insertedIndexPaths ) {
        if ( indexPath.length == 2 ) {
            id object = node[indexPath];
            if ( [object isKindOfClass:[Person class]] ) {
                Person *p = (id)object;
                XCTAssert([p.firstName hasPrefix:@"J"] || [p.lastName hasPrefix:@"J"]);
            }
            else if ( [object isKindOfClass:[NSString class]] ) {
                XCTAssert([object hasPrefix:@"J"]);
            }
        }
    }
}

- (void)testStartupInsertIsSequential
{
    NSFetchedResultsController *frc = [[RZAssemblageTestData shared] frcForPersonsByTeam];
    RZTree *content = [RZTree nodeForFetchedResultsController:frc];
    [content addObserver:self];
    NSError *error = nil;
    [frc performFetch:&error];
    NSAssert(error == nil, @"");

    XCTAssert([[content children] count] == 0);
    [[RZAssemblageTestData shared] createFakeData];
    [[RZAssemblageTestData shared] saveContext];
    XCTAssert([[content children] count] == 4);

    [self ensureChangeSetChangesAreSequential];
}

- (void)testStartupInsertFilter
{
    NSFetchedResultsController *frc = [[RZAssemblageTestData shared] frcForPersonsByTeam];
    RZTree *content = [RZTree nodeForFetchedResultsController:frc];
    RZTree<RZFilterableTree> *filter = [RZTree filterableNodeWithNode:content];
    [filter addObserver:self];
    filter.filter = [NSPredicate predicateWithBlock:^BOOL(Person *person, NSDictionary *bindings) {
        BOOL match = YES;
        if ( [person isKindOfClass:[Person class]] ) {
            match = [person.firstName hasPrefix:@"J"] || [person.lastName hasPrefix:@"J"];
        }
        return match;
    }];
    NSError *error = nil;
    [frc performFetch:&error];
    NSAssert(error == nil, @"");

    XCTAssert([[content children] count] == 0);
    [[RZAssemblageTestData shared] createFakeData];
    [[RZAssemblageTestData shared] saveContext];
    XCTAssert([[content children] count] == 4);

    [self ensureChangeSetChangesAreSequential];
    [self ensureRowsBeginWithJFor:filter];
}

- (void)testFRCSectionJoin
{
    NSFetchedResultsController *frc = [[RZAssemblageTestData shared] frcForPersonsByTeam];
    RZTree *content = [RZTree nodeForFetchedResultsController:frc];
    RZTree *staticSection = [RZTree nodeWithObject:@"static"
                                          children:@[@"This is a static row"]];
    RZTree *combinded = [RZTree nodeWithJoinedNodes:@[content, staticSection]];
    NSError *error = nil;
    [frc performFetch:&error];
    NSAssert(error == nil, @"");

    XCTAssert([[combinded children] count] == 1);
    [[RZAssemblageTestData shared] createFakeData];
    [[RZAssemblageTestData shared] saveContext];
    XCTAssert([[combinded children] count] == 5);

    [self ensureChangeSetChangesAreSequential];
    [self ensureRowsBeginWithJFor:combinded];
}

- (void)testFRCJoinFilter
{
    NSFetchedResultsController *frc = [[RZAssemblageTestData shared] frcForPersonsByTeam];
    RZTree *content = [RZTree nodeForFetchedResultsController:frc];
    RZTree *staticRows = [RZTree nodeWithObject:@"J Static Section"
                                       children:@[@"J is not filtered",
                                                  @"This is filtered"]];
    RZTree *staticSection = [RZTree nodeWithChildren:@[staticRows]];
    RZTree *combinded = [RZTree nodeWithJoinedNodes:@[content, staticSection]];
    NSError *error = nil;
    [frc performFetch:&error];
    NSAssert(error == nil, @"");

    RZTree<RZFilterableTree> *filter = [RZTree filterableNodeWithNode:combinded];
    [filter addObserver:self];

    filter.filter = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        BOOL match = YES;
        if ( [object isKindOfClass:[Person class]] ) {
            Person *person = (id)object;
            match = [person.firstName hasPrefix:@"J"] || [person.lastName hasPrefix:@"J"];
        }
        if ( [object isKindOfClass:[NSString class]] ) {
            NSString *staticRow = (id)object;
            match = [staticRow hasPrefix:@"J"];
        }
        return match;
    }];


    XCTAssert([[filter children] count] == 1);
    [[RZAssemblageTestData shared] createFakeData];
    [[RZAssemblageTestData shared] saveContext];
    XCTAssert([[filter children] count] == 5);

    [self ensureChangeSetChangesAreSequential];
    [self ensureRowsBeginWithJFor:filter];
}

@end
