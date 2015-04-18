//
//  RZFRCTests.m
//  RZAssemblage
//
//  Created by Brian King on 4/18/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
@import RZAssemblage;

#import "RZAssemblageTestData.h"
#import "NSIndexPath+RZAssemblage.h"

@interface RZFRCTests : XCTestCase<RZAssemblageDelegate>

@property (nonatomic, strong) RZAssemblageChangeSet *changeSet;

@end

@implementation RZFRCTests

- (void)assemblage:(RZAssemblage *)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet;
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

- (void)testStartupInsertIsSequential
{
    NSFetchedResultsController *frc = [[RZAssemblageTestData shared] frcForPersonsByTeam];
    RZAssemblage *content = [RZAssemblage assemblageForFetchedResultsController:frc];
    content.delegate = self;
    NSError *error = nil;
    [frc performFetch:&error];
    NSAssert(error == nil, @"");

    XCTAssert([[content children] count] == 0);
    [[RZAssemblageTestData shared] createFakeData];
    [[RZAssemblageTestData shared] saveContext];
    XCTAssert([[content children] count] == 4);
    
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

- (void)testStartupInsertFilter
{
    NSFetchedResultsController *frc = [[RZAssemblageTestData shared] frcForPersonsByTeam];
    RZAssemblage *content = [RZAssemblage assemblageForFetchedResultsController:frc];
    RZFilterAssemblage *filter = [[RZFilterAssemblage alloc] initWithAssemblage:content];
    filter.delegate = self;
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

@end
