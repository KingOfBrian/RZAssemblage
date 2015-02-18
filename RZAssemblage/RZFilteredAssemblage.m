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
#import "RZIndexPathSet.h"
#import "RZAssemblageMutationRelay.h"

@interface RZFilteredAssemblage() <RZAssemblageMutationRelay>

@property (copy, nonatomic) NSMutableIndexSet *filteredIndexes;
@property (strong, nonatomic) id<RZAssemblage>filteredAssemblage;

@end

@implementation RZFilteredAssemblage

- (instancetype)initWithAssemblage:(id<RZAssemblage>)assemblage
{
    self = [super initWithArray:@[]];
    if ( self ) {
        _filteredAssemblage = assemblage;
        _filteredAssemblage.delegate = self;
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
    return [NSString stringWithFormat:@"<%@: %p %@ filtering indexes %@ with %@", self.class, self, self.filteredAssemblage, self.filteredIndexes, self.filter];
}

- (NSUInteger)numberOfChildren
{
    return [self.filteredAssemblage numberOfChildren] - self.filteredIndexes.count;
}

- (id)objectAtIndex:(NSUInteger)index
{
    index = [self realIndexFromIndexPath:[NSIndexPath indexPathWithIndex:index]];
    return [self.filteredAssemblage objectAtIndex:index];
}

- (NSArray *)allObjects
{
    return [[self.filteredAssemblage allObjects] filteredArrayUsingPredicate:self.filter];
}

- (void)setFilter:(NSPredicate *)filter
{
    _filter = filter;
    [self updateFilterState];
}

- (void)updateFilterState
{
    [self openBatchUpdate];
    // Process removals first, and do not modify the internal
    // index state, to ensure that the indexes generated are valid when used on the
    // assemblage before the filter change.
    [[self.filteredAssemblage allObjects] enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        if ( [self isObjectFiltered:object] && [self isIndexFiltered:index] == NO) {
            NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:index];
            indexPath = [self indexPathFromRealIndexPath:indexPath];
            [self.changeSet removeAtIndexPath:indexPath];
        }
    }];
    [[self.filteredAssemblage allObjects] enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        if ( [self isObjectFiltered:object] && [self isIndexFiltered:index] == NO) {
            [self.filteredIndexes addIndex:index];
        }
    }];
    // Next generate insert events and always ensure that the indexes are valid against
    // the current state.
    [[self.filteredAssemblage allObjects] enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        if ( [self isIndexFiltered:index] && [self isObjectFiltered:object] == NO) {
            NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:index];
            indexPath = [self indexPathFromRealIndexPath:indexPath];
            [self.filteredIndexes removeIndex:index];
            [self.changeSet insertAtIndexPath:indexPath];
        }
    }];
    [self closeBatchUpdate];
}

- (void)lookupIndexPath:(NSIndexPath *)indexPath forRemoval:(BOOL)forRemoval
             assemblage:(out id<RZAssemblage> *)assemblage newIndexPath:(out NSIndexPath **)newIndexPath;
{
    id<RZAssemblageMutationRelay>assemblageRelay = (id)self.filteredAssemblage;
    RZRaize([assemblageRelay conformsToProtocol:@protocol(RZAssemblageMutationRelay)], @"Contained assemblage does not support mutation relay");
    indexPath = [self realIndexPathFromIndexPath:indexPath];
    [assemblageRelay lookupIndexPath:indexPath forRemoval:forRemoval
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
    for ( NSIndexPath *indexPath in changeSet.insertedIndexPaths ) {
        NSUInteger idx = [indexPath indexAtPosition:0];
        NSIndexPath *parentIndexPath = [self indexPathFromRealIndexPath:indexPath];

        id object = [assemblage objectAtIndexPath:indexPath];
        if ( [self isObjectFiltered:object] == NO ) {
            [self.changeSet insertAtIndexPath:parentIndexPath];
        }
        else {
            [self.filteredIndexes shiftIndexesStartingAtIndex:idx by:1];
            [self.filteredIndexes addIndex:idx];
        }
    }
    for ( NSIndexPath *indexPath in changeSet.removedIndexPaths ) {
        NSIndexPath *parentIndexPath = [self indexPathFromRealIndexPath:indexPath];
        NSUInteger idx = [indexPath indexAtPosition:0];

        if ( [self isIndexFiltered:idx] == NO ) {
            [self.changeSet removeAtIndexPath:parentIndexPath];
        }
        [self.filteredIndexes shiftIndexesStartingAtIndex:idx + 1 by:-1];
    }
    for ( NSIndexPath *indexPath in changeSet.updatedIndexPaths ) {
        NSUInteger idx = [indexPath indexAtPosition:0];
        id object = [assemblage objectAtIndexPath:indexPath];

        NSIndexPath *parentIndexPath = [self indexPathFromRealIndexPath:indexPath];
        if ( [self isIndexFiltered:idx] && [self isObjectFiltered:object] == NO ) {
            [self.filteredIndexes removeIndex:idx];

            [self.changeSet insertAtIndexPath:parentIndexPath];
        }
        else if ( [self isIndexFiltered:idx] == NO && [self isObjectFiltered:object] ) {
            [self.filteredIndexes addIndex:idx];

            [self.changeSet removeAtIndexPath:parentIndexPath];
        }
        else {
            [self.changeSet updateAtIndexPath:parentIndexPath];
        }
    }
    [self closeBatchUpdate];
}

@end
