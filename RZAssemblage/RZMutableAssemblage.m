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
    [self insertObject:anObject atIndex:self.store.count];
}

- (void)removeLastObject
{
    [self beginUpdates];
    NSUInteger index = self.store.count - 1;
    [self.store removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self endUpdates];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    NSParameterAssert(anObject);
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self beginUpdates];
    [self.store insertObject:anObject atIndex:index];
    [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self endUpdates];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [self beginUpdates];
    [self.store removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self endUpdates];
}

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self.store indexOfObject:anObject];
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self beginUpdates];
    [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self endUpdates];
}

@end
