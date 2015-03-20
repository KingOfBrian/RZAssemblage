//
//  RZChangeSet.m
//  RZAssemblage
//
//  Created by Brian King on 2/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageChangeSet+Private.h"
#import "RZIndexPathSet.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageDefines.h"

@implementation RZAssemblageChangeSet

+ (NSIndexSet *)sectionIndexSetFromIndexPaths:(NSArray *)indexPaths
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    for ( NSIndexPath *indexPath in indexPaths ) {
        if ( indexPath.length == 1 ) {
            [indexes addIndex:[indexPath indexAtPosition:0]];
        }
    }
    return [indexes copy];
}

+ (NSArray *)rowIndexPathsFromIndexPaths:(NSArray *)indexPaths
{
    NSMutableArray *rowIndexPaths = [NSMutableArray array];
    for ( NSIndexPath *indexPath in indexPaths ) {
        if ( indexPath.length == 2 ) {
            [rowIndexPaths addObject:indexPath];
        }
    }
    return [rowIndexPaths copy];
}

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        _inserts = [RZMutableIndexPathSet set];
        _updates = [RZMutableIndexPathSet set];
        _removes = [RZMutableIndexPathSet set];
        self.moveFromToIndexPathMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p \nI=%@, U=%@, R=%@, M=%@>", self.class, self,
            self.insertedIndexPaths, self.updatedIndexPaths, self.removedIndexPaths, self.moveFromToIndexPathMap];
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

- (NSDictionary *)moveFromToIndexPaths
{
    return [self.moveFromToIndexPathMap copy];
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
        [objects addObject:[assemblage childAtIndexPath:indexPath]];
    }
    return [objects copy];
}

- (void)generateMoveEventsFromAssemblage:(id<RZAssemblage>)assemblage
{
    NSArray *insertedIndexPaths = self.insertedIndexPaths;
    NSArray *removedIndexPaths = self.removedIndexPaths;

    NSArray *insertedObjects = [self objectsForIndexPaths:insertedIndexPaths inAssemblage:assemblage];
    NSArray *removedObjects  = [self objectsForIndexPaths:removedIndexPaths inAssemblage:self.startingAssemblage];

    // Save the index state of the removes
    NSMutableDictionary *parentIndexPathToIndexes = [NSMutableDictionary dictionary];
    [self.removes enumerateIndexesUsingBlock:^(NSIndexPath *parentPath, NSIndexSet *indexes, BOOL *stop) {
        parentIndexPathToIndexes[parentPath] = indexes;
    }];

    NSMutableDictionary *moveFromToIndexPathMap = [NSMutableDictionary dictionary];
    [insertedObjects enumerateObjectsUsingBlock:^(id insertedObject, NSUInteger insertedIndex, BOOL *stop) {
        NSUInteger removedIndex = [removedObjects indexOfObject:insertedObject];
        if ( removedIndex != NSNotFound ) {
            NSIndexPath *removedIndexPath = removedIndexPaths[removedIndex];
            NSIndexPath *insertedIndexPath = insertedIndexPaths[insertedIndex];
            moveFromToIndexPathMap[removedIndexPath] = insertedIndexPath;
            [self.inserts removeIndexPath:insertedIndexPath];
            [self.removes removeIndexPath:removedIndexPath];
        }
    }];

#ifdef CORRECT_MOVE_NOTIFICATIONS_FOR_SHIFT_WHOLE
    // Iterate over the to destinations, and if the index path lands inside a remove hole (More than 1 remove), correct it.
    [[moveFromToIndexPathMap copy] enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *fromIndexPath, NSIndexPath *toIndexPath, BOOL *stop) {
        NSIndexPath *parentFromIndexPath = [fromIndexPath indexPathByRemovingLastIndex];
        NSIndexPath *parentToIndexPath   = [toIndexPath indexPathByRemovingLastIndex];
        if ( [parentFromIndexPath isEqual:parentToIndexPath] ) {
            NSIndexSet *indexes = parentIndexPathToIndexes[parentFromIndexPath];
            __block NSUInteger index = [toIndexPath rz_lastIndex];
            [indexes enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
                if ( range.length > 2 && index > range.location && index < range.location + range.length ) {
                    // The to index is inside of a shift-hole.   Subtract the range
                    index -= range.length - 2;
                }
            }];
            moveFromToIndexPathMap[fromIndexPath] = [parentToIndexPath indexPathByAddingIndex:index];
        }
    }];
#endif
    [self.moveFromToIndexPathMap setValuesForKeysWithDictionary:moveFromToIndexPathMap];
}

- (void)moveAtIndexPath:(NSIndexPath *)index1 toIndexPath:(NSIndexPath *)index2
{
    if ( [self.updates containsIndexPath:index1] ) {
        [self.updates removeIndexPath:index1];
        [self.updates addIndexPath:index2];
    }
    self.moveFromToIndexPathMap[index1] = index2;
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
    [changeSet.moveFromToIndexPathMap enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *fromIndexPath, NSIndexPath *toIndexPath, BOOL *stop) {
        NSIndexPath *newFromIndexPath = transform(fromIndexPath);
        NSIndexPath *newToIndexPath = transform(toIndexPath);
        [self moveAtIndexPath:newFromIndexPath toIndexPath:newToIndexPath];
    }];
}

@end
