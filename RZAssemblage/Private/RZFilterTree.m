    //
//  RZModifiedTree.m
//  RZTree
//
//  Created by Brian King on 1/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZFilterTree.h"
#import "RZFilteredTree.h"
#import "RZTree+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageDefines.h"
#import "RZIndexPathSet.h"
#import "NSIndexSet+RZAssemblage.h"

@interface RZFilterTree()

@property (strong, nonatomic) RZFilteredTree *filteredTree;
@property (strong, nonatomic) RZTree *unfilteredTree;
@property (strong, nonatomic) RZMutableIndexPathSet *filteredIndexPaths;

@end

@implementation RZFilterTree

- (instancetype)initWithNode:(RZTree *)node
{
    self = [super init];
    if ( self ) {
        _filteredIndexPaths = [RZMutableIndexPathSet set];
        _filteredTree = [[RZFilteredTree alloc] initWithNode:node filteredIndexPaths:_filteredIndexPaths];
        _unfilteredTree = node;
        [_unfilteredTree addObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [_unfilteredTree removeObserver:self];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p %@ filter %@", self.class, self, self.filter, self.filteredTree];
}

#pragma mark - RZTree

- (NSUInteger)countOfElements
{
    return [self.filteredTree countOfElements];
}

- (nullable id)objectInElementsAtIndex:(NSUInteger)index
{
    return [self.filteredTree objectInElementsAtIndex:index];
}

- (id)nodeAtIndex:(NSUInteger)index;
{
    return [self.filteredTree nodeAtIndex:index];
}

- (NSUInteger)indexOfNode:(RZTree *)node
{
    return [self.filteredTree indexOfNode:node];
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    [self.filteredTree removeObjectFromElementsAtIndex:index];
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    [self.filteredTree insertObject:object inElementsAtIndex:index];
}

- (RZTree *)nodeAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.filteredTree nodeAtIndexPath:indexPath];
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
    RZTreeEnumerationOptions options = RZTreeEnumerationBreadthFirst;
    RZMutableIndexPathSet *insertedIndexPaths = [RZMutableIndexPathSet set];
    RZMutableIndexPathSet *removedIndexPaths = [RZMutableIndexPathSet set];
    __block NSUInteger maxTreeDepth = 0;
    [self.unfilteredTree enumerateObjectsWithOptions:options usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
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
                    id object = [self.unfilteredTree objectAtIndexPath:indexPath];
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

#pragma mark - RZTreeObserver

- (void)node:(RZTree *)node didEndUpdatesWithChangeSet:(RZChangeSet *)changeSet
{
    // Transform the removals. Any removals that were filtered are removed from the change set. Other removals
    // are translated to occur at the 'exposed' index path.
    [changeSet.removedObjectsByIndexPath enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, id obj, BOOL *stop) {
        NSIndexPath *exposedIndexPath = [self exposedIndexPathFromIndexPath:indexPath];

        if ( [self.filteredIndexPaths containsIndexPath:indexPath] == NO ) {
            [self.changeSet removeObject:obj atIndexPath:exposedIndexPath];
        }
    }];
    // Clean up the index set. Clear out any filtered indexes and shift down the rest
    [self.filteredIndexPaths removeIndexPathsInArray:changeSet.removedIndexPaths];
    for ( NSIndexPath *indexPath in changeSet.removedIndexPaths ) {
        NSIndexPath *newIndexPath = [indexPath rz_indexPathWithLastIndexShiftedBy:1];
        [self.filteredIndexPaths shiftIndexesStartingAtIndexPath:newIndexPath by:-1];
    }

    // Transform the insertions. Any insertions that are filtered are removed from the change set. Other insertions
    // are translated to occur at the 'exposed' index path.
    for ( NSIndexPath *indexPath in changeSet.insertedIndexPaths ) {
        [self.filteredIndexPaths shiftIndexesStartingAtIndexPath:indexPath by:1];

        id object = [node objectAtIndexPath:indexPath];
        if ( [self isObjectFiltered:object] == NO ) {
            NSIndexPath *exposedIndexPath = [self exposedIndexPathFromIndexPath:indexPath];
            [self.changeSet insertAtIndexPath:exposedIndexPath];
        }
        else {
            [self.filteredIndexPaths addIndexPath:indexPath];
        }
    }

    for ( NSIndexPath *indexPath in changeSet.updatedIndexPaths ) {
        id object = [node objectAtIndexPath:indexPath];

        NSIndexPath *exposedIndexPath = [self exposedIndexPathFromIndexPath:indexPath];
        if ( [self.filteredIndexPaths containsIndexPath:indexPath] && [self isObjectFiltered:object] == NO ) {
            [self.filteredIndexPaths removeIndexPath:indexPath];

            [self.changeSet insertAtIndexPath:exposedIndexPath];
        }
        else if ( [self.filteredIndexPaths containsIndexPath:indexPath] == NO && [self isObjectFiltered:object] ) {
            [self.filteredIndexPaths addIndexPath:indexPath];

            [self.changeSet removeObject:object atIndexPath:exposedIndexPath];
        }
        else {
            [self.changeSet updateAtIndexPath:exposedIndexPath];
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
        NSUInteger exposedIndex = index - [filtered countOfIndexesInRange:NSMakeRange(0, index)];
        if ( index != exposedIndex ) {
            indexPath = [indexPath rz_indexPathByReplacingIndexAtPosition:indexPosition withIndex:exposedIndex];
        }
        parentIndexPath = [parentIndexPath indexPathByAddingIndex:index];
    }
    return indexPath;
}

- (NSIndexPath *)indexPathFromExposedIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *parentIndexPath = [NSIndexPath indexPathWithIndexes:NULL length:0];
    for ( NSUInteger indexPosition = 0; indexPosition < indexPath.length; indexPosition++ ) {
        NSIndexSet *filtered = [self.filteredIndexPaths indexesAtIndexPath:parentIndexPath];
        NSUInteger index = [indexPath indexAtPosition:0];
        NSUInteger exposedIndex = index + [filtered rz_countOfIndexesInRangesBeforeOrContainingIndex:index];
        if ( index != exposedIndex ) {
            indexPath = [indexPath rz_indexPathByReplacingIndexAtPosition:indexPosition withIndex:exposedIndex];
        }
        parentIndexPath = [parentIndexPath indexPathByAddingIndex:index];
    }
    return indexPath;
}

- (BOOL)isObjectFiltered:(id)object
{
    BOOL filtered = self.filter && [self.filter evaluateWithObject:object] == NO;
    return filtered;
}

@end
