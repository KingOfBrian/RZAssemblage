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

- (NSIndexPath *)indexPathFromChildIndexPath:(NSIndexPath *)indexPath fromAssemblage:(id<RZAssemblage>)assemblage
{
    return [indexPath rz_indexPathByPrependingIndex:[self indexForChildAssemblage:assemblage]];
}

- (NSIndexPath *)childIndexPathFromIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath rz_indexPathByRemovingFirstIndex];
}

- (BOOL)leafNodeForIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath length] == 1;
}

- (id<RZAssemblageMutationTraversalSupport>)assemblageToTraverseForIndexPath:(NSIndexPath *)indexPath canBeEmpty:(BOOL)canBeEmpty
{
    return [self objectAtIndex:[indexPath indexAtPosition:0]];
}

- (void)beginUpdates
{
    [self willBeginUpdatesForAssemblage:self];
}

#pragma mark - Index Path Mutation


- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
{
    RZIndexPathWithLength(indexPath);
    NSUInteger index = [indexPath indexAtPosition:0];
    if ( [self leafNodeForIndexPath:indexPath] ) {
        RZConformMutationSupport(self);
        id<RZMutableAssemblageSupport> assemblage = (id)self;
        [assemblage insertObject:anObject atIndex:index];
    }
    else {
        id<RZAssemblageMutationTraversalSupport> assemblage = [self assemblageToTraverseForIndexPath:indexPath canBeEmpty:YES];
        RZConformTraversal(assemblage);
        NSIndexPath *childIndexPath = [self childIndexPathFromIndexPath:indexPath];
        [assemblage insertObject:anObject atIndexPath:childIndexPath];
    }
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RZIndexPathWithLength(indexPath);
    NSUInteger index = [indexPath indexAtPosition:0];
    if ( [self leafNodeForIndexPath:indexPath] ) {
        id<RZMutableAssemblageSupport> assemblage = (id)self;
        RZConformMutationSupport(assemblage);
        [assemblage removeObjectAtIndex:index];
    }
    else {
        id<RZAssemblageMutationTraversalSupport> assemblage = [self assemblageToTraverseForIndexPath:indexPath canBeEmpty:NO];
        RZConformTraversal(assemblage);
        NSIndexPath *childIndexPath = [self childIndexPathFromIndexPath:indexPath];
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

- (void)endUpdates
{
    [self didEndUpdatesForEnsemble:self];
}

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblage>)assemblage
{
    RZLogTrace1(assemblage);

    if ( self.updateCount == 0 ) {
        [self.delegate willBeginUpdatesForAssemblage:self];
    }
    self.updateCount += 1;
}

- (void)assemblage:(id<RZAssemblage>)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZLogTrace3(assemblage, object, indexPath);

    NSIndexPath *newIndexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
    [self.delegate assemblage:self didInsertObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZLogTrace3(assemblage, object, indexPath);

    NSIndexPath *newIndexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
    [self.delegate assemblage:self didRemoveObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZLogTrace3(assemblage, object, indexPath);
    NSIndexPath *newIndexPath = [self indexPathFromChildIndexPath:indexPath fromAssemblage:assemblage];
    [self.delegate assemblage:self didUpdateObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    RZLogTrace4(assemblage, object, fromIndexPath, toIndexPath);

    NSIndexPath *newFromIndexPath = [self indexPathFromChildIndexPath:fromIndexPath fromAssemblage:assemblage];
    NSIndexPath *newToIndexPath = [self indexPathFromChildIndexPath:toIndexPath fromAssemblage:assemblage];
    [self.delegate assemblage:self didMoveObject:object fromIndexPath:newFromIndexPath toIndexPath:newToIndexPath];
}

- (void)didEndUpdatesForEnsemble:(id<RZAssemblage>)assemblage
{
    RZLogTrace1(assemblage);
    self.updateCount -= 1;

    if ( self.updateCount == 0 ) {
        [self.delegate didEndUpdatesForEnsemble:self];
    }
}

@end
