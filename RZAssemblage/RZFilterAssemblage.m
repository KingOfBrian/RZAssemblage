    //
//  RZModifiedAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZFilterAssemblage.h"
#import "RZFilteredAssemblage.h"
#import "RZAssemblage+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageDefines.h"
#import "RZIndexPathSet.h"
#import "NSIndexSet+RZAssemblage.h"

@interface RZFilterAssemblage()

@property (strong, nonatomic) RZFilteredAssemblage *filteredAssemblage;
@property (strong, nonatomic) RZAssemblage *unfilteredAssemblage;
@property (strong, nonatomic) RZMutableIndexPathSet *filteredIndexPaths;

@end

@implementation RZFilterAssemblage

- (instancetype)initWithAssemblage:(RZAssemblage *)assemblage
{
    self = [super init];
    if ( self ) {
        _filteredIndexPaths = [RZMutableIndexPathSet set];
        _filteredAssemblage = [[RZFilteredAssemblage alloc] initWithAssemblage:assemblage filteredIndexPaths:_filteredIndexPaths];
        _unfilteredAssemblage = assemblage;
        _unfilteredAssemblage.delegate = self;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p %@ filter %@", self.class, self, self.filter, self.filteredAssemblage];
}

#pragma mark - RZAssemblage

- (NSUInteger)countOfElements
{
    return [self.filteredAssemblage countOfElements];
}

- (id)objectInElementsAtIndex:(NSUInteger)index
{
    return [self.filteredAssemblage objectInElementsAtIndex:index];
}

- (id)nodeAtIndex:(NSUInteger)index;
{
    return [self.filteredAssemblage nodeAtIndex:index];
}

- (NSUInteger)indexOfAssemblage:(RZAssemblage *)assemblage
{
    return [self.filteredAssemblage indexOfAssemblage:assemblage];
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    [self.filteredAssemblage removeObjectFromElementsAtIndex:index];
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    [self.filteredAssemblage insertObject:object inElementsAtIndex:index];
}

- (RZAssemblage *)assemblageAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.filteredAssemblage assemblageAtIndexPath:indexPath];
}

#pragma mark - Filter Mutation

- (void)setFilter:(NSPredicate *)filter
{
    RZRaize(self.updateCount == 0, @"Can not modify the filter during mutation");
    _filter = filter;
    [self updateFilterState];
}

- (void)updateFilterState
{
    [self openBatchUpdate];
    RZAssemblageEnumerationOptions options = RZAssemblageEnumerationBreadthFirst;
    RZMutableIndexPathSet *insertedIndexPaths = [RZMutableIndexPathSet set];
    RZMutableIndexPathSet *removedIndexPaths = [RZMutableIndexPathSet set];
    __block NSUInteger maxTreeDepth = 0;
    [self.unfilteredAssemblage enumerateObjectsWithOptions:options usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        BOOL objectIsFiltered = [self isObjectFiltered:object];
        BOOL indexIsFiltered = [self.filteredIndexPaths containsIndexPath:indexPath];
        if ( objectIsFiltered && indexIsFiltered == NO) {
            [removedIndexPaths addIndexPath:indexPath];
        }
        else if ( indexIsFiltered && objectIsFiltered == NO) {
            [insertedIndexPaths addIndexPath:indexPath];
        }
        maxTreeDepth = MAX(maxTreeDepth, indexPath.length);
    }];
    // Enumerate changes based on depth. Peers do not want the changes
    // in indexes to be reflected, but nodes do want their parent changes
    // to be reflected.
    for ( NSUInteger depth = 0; depth < maxTreeDepth; depth++ ) {
        // Process removals first, and do not modify the index filter until after the
        // change set for removals has been created to ensure that the indexes generated
        // are valid pre-mutation values.
        [removedIndexPaths enumerateIndexesUsingBlock:^(NSIndexPath *parentPath, NSIndexSet *indexes, BOOL *stop) {
            if ( parentPath.length == depth ) {
                [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                    NSIndexPath *indexPath = [parentPath indexPathByAddingIndex:idx];
                    NSIndexPath *exposedIndexPath = [self exposedIndexPathFromIndexPath:indexPath];
                    id object = [self.unfilteredAssemblage objectAtIndexPath:indexPath];
                    [self.changeSet removeObject:object atIndexPath:exposedIndexPath];
                }];
            }
        }];
        // Update the filtered indexes now that removals have been added to the change set.
        [removedIndexPaths enumerateIndexesUsingBlock:^(NSIndexPath *parentPath, NSIndexSet *indexes, BOOL *stop) {
            if ( parentPath.length == depth ) {
                [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                    NSIndexPath *indexPath = [parentPath indexPathByAddingIndex:idx];
                    [self.filteredIndexPaths addIndexPath:indexPath];
                }];
            }
        }];
        // Update the change set with the insertion events. Insertions do not self-interfere
        // with their index space so this can be done in one pass.
        [insertedIndexPaths enumerateIndexesUsingBlock:^(NSIndexPath *parentPath, NSIndexSet *indexes, BOOL *stop) {
            if ( parentPath.length == depth ) {
                [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                    NSIndexPath *indexPath = [parentPath indexPathByAddingIndex:idx];
                    NSIndexPath *exposedIndexPath = [self exposedIndexPathFromIndexPath:indexPath];
                    [self.changeSet insertAtIndexPath:exposedIndexPath];
                    [self.filteredIndexPaths removeIndexPath:indexPath];
                }];
            }
        }];
    }
    [self closeBatchUpdate];
}

#pragma mark - RZAssemblageDelegate

- (void)assemblage:(RZAssemblage *)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    [changeSet.removedObjectsByIndexPath enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id obj, BOOL *stop) {
        NSIndexPath *parentIndexPath = [self exposedIndexPathFromIndexPath:indexPath];

        if ( [self.filteredIndexPaths containsIndexPath:indexPath] == NO ) {
            [self.changeSet removeObject:obj atIndexPath:parentIndexPath];
        }
    }];
    // Clean up the index set.   If we shift a lot of items sequentially,
    // indexes can get improperly preserved, so remove them, and then shift them.
    [self.filteredIndexPaths removeIndexPathsInArray:changeSet.removedIndexPaths];
    for ( NSIndexPath *indexPath in changeSet.removedIndexPaths ) {
        NSIndexPath *newIndexPath = [indexPath rz_indexPathWithLastIndexShiftedBy:1];
        [self.filteredIndexPaths shiftIndexesStartingAtIndexPath:newIndexPath by:-1];
    }

    for ( NSIndexPath *indexPath in changeSet.insertedIndexPaths ) {
        NSIndexPath *parentIndexPath = [self exposedIndexPathFromIndexPath:indexPath];
        [self.filteredIndexPaths shiftIndexesStartingAtIndexPath:indexPath by:1];

        id object = [assemblage objectAtIndexPath:indexPath];
        if ( [self isObjectFiltered:object] == NO ) {
            [self.changeSet insertAtIndexPath:parentIndexPath];
        }
        else {
            [self.filteredIndexPaths addIndexPath:indexPath];
        }
    }

    for ( NSIndexPath *indexPath in changeSet.updatedIndexPaths ) {
        id object = [assemblage objectAtIndexPath:indexPath];

        NSIndexPath *parentIndexPath = [self exposedIndexPathFromIndexPath:indexPath];
        if ( [self.filteredIndexPaths containsIndexPath:indexPath] && [self isObjectFiltered:object] == NO ) {
            [self.filteredIndexPaths removeIndexPath:indexPath];

            [self.changeSet insertAtIndexPath:parentIndexPath];
        }
        else if ( [self.filteredIndexPaths containsIndexPath:indexPath] == NO && [self isObjectFiltered:object] ) {
            [self.filteredIndexPaths addIndexPath:indexPath];

            [self.changeSet removeObject:object atIndexPath:parentIndexPath];
        }
        else {
            [self.changeSet updateAtIndexPath:parentIndexPath];
        }
    }
    [self closeBatchUpdate];
}

#pragma mark - Private

- (NSIndexPath *)exposedIndexPathFromIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *parentIndexPath = [NSIndexPath indexPathWithIndexes:NULL length:0];
    for ( NSUInteger indexPosition = 0; indexPosition < indexPath.length; indexPosition++ ) {
        NSIndexSet *filtered = [self.filteredIndexPaths indexesAtIndexPath:parentIndexPath];
        NSUInteger index = [indexPath indexAtPosition:indexPosition];
        index -= [filtered countOfIndexesInRange:NSMakeRange(0, index)];
        indexPath = [indexPath rz_indexPathByReplacingIndexAtPosition:indexPosition withIndex:index];
    }
    return indexPath;
}

- (NSIndexPath *)indexPathFromExposedIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *parentIndexPath = [NSIndexPath indexPathWithIndexes:NULL length:0];
    for ( NSUInteger indexPosition = 0; indexPosition < indexPath.length; indexPosition++ ) {
        NSIndexSet *filtered = [self.filteredIndexPaths indexesAtIndexPath:parentIndexPath];
        NSUInteger index = [indexPath indexAtPosition:0];
        index += [filtered rz_countOfIndexesInRangesBeforeOrContainingIndex:index];
        indexPath = [indexPath rz_indexPathByReplacingIndexAtPosition:indexPosition withIndex:index];
    }
    return indexPath;
}

- (BOOL)isObjectFiltered:(id)object
{
    BOOL filtered = self.filter && [self.filter evaluateWithObject:object] == NO;
    return filtered;
}

@end
