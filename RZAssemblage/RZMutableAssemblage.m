//
//  RZMutableAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZMutableAssemblage.h"
#import "RZAssemblage+Private.h"
#import "NSIndexPath+RZAssemblage.h"

@interface RZMutableAssemblage()

@property (copy, nonatomic) NSMutableArray *store;

@end

@implementation RZMutableAssemblage

- (instancetype)initWithArray:(NSArray *)array
{
    NSParameterAssert(array);
    self = [super initWithArray:array];
    if ( self ) {
        _store = [array mutableCopy];
    }
    return self;
}

#pragma mark - Basic Mutation

- (void)addObject:(id)anObject
{
    NSParameterAssert(anObject);
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self willBeginUpdatesForAssemblage:self];
    [self.store addObject:anObject];
    NSUInteger index = self.store.count - 1;
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

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    NSParameterAssert(anObject);
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self willBeginUpdatesForAssemblage:self];
    [self.store insertObject:anObject atIndex:index];
    [self.delegate assemblage:self didInsertObject:anObject atIndexPath:[NSIndexPath indexPathWithIndex:index]];
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

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self.store indexOfObject:anObject];
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self willBeginUpdatesForAssemblage:self];
    [self.delegate assemblage:self didUpdateObject:anObject atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self didEndUpdatesForEnsemble:self];
}

@end
