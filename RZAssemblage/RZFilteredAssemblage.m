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
        if ( [self isObjectFiltered:object] && [self isIndexFiltered:index] == NO) {
            [self.filteredIndexes addIndex:index];
            [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
        }
        else if ( [self isIndexFiltered:index] && [self isObjectFiltered:object] == NO) {
            [self.filteredIndexes removeIndex:index];
            [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
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

- (void)assemblage:(id<RZAssemblage>)assemblage didChange:(RZAssemblageChangeSet *)changeSet
{
    [changeSet.inserts.rootIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        id object = [changeSet.startingAssemblage objectAtIndexPath:[NSIndexPath indexPathWithIndex:idx]];
        [self.store insertObject:object atIndex:idx];
        BOOL filtered = [self isObjectFiltered:object];
        if ( filtered ) {
            [self.filteredIndexes addIndex:idx];

            // How do are other indexes affected?!
//            [changeSet removeInsertAtIndex:idx];
        }
    }];
    [changeSet.removes.rootIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        id object = [changeSet.startingAssemblage objectAtIndexPath:[NSIndexPath indexPathWithIndex:idx]];
        [self.store removeObjectAtIndex:idx];
        [self.filteredIndexes removeIndex:idx];
        BOOL filtered = [self isObjectFiltered:object];
        if ( filtered ) {

        }
    }];
    [changeSet.updates.rootIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        id object = [changeSet.startingAssemblage objectAtIndexPath:[NSIndexPath indexPathWithIndex:idx]];
        NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:idx];
        indexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
        if ( [self isIndexFiltered:idx] && [self isObjectFiltered:object] == NO ) {
            [self.filteredIndexes removeIndex:idx];

//            [changeSet removeUpdateAtIndex:idx];
            [changeSet insertAtIndexPath:indexPath];
        }
        else if ( [self isIndexFiltered:idx] == NO && [self isObjectFiltered:object] ) {
            [self.filteredIndexes addIndex:idx];
//            [changeSet removeUpdateAtIndex:idx];
            [changeSet removeAtIndexPath:indexPath];
        }
    }];
    [changeSet.moves.rootIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    }];
    [super assemblage:self didChange:changeSet];
}

@end
