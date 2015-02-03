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

- (void)shiftIndexesAfter:(NSUInteger)index by:(NSUInteger)increment
{
    NSIndexSet *laterIndexes = [self.filteredIndexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return idx >= index;
    }];
    [self.filteredIndexes removeIndexes:laterIndexes];
    [laterIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self.filteredIndexes addIndex:idx + increment];
    }];
}

- (void)addFilterForIndex:(NSUInteger)index
{
    [self.filteredIndexes addIndex:index];
}

- (void)removeFilterForIndex:(NSUInteger)index
{
    [self.filteredIndexes removeIndex:index];
}

- (void)updateFilterState
{
    [self beginUpdates];
    [self.store enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
        NSUInteger childIndex = [self indexFromRealIndexPath:[NSIndexPath indexPathWithIndex:index]];
        NSIndexPath *childIndexPath = [NSIndexPath indexPathWithIndex:childIndex];

        if ( [self isObjectFiltered:object] && [self isIndexFiltered:index] == NO) {
            [self addFilterForIndex:index];
            [self.delegate assemblage:self didRemoveObject:object atIndexPath:childIndexPath];
        }
        else if ( [self isIndexFiltered:index] && [self isObjectFiltered:object] == NO) {
            [self removeFilterForIndex:index];
            [self.delegate assemblage:self didInsertObject:object atIndexPath:childIndexPath];
        }
        else {
            [self.delegate assemblage:self didUpdateObject:object atIndexPath:childIndexPath];
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
        if (idx <= index) {
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
    NSUInteger index = [self realIndexFromIndexPath:indexPath];
    indexPath = [indexPath rz_indexPathByRemovingFirstIndex];
    return [indexPath indexPathByAddingIndex:index];
}

- (BOOL)leafNodeForIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (id<RZAssemblageMutationTraversalSupport>)assemblageToTraverseForIndexPath:(NSIndexPath *)indexPath canBeEmpty:(BOOL)canBeEmpty;
{
    if ( [self.filteredAssemblage conformsToProtocol:@protocol(RZAssemblageMutationTraversalSupport)] ) {
        return (id)self.filteredAssemblage;
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
    RZLogTrace3(assemblage, object, indexPath);
    NSUInteger index = [indexPath indexAtPosition:0];
    [self.store insertObject:object atIndex:index];
    BOOL filtered = [self isObjectFiltered:object];
    if ( filtered ) {
        [self shiftIndexesAfter:index by:1];
        [self addFilterForIndex:index];
    }
    else {
        [self shiftIndexesAfter:index by:1];
        indexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
        [self.delegate assemblage:self didInsertObject:object atIndexPath:indexPath];
    }
}

- (void)assemblage:(id<RZAssemblage>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZLogTrace3(assemblage, object, indexPath);
    NSUInteger index = [indexPath indexAtPosition:0];
    BOOL filtered = [self.filteredIndexes containsIndex:index];
    [self.store removeObjectAtIndex:index];
    [self removeFilterForIndex:index];
    [self shiftIndexesAfter:index by:-1];
    if ( filtered == NO ) {
        indexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
        [self.delegate assemblage:self didRemoveObject:object atIndexPath:indexPath];
    }
}

- (void)assemblage:(id<RZAssemblage>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZLogTrace3(assemblage, object, indexPath);
    NSUInteger index = [indexPath indexAtPosition:0];
    indexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
    if ( [self isIndexFiltered:index] && [self isObjectFiltered:object] == NO ) {
        [self removeFilterForIndex:index];
        [self.delegate assemblage:self didInsertObject:object atIndexPath:indexPath];
    }
    else if ( [self isIndexFiltered:index] == NO && [self isObjectFiltered:object] ) {
        [self addFilterForIndex:index];
        [self.delegate assemblage:self didRemoveObject:object atIndexPath:indexPath];
    }
    else {
        [self.delegate assemblage:self didUpdateObject:object atIndexPath:indexPath];
    }
}

@end
