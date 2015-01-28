//
//  RZBaseAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage+Private.h"

@implementation NSIndexPath(RZAssemblage)

- (NSIndexPath *)rz_indexPathByRemovingFirstIndex
{
    NSIndexPath *remainingIndexPath = nil;
    if ( self.length > 0 ) {
        NSUInteger *indexes = calloc(self.length, sizeof(NSUInteger));
        [self getIndexes:indexes];
        remainingIndexPath = [NSIndexPath indexPathWithIndexes:indexes + 1 length:self.length - 1];
        free(indexes);
    }
    return remainingIndexPath;
}

- (NSIndexPath *)rz_indexPathByPrependingIndex:(NSUInteger)index
{
    NSIndexPath *indexPath = nil;
    NSUInteger *indexes = calloc(self.length + 1, sizeof(NSUInteger));
    [self getIndexes:indexes + 1];
    indexes[0] = index;
    indexPath = [NSIndexPath indexPathWithIndexes:indexes length:self.length + 1];
    free(indexes);
    return indexPath;
}

- (NSUInteger)rz_lastIndex
{
    return self.length == 0 ? NSNotFound : [self indexAtPosition:self.length - 1];
}

@end

@implementation RZAssemblage

- (id)initWithArray:(NSArray *)array
{
    self = [super init];
    if ( self ) {
        _store = [array copy];
        for ( id object in _store ) {
            [self assignDelegateIfObjectIsAssemblage:object];
        }
    }
    return self;
}

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath;
{
    NSUInteger count = NSNotFound;
    NSUInteger length = [indexPath length];

    if ( length == 0 ) {
        count = self.store.count;
    }
    else {
        NSUInteger index = [indexPath indexAtPosition:0];
        RZAssemblage *assemblage = self.store[index];
        NSAssert([assemblage isKindOfClass:[RZAssemblage class]], @"Invalid Index Path");
        count = [assemblage numberOfChildrenAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return count;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger length = [indexPath length];
    id object = nil;
    if ( length > 0 ) {
        NSUInteger lastIndex = [indexPath indexAtPosition:0];
        object = self.store[lastIndex];
        if ( length > 1 ) {
            RZAssemblage *assemblage = object;
            NSAssert([assemblage isKindOfClass:[RZAssemblage class]], @"Invalid Index Path");
            object = [assemblage objectAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
        }
    }
    return object;
}

- (NSUInteger)indexForObject:(id)object
{
    return [self.store indexOfObject:object];
}

- (void)assignDelegateIfObjectIsAssemblage:(id)anObject
{
    if ( [anObject isKindOfClass:[RZAssemblage class]] ) {
        [(RZAssemblage *)anObject setDelegate:self];
    }
}

- (void)willBeginUpdatesForAssemblage:(RZAssemblage *)assemblage
{
    if ( self.updateCount == 0 ) {
        [self.delegate willBeginUpdatesForAssemblage:self];
    }
    self.updateCount += 1;
}

- (void)assemblage:(RZAssemblage *)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *newIndexPath = [indexPath rz_indexPathByPrependingIndex:[self indexForObject:assemblage]];
    [self.delegate assemblage:self didInsertObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(RZAssemblage *)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *newIndexPath = [indexPath rz_indexPathByPrependingIndex:[self indexForObject:assemblage]];
    [self.delegate assemblage:self didRemoveObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(RZAssemblage *)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *newIndexPath = [indexPath rz_indexPathByPrependingIndex:[self indexForObject:assemblage]];
    [self.delegate assemblage:self didUpdateObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(RZAssemblage *)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSIndexPath *newFromIndexPath = [fromIndexPath rz_indexPathByPrependingIndex:[self indexForObject:assemblage]];
    NSIndexPath *newToIndexPath = [toIndexPath rz_indexPathByPrependingIndex:[self indexForObject:assemblage]];
    [self.delegate assemblage:self didMoveObject:object fromIndexPath:newFromIndexPath toIndexPath:newToIndexPath];
}

- (void)didEndUpdatesForEnsemble:(RZAssemblage *)assemblage
{
    self.updateCount -= 1;

    if ( self.updateCount == 0 ) {
        [self.delegate didEndUpdatesForEnsemble:self];
    }
}

@end
