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
        [self updateFilterState];
    }
    return self;
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

- (NSArray *)allItems
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
    [self.store enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        NSUInteger childIndex = [self indexFromRealIndexPath:[NSIndexPath indexPathWithIndex:index]];
        NSIndexPath *childIndexPath = [NSIndexPath indexPathWithIndex:childIndex];

        if ( [self isObjectFiltered:object] && [self isIndexFiltered:index] == NO) {
            [self.filteredIndexes addIndex:index];

            [self.delegate assemblage:self didRemoveObject:object atIndexPath:childIndexPath];
        }
        else if ( [self isIndexFiltered:index] && [self isObjectFiltered:object] == NO) {
            [self.filteredIndexes removeIndex:index];
            [self.delegate assemblage:self didInsertObject:object atIndexPath:childIndexPath];
        }
        else {
            [self.delegate assemblage:self didUpdateObject:object atIndexPath: [NSIndexPath indexPathWithIndex:index]];
        }
    }];
    [self endUpdates];
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
    [self.filteredIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < index) {
            index += 1;
        }
    }];
    return index;
}

- (NSIndexPath *)indexPathFromChildIndexPath:(NSIndexPath *)indexPath fromAssemblage:(id<RZAssemblage>)assemblage
{
    NSUInteger index = [self indexFromRealIndexPath:indexPath];
    indexPath = [indexPath rz_indexPathByRemovingFirstIndex];
    indexPath = [indexPath indexPathByAddingIndex:index];
    return indexPath;
}

- (NSIndexPath *)childIndexPathFromIndexPath:(NSIndexPath *)indexPath
{
    indexPath = [indexPath rz_indexPathByRemovingFirstIndex];
    return [indexPath indexPathByAddingIndex:[self realIndexFromIndexPath:indexPath]];
}

- (BOOL)leafNodeForIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (id<RZAssemblageMutationTraversal>)assemblageToTraverseForIndexPath:(NSIndexPath *)indexPath canBeEmpty:(BOOL)canBeEmpty;
{
    if ( [self.filteredAssemblage conformsToProtocol:@protocol(RZAssemblageMutationTraversal)] ) {
        return (id<RZAssemblageMutationTraversal>)self.filteredAssemblage;
    }
    return nil;
}

- (BOOL)isObjectFiltered:(id)object
{
    return self.filter && [self.filter evaluateWithObject:object] == NO;
}

- (BOOL)isIndexFiltered:(NSUInteger)index
{
    return [self.filteredIndexes containsIndex:index];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath indexAtPosition:0];
    // Update our state if this came from our delegate and not our delgate relay from update
    if ( assemblage != self ) {
        [self.store insertObject:object atIndex:index];
    }
    if ( [self isObjectFiltered:object] ) {
        [self.filteredIndexes addIndex:index];
    }
    else {
        indexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
        [self.delegate assemblage:self didInsertObject:object atIndexPath:indexPath];
    }
}

- (void)assemblage:(id<RZAssemblage>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath indexAtPosition:0];
    // Update our state if this came from our delegate and not our delgate relay from update
    if ( assemblage != self ) {
        [self.store removeObjectAtIndex:index];
    }
    if ( [self.filteredIndexes containsIndex:index] ) {
        [self.filteredIndexes removeIndex:index];
    }
    else {
        indexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
        [self.delegate assemblage:self didRemoveObject:object atIndexPath:indexPath];
    }
}

- (void)assemblage:(id<RZAssemblage>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath indexAtPosition:0];
    indexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
    if ( [self isIndexFiltered:index] && [self isObjectFiltered:object] == NO ) {
        [self.delegate assemblage:self didInsertObject:object atIndexPath:indexPath];
    }
    else if ( [self isIndexFiltered:index] == NO && [self isObjectFiltered:object] ) {
        [self.delegate assemblage:self didRemoveObject:object atIndexPath:indexPath];
    }
    else {
        [self.delegate assemblage:self didUpdateObject:object atIndexPath:indexPath];
    }
}

@end
