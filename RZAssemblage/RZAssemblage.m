//
//  RZBaseAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageDefines.h"
#import "RZIndexPathSet.h"

#import "RZJoinAssemblage.h"
#import "RZFilterAssemblage.h"
#import "RZArrayAssemblage.h"
#import "RZProxyAssemblage.h"
#import "RZPropertyAssemblage.h"

static NSString *RZAssemblageElementsKey = @"elements";

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

+ (RZAssemblage *)assemblageWithObject:(id)object leafKeypaths:(NSArray *)keypaths
{
    return [[RZPropertyAssemblage alloc] initWithObject:object keypaths:keypaths];
}

@synthesize delegate = _delegate;

- (id)representedObject
{
    return nil;
}

#pragma mark - <RZAssemblage>

- (RZAssemblage *)assemblageAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger length = [indexPath length];
    id node = self;

    if ( length > 0 ) {
        node = [self nodeAtIndex:[indexPath indexAtPosition:0]];
        node = [node assemblageAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return node;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    RZAssemblage *parent = [self assemblageAtIndexPath:[indexPath indexPathByRemovingLastIndex]];
    return [parent objectInElementsAtIndex:[indexPath rz_lastIndex]];
}

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSIndexPath *indexPath, BOOL *stop))block;
{
    NSParameterAssert(block);
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:NULL length:0];
    [self enumerateObjectsForIndexPath:indexPath usingBlock:block];
}

- (BOOL)enumerateObjectsForIndexPath:(NSIndexPath *)indexPath usingBlock:(void (^)(id obj, NSIndexPath *indexPath, BOOL *stop))block
{
    NSParameterAssert(block);
    BOOL stop = NO;
    block(self.representedObject, indexPath, &stop);

    if ( stop == NO ) {
        for ( NSUInteger index = 0; index < self.children.count; index++ ) {
            NSIndexPath *childIndexPath = [indexPath indexPathByAddingIndex:index];
            RZAssemblage *assemblage = [self nodeAtIndex:index];
            if ( assemblage ) {
                stop = [assemblage enumerateObjectsForIndexPath:childIndexPath usingBlock:block];
            }
            else {
                id object = [self objectInElementsAtIndex:index];
                block(object, childIndexPath, &stop);
            }

            if ( stop ) {
                break;
            }
        }
    }
    return stop;
}

- (NSMutableArray *)mutableChildren
{
    return [self mutableArrayValueForKey:RZAssemblageElementsKey];
}

- (NSArray *)children
{
    return [self valueForKey:RZAssemblageElementsKey];
}

#pragma mark - Batching

- (void)openBatchUpdate
{
    if ( self.updateCount == 0 ) {
        self.changeSet = [[RZAssemblageChangeSet alloc] init];
        if ( [self.delegate respondsToSelector:@selector(willBeginUpdatesForAssemblage:)] ) {
            [self.delegate willBeginUpdatesForAssemblage:self];
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

- (void)willBeginUpdatesForAssemblage:(RZAssemblage *)assemblage
{
    [self openBatchUpdate];
}

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self elementsIndexOfObject:anObject];
    RZAssemblageLog(@"%p:Update %@ at %zd", self, anObject, index);
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self openBatchUpdate];
    [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)assemblage:(RZAssemblage *)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    RZRaize(self.changeSet != nil, @"Must begin an update on the parent assemblage before mutating a child assemblage");
    NSUInteger assemblageIndex = [self indexOfAssemblage:assemblage];
    [self.changeSet mergeChangeSet:changeSet withIndexPathTransform:^NSIndexPath *(NSIndexPath *indexPath) {
        return [indexPath rz_indexPathByPrependingIndex:assemblageIndex];
    }];
    [self closeBatchUpdate];
}

#pragma mark - Index Path Helpers

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [[self assemblageAtIndexPath:[indexPath indexPathByRemovingLastIndex]] mutableChildren];
    [proxy insertObject:object atIndex:[indexPath rz_lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [[self assemblageAtIndexPath:[indexPath indexPathByRemovingLastIndex]] mutableChildren];
    [proxy removeObjectAtIndex:[indexPath rz_lastIndex]];
}

- (void)moveObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *fproxy = [[self assemblageAtIndexPath:[fromIndexPath indexPathByRemovingLastIndex]] mutableChildren];
    NSMutableArray *tproxy = [[self assemblageAtIndexPath:[toIndexPath indexPathByRemovingLastIndex]] mutableChildren];

    NSObject *object = [fproxy objectAtIndex:[fromIndexPath rz_lastIndex]];
    [fproxy removeObjectAtIndex:[fromIndexPath rz_lastIndex]];
    [tproxy insertObject:object atIndex:[toIndexPath rz_lastIndex]];
}

@end

@implementation RZAssemblage (Protected)

- (NSUInteger)countOfElements
{
    RZSubclassMustImplement(NSNotFound);
}

- (id)objectInElementsAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement(nil);
}

- (RZAssemblage *)nodeAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement(nil);
}

- (NSUInteger)indexOfAssemblage:(RZAssemblage *)assemblage
{
    NSUInteger index = NSNotFound;
    for ( NSUInteger i = 0; i < [self countOfElements]; i++ ) {
        RZAssemblage *childAssemblage = [self assemblageAtIndexPath:[NSIndexPath indexPathWithIndex:i]];
        if ( childAssemblage == assemblage ) {
            index = i;
            break;
        }
    }
    return index;
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement();
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement();
}

- (NSUInteger)elementsIndexOfObject:(id)object
{
    RZSubclassMustImplement(NSNotFound);
}

- (void)addMonitorsForObject:(NSObject *)anObject
{
    if ( [anObject isKindOfClass:[RZAssemblage class]] ) {
        [(RZAssemblage *)anObject setDelegate:self];
    }
}

- (void)removeMonitorsForObject:(NSObject *)anObject;
{
    if ( [anObject isKindOfClass:[RZAssemblage class]] ) {
        [(RZAssemblage *)anObject setDelegate:nil];
    }
}

@end
