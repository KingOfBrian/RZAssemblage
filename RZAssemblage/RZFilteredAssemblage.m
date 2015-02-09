    //
//  RZModifiedAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZFilteredAssemblage.h"
#import "RZAssemblage+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageDefines.h"
#import "RZMutableIndexPathSet.h"

@interface RZFilteredAssemblage()

@property (copy, nonatomic) NSMutableArray *store;
@property (copy, nonatomic) NSMutableIndexSet *filteredIndexes;
@property (strong, nonatomic) id<RZAssemblage>filteredAssemblage;

@end

@implementation RZFilteredAssemblage

- (instancetype)initWithAssemblage:(id<RZAssemblage>)assemblage
{
    self = [super initWithArray:@[]];
    if ( self ) {
        _filteredAssemblage = assemblage;
        _store = [NSMutableArray array];
        for ( NSUInteger i = 0; i < [assemblage numberOfChildrenAtIndexPath:nil]; i++ ) {
            [self.store addObject:[assemblage objectAtIndexPath:[NSIndexPath indexPathWithIndex:i]]];
        }
        assemblage.delegate = self;
        _filteredIndexes = [NSMutableIndexSet indexSet];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone;
{
    RZFilteredAssemblage *copy = [super copyWithZone:zone];
    copy->_filter = self.filter;
    copy->_filteredIndexes = [self.filteredIndexes copyWithZone:zone];
    copy->_filteredAssemblage = [self.filteredAssemblage copyWithZone:zone];
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p %@ filtering indexes %@ with %@", self.class, self, self.store, self.filteredIndexes, self.filter];
}

- (NSUInteger)numberOfChildren
{
    return self.store.count - self.filteredIndexes.count;
}

- (id)objectAtIndex:(NSUInteger)index
{
    index = [self realIndexFromIndexPath:[NSIndexPath indexPathWithIndex:index]];
    return [super objectAtIndex:index];
}

- (NSArray *)allObjects
{
    return [self.store filteredArrayUsingPredicate:self.filter];
}

- (void)setFilter:(NSPredicate *)filter
{
    _filter = filter;
    [self updateFilterState];
}

- (void)updateFilterState
{
    [self beginUpdates];
    // Process removals first, and do not modify the internal
    // index state, to ensure that the indexes generated are valid when used on the
    // assemblage before the filter change.
    [self.store enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        if ( [self isObjectFiltered:object] && [self isIndexFiltered:index] == NO) {
            NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:index];
            indexPath = [self indexPathFromRealIndexPath:indexPath];
            [self.changeSet removeAtIndexPath:indexPath];
        }
    }];
    [self.store enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        if ( [self isObjectFiltered:object] && [self isIndexFiltered:index] == NO) {
            [self.filteredIndexes addIndex:index];
        }
    }];
    // Next generate insert events and always ensure that the indexes are valid against
    // the current state.
    [self.store enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        if ( [self isIndexFiltered:index] && [self isObjectFiltered:object] == NO) {
            NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:index];
            indexPath = [self indexPathFromRealIndexPath:indexPath];
            [self.filteredIndexes removeIndex:index];
            [self.changeSet insertAtIndexPath:indexPath];
        }
    }];
    [self endUpdates];
}

- (void)lookupIndexPath:(NSIndexPath *)indexPath forRemoval:(BOOL)forRemoval
             assemblage:(out id<RZAssemblage> *)assemblage newIndexPath:(out NSIndexPath **)newIndexPath;
{
    indexPath = [self realIndexPathFromIndexPath:indexPath];
    [self.filteredAssemblage lookupIndexPath:indexPath forRemoval:forRemoval
                         assemblage:assemblage newIndexPath:newIndexPath];
}

- (NSUInteger)indexFromRealIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath indexAtPosition:0];
    index -= [self.filteredIndexes countOfIndexesInRange:NSMakeRange(0, index)];
    return index;
}

- (NSUInteger)realIndexFromIndexPath:(NSIndexPath *)indexPath
{
    __block NSUInteger index = [indexPath indexAtPosition:0];
    [self.filteredIndexes enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        if ( index >=  range.location ) {
            index += range.length;
        }
    }];

    return index;
}

- (NSIndexPath *)indexPathFromRealIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [self indexFromRealIndexPath:indexPath];
    indexPath = [indexPath rz_indexPathByRemovingFirstIndex];
    indexPath = [indexPath indexPathByAddingIndex:index];
    return indexPath;
}

- (NSIndexPath *)realIndexPathFromIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [self realIndexFromIndexPath:indexPath];
    indexPath = [indexPath rz_indexPathByRemovingFirstIndex];
    indexPath = [indexPath indexPathByAddingIndex:index];
    return indexPath;
}

- (BOOL)isObjectFiltered:(id)object
{
    return self.filter && [self.filter evaluateWithObject:object] == NO;
}

- (BOOL)isIndexFiltered:(NSUInteger)index
{
    return [self.filteredIndexes containsIndex:index];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    [changeSet.inserts enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        NSUInteger idx = [indexPath indexAtPosition:0];
        id object = [assemblage objectAtIndexPath:indexPath];
        BOOL filtered = [self isObjectFiltered:object];
        if ( filtered ) {
            [self.filteredIndexes addIndex:[indexPath indexAtPosition:0]];
            // How do are other indexes affected?!
            [changeSet clearInsertAtIndexPath:indexPath];
        }
        else {
            [self.store insertObject:object atIndex:idx];
            [self.filteredIndexes shiftIndexesStartingAtIndex:idx by:1];
        }
    }];
    [changeSet.removes enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        NSUInteger idx = [indexPath indexAtPosition:0];
        id object = [changeSet.startingAssemblage objectAtIndexPath:indexPath];
        [self.store removeObjectAtIndex:idx];
        [self.filteredIndexes shiftIndexesStartingAtIndex:idx by:-1];

        BOOL filtered = [self isObjectFiltered:object];
        if ( filtered ) {
            // How do are other indexes affected?!
            [changeSet clearRemoveAtIndexPath:indexPath];
        }
    }];
    [changeSet.updates enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        NSUInteger idx = [indexPath indexAtPosition:0];
        id object = [assemblage objectAtIndexPath:indexPath];
        indexPath = [self indexPathFromRealIndexPath:indexPath];
        if ( [self isIndexFiltered:idx] && [self isObjectFiltered:object] == NO ) {
            [self.filteredIndexes removeIndex:idx];

            [changeSet clearUpdateAtIndexPath:indexPath];
            [changeSet insertAtIndexPath:indexPath];
        }
        else if ( [self isIndexFiltered:idx] == NO && [self isObjectFiltered:object] ) {
            [self.filteredIndexes addIndex:idx];
            [changeSet clearUpdateAtIndexPath:indexPath];

            [changeSet removeAtIndexPath:indexPath];
        }
    }];
    [changeSet.moves.rootIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    }];
    [self.changeSet mergeChangeSet:changeSet withIndexPathTransform:^NSIndexPath *(NSIndexPath *indexPath) {
        return [self indexPathFromRealIndexPath:indexPath];
    }];
    [self endUpdates];
}

@end
