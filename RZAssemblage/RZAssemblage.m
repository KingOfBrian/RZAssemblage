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
        _childrenStorage = [array mutableCopy];
        for ( id object in _childrenStorage ) {
            [self assignDelegateIfObjectIsAssemblage:object];
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p - %@>", self.class, self, self.childrenStorage];
}

- (id)copyWithZone:(NSZone *)zone;
{
    RZAssemblage *copy = [[self class] allocWithZone:zone];

    // Copy the store.   Do a deep copy of any assemblages that are in the store.
    // This is not good.
    NSMutableArray *children = [NSMutableArray arrayWithArray:self.childrenStorage];
    NSUInteger index = 0;
    for ( id object in self.childrenStorage ) {
        if ( [object conformsToProtocol:@protocol(RZAssemblage)] ) {
            id assemblageCopy = [object copy];
            [children replaceObjectAtIndex:index withObject:assemblageCopy];
        }
        index++;
    }
    copy->_childrenStorage = [self.childrenStorage isKindOfClass:[NSMutableArray class]] ? children : [children copy];
    return copy;
}

#pragma mark - <RZAssemblage>

- (id)representedObject
{
    return self;
}

- (NSArray *)arrayProxyForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger length = [indexPath length];

    NSArray *proxy = nil;

    if ( length == 0 ) {
        proxy = [self mutableArrayValueForKey:@"children"];
    }
    else {
        id<RZAssemblage> assemblage = [self objectInChildrenAtIndex:[indexPath indexAtPosition:0]];
        proxy = [assemblage arrayProxyForIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return proxy;
}

- (NSMutableArray *)mutableArrayProxyForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger length = [indexPath length];

    NSMutableArray *proxy = nil;

    if ( length == 0 ) {
        proxy = [self mutableArrayValueForKey:@"children"];
    }
    else {
        id<RZAssemblage> assemblage = [self objectInChildrenAtIndex:[indexPath indexAtPosition:0]];
        proxy = [assemblage mutableArrayProxyForIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return proxy;
}

- (NSUInteger)childCountAtIndexPath:(NSIndexPath *)indexPath;
{
    NSUInteger count = NSNotFound;
    NSUInteger length = [indexPath length];

    if ( length == 0 ) {
        count = self.countOfChildren;
    }
    else {
        id<RZAssemblage> assemblage = [self objectInChildrenAtIndex:[indexPath indexAtPosition:0]];
        NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"Invalid Index Path: %@", indexPath);
        count = [assemblage childCountAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return count;
}

- (id)childAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger length = [indexPath length];
    id object = nil;
    if ( length == 1 ) {
        object = [self objectInChildrenAtIndex:[indexPath indexAtPosition:0]];
    }
    else if ( length > 1 ) {
        id<RZAssemblage> assemblage = [self.childrenStorage objectAtIndex:[indexPath indexAtPosition:0]];
        NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"Invalid Index Path: %@", indexPath);
        object = [assemblage childAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    else if ( length == 0 && indexPath != nil ) {
        object = [self representedObject];
    }
    return object;
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

#pragma mark - Array Key Value Coding

- (NSUInteger)countOfChildren
{
    return self.childrenStorage.count;
}

- (id)objectInChildrenAtIndex:(NSUInteger)index
{
    return [self.childrenStorage objectAtIndex:index];
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Remove %@ at %zd", self, [self objectInChildrenAtIndex:index],  index);
    [self openBatchUpdate];
    [self.childrenStorage removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)insertObject:(NSObject *)object inChildrenAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Insert %@ at %zd", self, object, index);
    NSParameterAssert(object);
    [self assignDelegateIfObjectIsAssemblage:object];
    [self openBatchUpdate];
    [self.childrenStorage insertObject:object atIndex:index];
    [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self.childrenStorage indexOfObject:anObject];
    RZAssemblageLog(@"%p:Update %@ at %zd", self, anObject, index);
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self openBatchUpdate];
    [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}


#pragma mark - Private

- (NSUInteger)indexForChildAssemblage:(id<RZAssemblage>)assemblage
{
    NSAssert([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"%@ does not conform to <RZAssemblage>", assemblage);
    return [self.childrenStorage indexOfObject:assemblage];
}

- (void)assignDelegateIfObjectIsAssemblage:(id)anObject
{
    if ( [anObject conformsToProtocol:@protocol(RZAssemblage)] ) {
        [(id<RZAssemblage>)anObject setDelegate:self];
    }
}

#pragma mark - Index Path Helpers

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [self mutableArrayProxyForIndexPath:[indexPath indexPathByRemovingLastIndex]];
    [proxy insertObject:object atIndex:[indexPath rz_lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [self mutableArrayProxyForIndexPath:[indexPath indexPathByRemovingLastIndex]];
    [proxy removeObjectAtIndex:[indexPath rz_lastIndex]];
}

- (void)moveObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *fproxy = [self mutableArrayProxyForIndexPath:[fromIndexPath indexPathByRemovingLastIndex]];
    NSMutableArray *tproxy = [self mutableArrayProxyForIndexPath:[toIndexPath indexPathByRemovingLastIndex]];

    NSObject *object = [fproxy objectAtIndex:[fromIndexPath rz_lastIndex]];
    [fproxy removeObjectAtIndex:[fromIndexPath rz_lastIndex]];
    [tproxy insertObject:object atIndex:[toIndexPath rz_lastIndex]];
}

@end

@implementation RZAssemblage (Legacy)

- (void)addObject:(id)object
{
    NSMutableArray *proxy = [self mutableArrayProxyForIndexPath:nil];
    [proxy addObject:object];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index
{
    NSMutableArray *proxy = [self mutableArrayProxyForIndexPath:nil];
    [proxy insertObject:object atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    NSMutableArray *proxy = [self mutableArrayProxyForIndexPath:nil];
    [proxy removeObjectAtIndex:index];
}

- (void)removeLastObject
{
    NSMutableArray *proxy = [self mutableArrayProxyForIndexPath:nil];
    [proxy removeLastObject];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [self childAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
}

@end
