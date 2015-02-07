//
//  RZBaseAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageProtocols.h"
#import "RZAssemblageDefines.h"

@implementation RZAssemblage

@synthesize delegate = _delegate;

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

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ - %@", super.description, self.store];
}

#pragma mark - <RZAssemblage>

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath;
{
    NSUInteger count = NSNotFound;
    NSUInteger length = [indexPath length];

    if ( length == 0 ) {
        count = [self numberOfChildren];
    }
    else {
        id<RZAssemblage> assemblage = [self objectAtIndex:[indexPath indexAtPosition:0]];
        NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"Invalid Index Path: %@", indexPath);
        count = [assemblage numberOfChildrenAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return count;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger length = [indexPath length];
    id object = nil;
    if ( length == 1 ) {
        object = [self objectAtIndex:[indexPath indexAtPosition:0]];
    }
    else if ( length > 1 ) {
        id<RZAssemblage> assemblage = [self objectAtIndex:[indexPath indexAtPosition:0]];
        NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"Invalid Index Path: %@", indexPath);
        object = [assemblage objectAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return object;
}

- (NSArray *)allItems
{
    return [self.store copy];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [self.store objectAtIndex:index];
}

- (NSUInteger)numberOfChildren
{
    return self.store.count;
}

#pragma mark - Private

- (NSUInteger)indexForChildAssemblage:(id<RZAssemblage>)assemblage
{
    NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"%@ does not conform to <RZAssemblage>", assemblage);
    return [self.store indexOfObject:assemblage];
}

- (void)assignDelegateIfObjectIsAssemblage:(id)anObject
{
    if ( [anObject conformsToProtocol:@protocol(RZAssemblage)] ) {
        [(id<RZAssemblage>)anObject setDelegate:self];
    }
}

#pragma mark - RZAssemblageMutationTraversalSupport

- (NSIndexPath *)indexPathFromChildIndexPath:(NSIndexPath *)indexPath fromAssemblage:(id<RZAssemblage>)assemblage
{
    return [indexPath rz_indexPathByPrependingIndex:[self indexForChildAssemblage:assemblage]];
}

- (NSIndexPath *)childIndexPathFromIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath rz_indexPathByRemovingFirstIndex];
}

- (id<RZAssemblageMutationTraversalSupport>)assemblageToTraverseForIndexPath:(NSIndexPath *)indexPath canBeEmpty:(BOOL)canBeEmpty
{
    return [self objectAtIndex:[indexPath indexAtPosition:0]];
}

#pragma mark - Index Path Mutation

- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
{
    RZIndexPathWithLength(indexPath);
    NSIndexPath *childIndexPath = [self childIndexPathFromIndexPath:indexPath];

    if ( childIndexPath.length == 1 ) {
        RZConformMutationSupport(self);
        id<RZMutableAssemblageSupport> assemblage = (id)self;
        NSUInteger index = [indexPath indexAtPosition:0];
        [assemblage insertObject:anObject atIndex:index];
    }
    else {
        id<RZAssemblageMutationTraversalSupport> assemblage = [self assemblageToTraverseForIndexPath:indexPath canBeEmpty:YES];
        RZConformTraversal(assemblage);
        [assemblage insertObject:anObject atIndexPath:childIndexPath];
    }
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RZIndexPathWithLength(indexPath);
    NSIndexPath *childIndexPath = [self childIndexPathFromIndexPath:indexPath];
    if ( childIndexPath.length == 1 ) {
        id<RZMutableAssemblageSupport> assemblage = (id)self;
        RZConformMutationSupport(assemblage);
        NSUInteger index = [indexPath indexAtPosition:0];
        [assemblage removeObjectAtIndex:index];
    }
    else {
        id<RZAssemblageMutationTraversalSupport> assemblage = [self assemblageToTraverseForIndexPath:indexPath canBeEmpty:NO];
        RZConformTraversal(assemblage);
        [assemblage removeObjectAtIndexPath:childIndexPath];
    }
}

- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2
{
    [self beginUpdates];
    id object = [self objectAtIndexPath:indexPath1];
    [self removeObjectAtIndexPath:indexPath1];
    [self insertObject:object atIndexPath:indexPath2];
    [self endUpdates];
}

#pragma mark - Delegation

- (void)beginUpdates
{
    self.changeSet = self.changeSet ?: [[RZAssemblageChangeSet alloc] init];
    [self.changeSet beginUpdateWithAssemblage:self];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didChange:(RZAssemblageChangeSet *)changeSet
{
    NSUInteger assemblageIndex = [self indexForChildAssemblage:assemblage];
    [self.changeSet mergeChangeSet:changeSet fromIndex:assemblageIndex];
}

- (void)endUpdates
{
    [self.changeSet endUpdateWithAssemblage:self];
    if ( self.changeSet.updateCount == 0 ) {
        [self.delegate assemblage:self didChange:self.changeSet];
        self.changeSet = nil;
    }
}


@end
