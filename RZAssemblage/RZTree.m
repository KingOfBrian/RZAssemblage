//
//  RZTree.m
//  RZTree
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTree+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageDefines.h"
#import "RZIndexPathSet.h"

#import "RZJoinedTree.h"
#import "RZFilterTree.h"
#import "RZArrayBackedTree.h"
#import "RZProxyTree.h"
#import "RZPropertyTree.h"
#import "RZFRCTree.h"

static NSString *RZAssemblageElementsKey = @"elements";

@implementation RZTree

+ (nonnull RZTree *)nodeWithChildren:(nonnull NSArray *)array
{
    return [self nodeWithObject:nil children:array];
}

+ (nonnull RZTree *)nodeWithObject:(nullable id)representedObject children:(nonnull NSArray *)array;
{
    return [[RZArrayBackedTree alloc] initWithChildren:array representingObject:representedObject];
}

+ (nonnull RZTree *)nodeBackedByFetchedResultsController:(nonnull NSFetchedResultsController *)frc
{
    return [[RZFRCTree alloc] initWithFetchedResultsController:frc];
}

+ (nonnull RZTree *)nodeWithJoinedNodes:(nonnull NSArray *)joinedNodes
{
    return [[RZJoinedTree alloc] initWithNodes:joinedNodes];
}

+ (nonnull RZTree *)nodeWithObject:(nonnull id)object descendingKeypaths:(nonnull NSArray *)keypaths
{
    return [[RZProxyTree alloc] initWithObject:object keypaths:keypaths];
}

+ (nonnull RZTree *)nodeWithObject:(nonnull id)object repeatingKeypath:(nonnull NSString *)keypath
{
    return [[RZProxyTree alloc] initWithObject:object childKey:keypath];
}

+ (nonnull RZTree *)nodeWithObject:(nonnull id)object leafKeypaths:(nonnull NSArray *)keypaths
{
    return [[RZPropertyTree alloc] initWithObject:object keypaths:keypaths];
}

+ (nonnull RZTree<RZFilterableTree> *)filterableNodeWithNode:(nonnull RZTree *)node;
{
    return [[RZFilterTree alloc] initWithAssemblage:node];
}

- (nullable id)representedObject
{
    return nil;
}

#pragma mark - <RZTree>

- (nonnull RZTree *)nodeAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSUInteger length = [indexPath length];
    RZTree *assemblage = self;

    if ( length > 0 ) {
        assemblage = [self nodeAtIndex:[indexPath indexAtPosition:0]];
        assemblage = [assemblage nodeAtIndexPath:[indexPath rz_indexPathByRemovingFirstIndex]];
    }
    return assemblage;
}

- (nullable id)objectAtIndexPath:(nullable NSIndexPath *)indexPath
{
    RZTree *parent = [self nodeAtIndexPath:[indexPath indexPathByRemovingLastIndex]];
    return [parent objectInElementsAtIndex:[indexPath rz_lastIndex]];
}

- (void)enumerateObjectsUsingBlock:(nonnull void (^)(id __nullable obj, NSIndexPath * __nonnull indexPath, BOOL * __nonnull stop))block
{
    [self enumerateObjectsWithOptions:RZTreeEnumerationNoOptions usingBlock:block];
}

- (void)enumerateObjectsWithOptions:(RZTreeEnumerationOptions)options usingBlock:(nonnull void (^)(id __nullable obj, NSIndexPath * __nonnull indexPath, BOOL * __nonnull stop))block;
{
    NSParameterAssert(block);
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:NULL length:0];
    [self enumerateObjectsWithOptions:options forIndexPath:indexPath usingBlock:block];
}

- (BOOL)enumerateObjectsWithOptions:(RZTreeEnumerationOptions)options forIndexPath:(NSIndexPath *)indexPath usingBlock:(void (^)(id obj, NSIndexPath *indexPath, BOOL *stop))block
{
    NSParameterAssert(block);
    BOOL stop = NO;

    BOOL includeNil = ((options & RZTreeEnumerationIncludeNilRepresentedObject) == RZTreeEnumerationIncludeNilRepresentedObject);
    BOOL breadthFirst = ((options & RZTreeEnumerationBreadthFirst) == RZTreeEnumerationBreadthFirst);

    if ( self.representedObject || includeNil ) {
        block(self.representedObject, indexPath, &stop);
    }

    if ( stop == NO ) {
        for ( NSUInteger index = 0; index < self.children.count; index++ ) {
            NSIndexPath *childIndexPath = [indexPath indexPathByAddingIndex:index];
            RZTree *assemblage = [self nodeAtIndex:index];
            if ( assemblage ) {
                if ( breadthFirst == NO ) {
                    stop = [assemblage enumerateObjectsWithOptions:options forIndexPath:childIndexPath usingBlock:block];
                }
            }
            else {
                id object = [self objectInElementsAtIndex:index];
                if ( object || includeNil ) {
                    block(object, childIndexPath, &stop);
                }
            }

            if ( stop ) {
                break;
            }
        }
        if ( breadthFirst && stop == NO ) {
            for ( NSUInteger index = 0; index < self.children.count; index++ ) {
                NSIndexPath *childIndexPath = [indexPath indexPathByAddingIndex:index];
                RZTree *assemblage = [self nodeAtIndex:index];
                if ( [assemblage enumerateObjectsWithOptions:options forIndexPath:childIndexPath usingBlock:block] ) {
                    stop = YES;
                    break;
                }
            }
        }
    }
    return stop;
}

- (nonnull RZTree *)objectAtIndexedSubscript:(NSUInteger)index
{
    return [self nodeAtIndex:index];
}

- (nullable id)objectForKeyedSubscript:(nonnull NSIndexPath *)indexPath
{
    return [self objectAtIndexPath:indexPath];
}

- (nullable NSMutableArray *)mutableChildren
{
    return [self mutableArrayValueForKey:RZAssemblageElementsKey];
}

- (nonnull NSArray *)children
{
    return [self valueForKey:RZAssemblageElementsKey];
}

#pragma mark - Batching

- (void)openBatchUpdate
{
    if ( self.updateCount == 0 ) {
        self.changeSet = [[RZChangeSet alloc] init];
        for ( id<RZTreeObserver>observer in self.observers ) {
            if ( [observer respondsToSelector:@selector(willBeginUpdatesForNode:)] ) {
                [observer willBeginUpdatesForNode:self];
            }
        }
    }
    self.updateCount += 1;
}

- (void)closeBatchUpdate
{
    self.updateCount -= 1;
    if ( self.updateCount == 0 ) {
        for ( id<RZTreeObserver>observer in self.observers ) {
            RZAssemblageLog(@"Change:%@ -> %p:\n%@", self, observer, self.changeSet);
            [observer node:self didEndUpdatesWithChangeSet:self.changeSet];
        }
        self.changeSet = nil;
    }
}

#pragma mark - RZAssemblageDelegate

@synthesize observers = _observers;

- (NSPointerArray *)observers
{
    if ( _observers == nil ) {
        _observers = [NSPointerArray weakObjectsPointerArray];
    }
    return _observers;
}

- (void)addObserver:(nonnull id<RZTreeObserver>)observer;
{
    NSParameterAssert(observer);
    [self.observers addPointer:(__bridge void *)observer];
}

- (void)removeObserver:(nonnull id<RZTreeObserver>)observer
{
    NSParameterAssert(observer);
    NSUInteger index = NSNotFound;
    [self.observers compact];
    for ( NSUInteger i = 0; i < self.observers.count; i++ ) {
        if ( [self.observers pointerAtIndex:i] == (__bridge void *)observer ) {
            index = i;
            break;
        }
    }
    // It's common for observers to be nil'd out before the removeObserver call
    if ( index != NSNotFound ) {
        [self.observers removePointerAtIndex:index];
    }
}

- (void)willBeginUpdatesForNode:(nonnull RZTree *)node
{
    [self openBatchUpdate];
}

- (void)notifyObjectUpdate:(nonnull id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self elementsIndexOfObject:anObject];
    RZAssemblageLog(@"%p:Update %@ at %zd", self, anObject, index);
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self openBatchUpdate];
    [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)node:(nonnull RZTree *)node didEndUpdatesWithChangeSet:(nonnull RZChangeSet *)changeSet
{
    RZRaize(self.changeSet != nil, @"Must begin an update on the parent assemblage before mutating a child assemblage");
    NSUInteger assemblageIndex = [self indexOfNode:node];
    [self.changeSet mergeChangeSet:changeSet withIndexPathTransform:^NSIndexPath *(NSIndexPath *indexPath) {
        return [indexPath rz_indexPathByPrependingIndex:assemblageIndex];
    }];
    [self closeBatchUpdate];
}

#pragma mark - Index Path Helpers

- (void)insertObject:(nonnull id)object atIndexPath:(nullable NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [[self nodeAtIndexPath:[indexPath indexPathByRemovingLastIndex]] mutableChildren];
    [proxy insertObject:object atIndex:[indexPath rz_lastIndex]];
}

- (void)removeObjectAtIndexPath:(nullable NSIndexPath *)indexPath
{
    NSMutableArray *proxy = [[self nodeAtIndexPath:[indexPath indexPathByRemovingLastIndex]] mutableChildren];
    [proxy removeObjectAtIndex:[indexPath rz_lastIndex]];
}

- (void)moveObjectAtIndexPath:(nullable NSIndexPath *)fromIndexPath toIndexPath:(nullable NSIndexPath *)toIndexPath
{
    NSMutableArray *fproxy = [[self nodeAtIndexPath:[fromIndexPath indexPathByRemovingLastIndex]] mutableChildren];
    NSMutableArray *tproxy = [[self nodeAtIndexPath:[toIndexPath indexPathByRemovingLastIndex]] mutableChildren];

    NSObject *object = [fproxy objectAtIndex:[fromIndexPath rz_lastIndex]];
    [fproxy removeObjectAtIndex:[fromIndexPath rz_lastIndex]];
    [tproxy insertObject:object atIndex:[toIndexPath rz_lastIndex]];
}

@end

@implementation RZTree (Protected)

- (NSUInteger)countOfElements
{
    RZSubclassMustImplement(NSNotFound);
}

- (nullable id)objectInElementsAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement(nil);
}

- (nullable RZTree *)nodeAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement(nil);
}

- (NSUInteger)indexOfNode:(nonnull RZTree *)node
{
    NSUInteger index = NSNotFound;
    for ( NSUInteger i = 0; i < [self countOfElements]; i++ ) {
        RZTree *childAssemblage = [self nodeAtIndex:i];
        if ( childAssemblage == node ) {
            index = i;
            break;
        }
    }
    return index;
}

- (NSUInteger)elementsIndexOfObject:(nonnull id)object
{
    RZSubclassMustImplement(NSNotFound);
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement();
}

- (void)insertObject:(nonnull NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    RZSubclassMustImplement();
}

- (void)addMonitorsForObject:(nonnull id)anObject
{
    if ( [anObject isKindOfClass:[RZTree class]] ) {
        [(RZTree *)anObject addObserver:self];
    }
}

- (void)removeMonitorsForObject:(nonnull id)anObject;
{
    if ( [anObject isKindOfClass:[RZTree class]] ) {
        [(RZTree *)anObject removeObserver:self];
    }
}

@end
