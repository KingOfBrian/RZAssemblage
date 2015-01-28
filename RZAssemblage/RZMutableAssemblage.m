//
//  RZMutableAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZMutableAssemblage.h"
#import "RZAssemblage+Private.h"

@interface RZMutableAssemblage()

@property (copy, nonatomic) NSMutableArray *store;

@end

@implementation RZMutableAssemblage

- (instancetype)initWithArray:(NSArray *)array
{
    self = [super init];
    if ( self ) {
        _store = [array mutableCopy];
    }
    return self;
}

- (void)beginUpdateAndEndUpdateNextRunloop
{
    [self willBeginUpdatesForAssemblage:self];
    [self performSelector:@selector(didEndUpdatesForEnsemble:) withObject:self afterDelay:0.0];
}

- (void)beginUpdates
{
    [self willBeginUpdatesForAssemblage:self];
}

- (void)endUpdates
{
    [self didEndUpdatesForEnsemble:self];
}

- (void)assignDelegateIfObjectIsAssemblage:(id)anObject
{
    if ( [anObject isKindOfClass:[RZAssemblage class]] ) {
        [(RZAssemblage *)anObject setDelegate:self];
    }
}

- (void)addObject:(id)anObject
{
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self willBeginUpdatesForAssemblage:self];
    [self.store addObject:anObject];
    NSUInteger index = self.store.count - 1;
    [self.delegate assemblage:self didInsertObject:anObject atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self willBeginUpdatesForAssemblage:self];
    [self.store insertObject:anObject atIndex:index];
    [self.delegate assemblage:self didInsertObject:anObject atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)removeLastObject
{
    [self willBeginUpdatesForAssemblage:self];
    NSUInteger index = self.store.count - 1;
    id object = [self.store objectAtIndex:index];
    [self.store removeObjectAtIndex:index];
    [self.delegate assemblage:self didRemoveObject:object atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [self willBeginUpdatesForAssemblage:self];
    id object = [self.store objectAtIndex:index];
    [self.store removeObjectAtIndex:index];
    [self.delegate assemblage:self didRemoveObject:object atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2
{
    [self willBeginUpdatesForAssemblage:self];
    id object = [self.store objectAtIndex:idx1];
    [self.store exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
    [self.delegate assemblage:self didMoveObject:object
                fromIndexPath:[NSIndexPath indexPathWithIndex:idx1]
                  toIndexPath:[NSIndexPath indexPathWithIndex:idx2]];
    [self didEndUpdatesForEnsemble:self];
}

- (void)notifyObjectUpdate:(id)object
{
    NSUInteger index = [self.store indexOfObject:object];
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self willBeginUpdatesForAssemblage:self];
    [self.delegate assemblage:self didUpdateObject:object atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

@end
