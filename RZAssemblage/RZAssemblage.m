//
//  RZBaseAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage+Private.h"

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
        NSUInteger lastIndex = [indexPath indexAtPosition:length - 1];
        id<RZAssemblageAccess>assemblage = self.store[lastIndex];
        NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblageAccess)], @"Invalid Index Path");
        count = [assemblage numberOfChildrenAtIndexPath:[indexPath indexPathByRemovingLastIndex]];
    }
    return count;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger length = [indexPath length];
    NSUInteger lastIndex = [indexPath indexAtPosition:length - 1];
    id object = self.store[lastIndex];
    if ( length > 1 ) {
        id<RZAssemblageAccess>assemblage = object;
        NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblageAccess)], @"Invalid Index Path");
        return [assemblage objectAtIndexPath:[indexPath indexPathByRemovingLastIndex]];
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

- (NSIndexPath *)appendIndexPath:(NSIndexPath *)indexPath forAssemblage:(id<RZAssemblageAccess>)assemblage
{
    return [indexPath indexPathByAddingIndex:[self indexForObject:assemblage]];
}

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblageAccess>)assemblage
{
    if ( self.updateCount == 0 ) {
        [self.delegate willBeginUpdatesForAssemblage:self];
    }
    self.updateCount += 1;
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *newIndexPath = [self appendIndexPath:indexPath forAssemblage:assemblage];
    [self.delegate assemblage:self didInsertObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *newIndexPath = [self appendIndexPath:indexPath forAssemblage:assemblage];
    [self.delegate assemblage:self didRemoveObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *newIndexPath = [self appendIndexPath:indexPath forAssemblage:assemblage];
    [self.delegate assemblage:self didUpdateObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSIndexPath *newFromIndexPath = [self appendIndexPath:fromIndexPath forAssemblage:assemblage];
    NSIndexPath *newToIndexPath = [self appendIndexPath:toIndexPath forAssemblage:assemblage];
    [self.delegate assemblage:self didMoveObject:object fromIndexPath:newFromIndexPath toIndexPath:newToIndexPath];
}

- (void)didEndUpdatesForEnsemble:(id<RZAssemblageAccess>)assemblage
{
    self.updateCount -= 1;

    if ( self.updateCount == 0 ) {
        [self.delegate didEndUpdatesForEnsemble:self];
    }
}

@end
