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

#import "RZJoinAssemblage.h"
#import "RZFilteredAssemblage.h"
#import "RZArrayAssemblage.h"
#import "RZProxyAssemblage.h"

@implementation RZAssemblage

+ (RZAssemblage *)assemblageForArray:(NSArray *)array
{
    return [self assemblageForArray:array representedObject:nil];
}

+ (RZAssemblage *)assemblageForArray:(NSArray *)array representedObject:(id)representedObject
{
    return [[RZArrayAssemblage alloc] initWithArray:array representingObject:representedObject];
}

+ (RZAssemblage *)joinedAssemblages:(NSArray *)array
{
    return [[RZJoinAssemblage alloc] initWithAssemblages:array];
}

+ (RZAssemblage *)assemblageTreeWithObject:(id)object arrayKeypaths:(NSArray *)keypaths
{
    return [[RZProxyAssemblage alloc] initWithObject:object keypaths:keypaths];
}

+ (RZAssemblage *)assemblageTreeWithObject:(id)object arrayTreeKeypath:(NSString *)keypath
{
    return [[RZProxyAssemblage alloc] initWithObject:object childKey:keypath];
}


@synthesize delegate = _delegate;

- (id)copyWithZone:(NSZone *)zone;
{
    NSMutableArray *children = [NSMutableArray array];
    NSUInteger childCount = [self countOfChildren];

    for ( NSUInteger i = 0; i < childCount; i++ ) {
        id object = [self nodeInChildrenAtIndex:i];
        if ( [object conformsToProtocol:@protocol(RZAssemblage)] ) {
            object = [object copy];
        }
        [children addObject:object];
    }

    return [[RZCopyAssemblage alloc] initWithArray:children
                                representingObject:[self representedObject]];
}

- (id)representedObject
{
    return nil;
}

#pragma mark - <RZAssemblage>

- (NSMutableArray *)mutableArrayForIndexPath:(NSIndexPath *)indexPath;
{
    NSUInteger length = [indexPath length];

    NSMutableArray *proxy = nil;

    if ( length == 0 ) {
        proxy = [self mutableArrayValueForKey:@"children"];
    }
    else {
        id<RZAssemblage> assemblage = [self nodeInChildrenAtIndex:[indexPath indexAtPosition:0]];
        proxy = [assemblage mutableArrayForIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
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
        id<RZAssemblage> assemblage = [self nodeInChildrenAtIndex:[indexPath indexAtPosition:0]];
        RZRaize([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"Invalid Index Path: %@", indexPath);
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
        id<RZAssemblage> assemblage = [self nodeInChildrenAtIndex:[indexPath indexAtPosition:0]];
        RZRaize([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"Invalid Index Path: %@", indexPath);
        object = [assemblage childAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    else {
        object = [self representedObject];
    }
    return object;
}

#pragma mark - Batching

- (void)openBatchUpdate
{
    if ( self.updateCount == 0 ) {
        self.changeSet = [[RZAssemblageChangeSet alloc] init];
        self.changeSet.startingAssemblage = [self copy];
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

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self childrenIndexOfObject:anObject];
    RZAssemblageLog(@"%p:Update %@ at %zd", self, anObject, index);
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self openBatchUpdate];
    [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    RZRaize(self.changeSet != nil, @"Must begin an update on the parent assemblage before mutating a child assemblage");
    NSUInteger assemblageIndex = [self childrenIndexOfObject:assemblage];
    [self.changeSet mergeChangeSet:changeSet withIndexPathTransform:^NSIndexPath *(NSIndexPath *indexPath) {
        return [indexPath rz_indexPathByPrependingIndex:assemblageIndex];
    }];
    [self closeBatchUpdate];
}

#pragma mark - Index Path Helpers

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [self mutableArrayForIndexPath:[indexPath indexPathByRemovingLastIndex]];
    [proxy insertObject:object atIndex:[indexPath rz_lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [self mutableArrayForIndexPath:[indexPath indexPathByRemovingLastIndex]];
    [proxy removeObjectAtIndex:[indexPath rz_lastIndex]];
}

- (void)moveObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *fproxy = [self mutableArrayForIndexPath:[fromIndexPath indexPathByRemovingLastIndex]];
    NSMutableArray *tproxy = [self mutableArrayForIndexPath:[toIndexPath indexPathByRemovingLastIndex]];

    NSObject *object = [fproxy objectAtIndex:[fromIndexPath rz_lastIndex]];
    [fproxy removeObjectAtIndex:[fromIndexPath rz_lastIndex]];
    [tproxy insertObject:object atIndex:[toIndexPath rz_lastIndex]];
}

@end

@implementation RZAssemblage (Protected)

- (NSUInteger)countOfChildren
{
    RZSubclassMustImplement(NSNotFound);
}

- (id)objectInChildrenAtIndex:(NSUInteger)index
{
    id object = [self nodeInChildrenAtIndex:index];
    if ( [object conformsToProtocol:@protocol(RZAssemblage)] ) {
        object = [object representedObject];
    }
    return object;
}

- (id<RZAssemblage>)nodeInChildrenAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement(nil);
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement();
}

- (void)insertObject:(NSObject *)object inChildrenAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement();
}

- (NSUInteger)childrenIndexOfObject:(id)object
{
    RZSubclassMustImplement(NSNotFound);
}

- (void)addMonitorsForObject:(NSObject *)anObject
{
    if ( [anObject conformsToProtocol:@protocol(RZAssemblage)] ) {
        [(id<RZAssemblage>)anObject setDelegate:self];
    }
}

- (void)removeMonitorsForObject:(NSObject *)anObject;
{
    if ( [anObject conformsToProtocol:@protocol(RZAssemblage)] ) {
        [(id<RZAssemblage>)anObject setDelegate:nil];
    }
}

@end
