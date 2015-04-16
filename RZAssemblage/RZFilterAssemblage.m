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
    // Process removals first, and do not modify the internal
    // index state, to ensure that the indexes generated are valid when used on the
    // assemblage before the filter change.
    [self.unfilteredAssemblage enumerateObjectsWithOptions:options usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        if ( [self isObjectFiltered:object] && [self.filteredIndexPaths containsIndexPath:indexPath] == NO) {
            indexPath = [self exposedIndexPathFromIndexPath:indexPath];
            [self.changeSet removeObject:object atIndexPath:indexPath];
        }
    }];
    [self.unfilteredAssemblage enumerateObjectsWithOptions:RZAssemblageEnumerationBreadthFirst usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        if ( [self isObjectFiltered:object] && [self.filteredIndexPaths containsIndexPath:indexPath] == NO) {
            [self.filteredIndexPaths addIndexPath:indexPath];
        }
    }];
    // Next generate insert events and always ensure that the indexes are valid against
    // the current state.
    [self.unfilteredAssemblage enumerateObjectsWithOptions:RZAssemblageEnumerationBreadthFirst usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        if ( [self.filteredIndexPaths containsIndexPath:indexPath] && [self isObjectFiltered:object] == NO) {
            NSIndexPath *exposedIndexPath = [self exposedIndexPathFromIndexPath:indexPath];
            [self.changeSet insertAtIndexPath:exposedIndexPath];
        }
    }];
    [self.unfilteredAssemblage enumerateObjectsWithOptions:RZAssemblageEnumerationBreadthFirst usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        if ( [self.filteredIndexPaths containsIndexPath:indexPath] && [self isObjectFiltered:object] == NO) {
            [self.filteredIndexPaths removeIndexPath:indexPath];
        }
    }];
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
        __block NSUInteger index = [indexPath indexAtPosition:0];
        [filtered enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
            if ( index >=  range.location ) {
                index += range.length;
            }
        }];
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

@implementation RZAssemblage (Filter)

- (RZFilterAssemblage *)filterAssemblage
{
    return [[RZFilterAssemblage alloc] initWithAssemblage:self];
}

@end
