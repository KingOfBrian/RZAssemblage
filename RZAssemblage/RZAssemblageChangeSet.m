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
#import "RZAssemblage.h"

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
        _removedObjectsByIndexPath = [NSMutableDictionary dictionary];
        _moveFromToIndexPathMap = [NSMutableDictionary dictionary];
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
    return [[self.removedObjectsByIndexPath allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)updatedIndexPaths
{
    return self.updates.sortedIndexPaths;
}

- (NSDictionary *)moveFromToIndexPaths
{
    return [self.moveFromToIndexPathMap copy];
}

- (id)removedObjectAtIndexPath:(NSIndexPath *)indexPath;
{
    NSParameterAssert(indexPath);
    id object = self.removedObjectsByIndexPath[indexPath];
    NSAssert(object != nil, @"No object for indexPath=%@", indexPath);
    return object;
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

- (void)removeObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
{
    BOOL insertWasRemoved = [self.inserts containsIndexPath:indexPath];

    [self.updates shiftIndexesStartingAfterIndexPath:indexPath by:-1];
    [self.inserts shiftIndexesStartingAfterIndexPath:indexPath by:-1];

    // Do nothing if the removal was an un-propagated insertion
    if ( insertWasRemoved == NO) {
        // If the index has already been removed, shift it down till it finds an empty index.
        NSIndexPath *indexPathToRemove = indexPath;
        while ( [self.removedIndexPaths containsObject:indexPathToRemove] ) {
            indexPathToRemove = [indexPathToRemove rz_indexPathWithLastIndexShiftedBy:1];
        }
        self.removedObjectsByIndexPath[indexPathToRemove] = object;
    }
}

- (NSArray *)objectsForIndexPaths:(NSArray *)indexPaths inAssemblage:(RZAssemblage *)assemblage
{
    NSMutableArray *objects = [NSMutableArray array];
    for ( NSIndexPath *indexPath in indexPaths ) {
        [objects addObject:[assemblage objectAtIndexPath:indexPath]];
    }
    return [objects copy];
}

- (void)generateMoveEventsFromAssemblage:(RZAssemblage *)assemblage
{
    NSArray *insertedIndexPaths = self.insertedIndexPaths;

    NSArray *insertedObjects = [self objectsForIndexPaths:insertedIndexPaths inAssemblage:assemblage];

    NSMutableDictionary *moveFromToIndexPathMap = [NSMutableDictionary dictionary];
    [insertedObjects enumerateObjectsUsingBlock:^(id insertedObject, NSUInteger insertedIndex, BOOL *stop) {
        NSIndexPath *removedIndexPath = [self indexPathForRemovedObject:insertedObject];
        if ( removedIndexPath ) {
            NSIndexPath *insertedIndexPath = insertedIndexPaths[insertedIndex];
            moveFromToIndexPathMap[removedIndexPath] = insertedIndexPath;
            [self.inserts removeIndexPath:insertedIndexPath];
            [self.removedObjectsByIndexPath removeObjectForKey:removedIndexPath];
        }
    }];

    [self.moveFromToIndexPathMap setValuesForKeysWithDictionary:moveFromToIndexPathMap];
}

- (NSIndexPath *)indexPathForRemovedObject:(id)object
{
    __block NSIndexPath *indexPathForRemovedObject = nil;
    [self.removedObjectsByIndexPath enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id obj, BOOL *stop) {
        if ( object == obj ) {
            indexPathForRemovedObject = indexPath;
        }
    }];
    return indexPathForRemovedObject;
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
        id object = [changeSet removedObjectAtIndexPath:indexPath];
        [self removeObject:object atIndexPath:newIndexPath];
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
