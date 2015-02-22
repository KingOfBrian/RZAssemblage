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
#import "RZIndexPathSet.h"

@implementation RZAssemblage

@synthesize delegate = _delegate;

- (id)initWithArray:(NSArray *)array
{
    self = [super init];
    if ( self ) {
        _store = [array mutableCopy];
        for ( id object in _store ) {
            [self assignDelegateIfObjectIsAssemblage:object];
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p - %@>", self.class, self, self.store];
}

- (id)copyWithZone:(NSZone *)zone;
{
    RZAssemblage *copy = [[self class] allocWithZone:zone];

    // Copy the store.   Do a deep copy of any assemblages that are in the store.
    // This is not good.
    NSMutableArray *store = [NSMutableArray arrayWithArray:self.store];
    NSUInteger index = 0;
    for ( id object in self.store ) {
        if ( [object conformsToProtocol:@protocol(RZAssemblage)] ) {
            id assemblageCopy = [object copy];
            [store replaceObjectAtIndex:index withObject:assemblageCopy];
        }
        index++;
    }
    copy->_store = [self.store isKindOfClass:[NSMutableArray class]] ? store : [store copy];
    return copy;
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
        id<RZAssemblage> assemblage = [self.store objectAtIndex:[indexPath indexAtPosition:0]];
        NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"Invalid Index Path: %@", indexPath);
        object = [assemblage objectAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    else if ( length == 0 && indexPath != nil ) {
        object = self;
    }
    return object;
}

- (NSArray *)allObjects
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

#pragma mark - <RZAssemblageMutationRelay>

- (void)lookupIndexPath:(NSIndexPath *)indexPath forRemoval:(BOOL)forRemoval
             assemblage:(out id<RZAssemblage> *)assemblage newIndexPath:(out NSIndexPath **)newIndexPath;
{
    NSUInteger index = [indexPath indexAtPosition:0];
    indexPath = [indexPath rz_indexPathByRemovingFirstIndex];
    if ( index < self.store.count ) {
        id<RZAssemblageMutationRelay> nextAssemblage = [self.store objectAtIndex:index];
        if ( [nextAssemblage conformsToProtocol:@protocol(RZAssemblageMutationRelay)] ) {
            [nextAssemblage lookupIndexPath:indexPath forRemoval:forRemoval
                                 assemblage:assemblage newIndexPath:newIndexPath];
            return;
        }
    }
    *newIndexPath = [NSIndexPath indexPathWithIndex:index];
    *assemblage = self;
}

#pragma mark - Batching

- (void)openBatchUpdate
{
    if ( self.updateCount == 0 ) {
        self.changeSet = [[RZAssemblageChangeSet alloc] init];
        self.changeSet.startingAssemblage = self;
        if ( [self.delegate respondsToSelector:@selector(willBeginUpdatesForAssemblage:)] ) {
            [self.delegate willBeginUpdatesForAssemblage:self.changeSet.startingAssemblage];
        }
    }
    self.updateCount += 1;
}

- (void)closeBatchUpdate
{
    self.updateCount -= 1;
    if ( self.updateCount == 0 ) {
        RZAssemblageLog(@"Change:%@ -> %p:\n%@", self, self.delegate, self.changeSet);
        [self.delegate assemblage:self didEndUpdatesWithChangeSet:self.changeSet];
        self.changeSet = nil;
    }
}

#pragma mark - RZAssemblageDelegate

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblage>)assemblage
{
    [self openBatchUpdate];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    RZRaize(self.changeSet != nil, @"Must begin an update on the parent assemblage before mutating a child assemblage");
    NSUInteger assemblageIndex = [self indexForChildAssemblage:assemblage];
    [self.changeSet mergeChangeSet:changeSet withIndexPathTransform:^NSIndexPath *(NSIndexPath *indexPath) {
        return [indexPath rz_indexPathByPrependingIndex:assemblageIndex];
    }];
    [self closeBatchUpdate];
}

#pragma mark - Mutation

- (void)addObject:(id)anObject
{
    [self insertObject:anObject atIndex:self.store.count];
}

- (void)removeLastObject
{
    [self openBatchUpdate];
    NSUInteger index = self.store.count - 1;
    [self.store removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Insert %@ at %zd", self, anObject, index);
    NSParameterAssert(anObject);
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self openBatchUpdate];
    [self.store insertObject:anObject atIndex:index];
    [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Remove at %zd", self, index);
    [self openBatchUpdate];
    [self.store removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self.store indexOfObject:anObject];
    RZAssemblageLog(@"%p:Update %@ at %zd", self, anObject, index);
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self openBatchUpdate];
    [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
{
    RZAssemblageLog(@"Insert %@ at %@", anObject, indexPath);
    id<RZAssemblage> assemblage = nil;
    NSIndexPath *newIndexPath = nil;

    [self lookupIndexPath:indexPath forRemoval:NO
               assemblage:&assemblage newIndexPath:&newIndexPath];

    RZConformMutationSupportAtIndexPath(assemblage, indexPath);
    id<RZAssemblageMutation> mutable = (id)assemblage;
    [mutable insertObject:anObject atIndex:[newIndexPath rz_lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RZAssemblageLog(@"Remove %@", indexPath);
    id<RZAssemblage> assemblage = nil;
    NSIndexPath *newIndexPath = nil;

    [self lookupIndexPath:indexPath forRemoval:YES
               assemblage:&assemblage newIndexPath:&newIndexPath];

    RZConformMutationSupportAtIndexPath(assemblage, indexPath);
    id<RZAssemblageMutation> mutable = (id)assemblage;
    [mutable removeObjectAtIndex:[newIndexPath rz_lastIndex]];
}

- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2
{
    if ( [indexPath1 isEqual:indexPath2] ) {
        return;
    }
    RZAssemblageLog(@"Move %@ -> %@", indexPath1, indexPath2);
    [self openBatchUpdate];
    id object = [self objectAtIndexPath:indexPath1];
    [self removeObjectAtIndexPath:indexPath1];
    [self insertObject:object atIndexPath:indexPath2];
    [self closeBatchUpdate];
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

@end
