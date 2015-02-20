//
//  RZChangeSet.m
//  RZAssemblage
//
//  Created by Brian King on 2/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageChangeSet.h"
#import "RZIndexPathSet.h"
#import "NSIndexPath+RZAssemblage.h"

@interface RZAssemblageChangeSet ()

@property (strong, nonatomic) RZMutableIndexPathSet *inserts;
@property (strong, nonatomic) RZMutableIndexPathSet *updates;
@property (strong, nonatomic) RZMutableIndexPathSet *removes;

@end

@implementation RZAssemblageChangeSet

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        _inserts = [RZMutableIndexPathSet set];
        _updates = [RZMutableIndexPathSet set];
        _removes = [RZMutableIndexPathSet set];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p \nI=%@, U=%@, R=%@, M=%@>", self.class, self,
            self.insertedIndexPaths, self.updatedIndexPaths, self.removedIndexPaths, self.moveIndexPathFromToMap];
}

- (NSArray *)insertedIndexPaths
{
    return self.inserts.sortedIndexPaths;
}

- (NSArray *)removedIndexPaths
{
    return self.removes.sortedIndexPaths;
}

- (NSArray *)updatedIndexPaths
{
    return self.updates.sortedIndexPaths;
}

- (void)insertAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates shiftIndexesStartingAtIndexPath:indexPath by:1];
    [self.inserts shiftIndexesStartingAtIndexPath:indexPath by:1];

    [self.inserts addIndexPath:indexPath];
}

- (void)updateAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates addIndexPath:indexPath];
}

- (void)removeAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL insertWasRemoved = [self.inserts containsIndexPath:indexPath];

    [self.updates shiftIndexesStartingAfterIndexPath:indexPath by:-1];
    [self.inserts shiftIndexesStartingAfterIndexPath:indexPath by:-1];

    // Do nothing if the removal was an un-propagated insertion
    if ( insertWasRemoved == NO) {
        // If the index has already been removed, shift it down till it finds an empty index.
        NSIndexPath *indexPathToRemove = indexPath;
        while ( [self.removes containsIndexPath:indexPathToRemove] ) {
            indexPathToRemove = [indexPathToRemove rz_indexPathWithLastIndexShiftedBy:1];
        }
        [self.removes addIndexPath:indexPathToRemove];
    }
}

- (NSArray *)objectsForIndexPaths:(NSArray *)indexPaths inAssemblage:(id<RZAssemblage>)assemblage
{
    NSMutableArray *objects = [NSMutableArray array];
    for ( NSIndexPath *indexPath in indexPaths ) {
        [objects addObject:[assemblage objectAtIndexPath:indexPath]];
    }
    return [objects copy];
}

- (void)generateMoveEventsFromAssemblage:(id<RZAssemblage>)assemblage
{
    NSArray *insertedIndexPaths = self.insertedIndexPaths;
    NSArray *removedIndexPaths = self.removedIndexPaths;

    NSArray *insertedObjects = [self objectsForIndexPaths:insertedIndexPaths inAssemblage:assemblage];
    NSArray *removedObjects  = [self objectsForIndexPaths:removedIndexPaths inAssemblage:self.startingAssemblage];

    NSMutableDictionary *moveIndexPathFromToMap = [NSMutableDictionary dictionary];
    [insertedObjects enumerateObjectsUsingBlock:^(id insertedObject, NSUInteger insertedIndex, BOOL *stop) {
        NSUInteger removedIndex = [removedObjects indexOfObject:insertedObject];
        if ( removedIndex != NSNotFound ) {
            NSIndexPath *removedIndexPath = removedIndexPaths[removedIndex];
            NSIndexPath *insertedIndexPath = insertedIndexPaths[insertedIndex];
            moveIndexPathFromToMap[removedIndexPath] = insertedIndexPath;
            [self.inserts removeIndexPath:insertedIndexPath];
            [self.removes removeIndexPath:removedIndexPath];
            
        }
    }];
    _moveIndexPathFromToMap = [moveIndexPathFromToMap copy];
}

- (void)moveAtIndexPath:(NSIndexPath *)index1 toIndexPath:(NSIndexPath *)index2
{
    if ( [self.updates containsIndexPath:index1] ) {
        [self.updates removeIndexPath:index1];
        [self.updates addIndexPath:index2];
    }
//    [self.moves ]
//    [self.moves addIndexPath:index2];
}

- (void)mergeChangeSet:(RZAssemblageChangeSet *)changeSet
withIndexPathTransform:(RZAssemblageChangeSetIndexPathTransform)transform
{
    NSParameterAssert(transform);

    for ( NSIndexPath *indexPath in changeSet.removedIndexPaths ) {
        NSIndexPath *newIndexPath = transform(indexPath);
        [self removeAtIndexPath:newIndexPath];
    }

    for ( NSIndexPath *indexPath in changeSet.insertedIndexPaths ) {
        NSIndexPath *newIndexPath = transform(indexPath);
        [self insertAtIndexPath:newIndexPath];
    }

    for ( NSIndexPath *indexPath in changeSet.updatedIndexPaths ) {
        NSIndexPath *newIndexPath = transform(indexPath);
        [self updateAtIndexPath:newIndexPath];
    }
#warning Moves
}

@end
