//
//  RZFilteredTree.m
//  RZTree
//
//  Created by Brian King on 4/14/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZFilteredTree.h"
#import "RZTree+Private.h"
#import "NSIndexSet+RZAssemblage.h"

@interface RZFilteredTree()
@property (strong, nonatomic) RZTree *node;
@end

@implementation RZFilteredTree

- (instancetype)initWithNode:(RZTree *)node filteredIndexPaths:(RZMutableIndexPathSet *)filteredIndexPaths
{
    self = [super init];
    if ( self ) {
        _node = node;
        _filteredIndexPaths = filteredIndexPaths;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p %@ filtered from %@", self.class, self, self.filteredIndexPaths, self.node];
}

- (NSUInteger)exposedIndexFromIndex:(NSUInteger)index
{
    NSIndexSet *filtered = [self.filteredIndexPaths indexesAtIndexPath:nil];
    index -= [filtered countOfIndexesInRange:NSMakeRange(0, index)];
    return index;
}

- (NSUInteger)indexFromExposedIndex:(NSUInteger)index
{
    NSIndexSet *filtered = [self.filteredIndexPaths indexesAtIndexPath:nil];
    index += [filtered rz_countOfIndexesInRangesBeforeOrContainingIndex:index];
    return index;
}

#pragma mark - RZTree

- (id)representedObject
{
    return self.node.representedObject;
}

- (NSUInteger)countOfElements
{
    return [self.node countOfElements] - self.filteredIndexPaths.count;
}

- (id)objectInElementsAtIndex:(NSUInteger)index
{
    NSUInteger exposedIndex = [self indexFromExposedIndex:index];
    return [self.node objectInElementsAtIndex:exposedIndex];
}

- (NSUInteger)elementsIndexOfObject:(id)object
{
    NSUInteger index = [self.node elementsIndexOfObject:object];
    NSUInteger exposedIndex = [self exposedIndexFromIndex:index];
    return exposedIndex;
}

- (id)nodeAtIndex:(NSUInteger)index;
{
    NSUInteger exposedIndex = [self indexFromExposedIndex:index];
    RZTree *node = [self.node nodeAtIndex:exposedIndex];
    if ( node ) {
        RZMutableIndexPathSet *childIndexPathSet = [self.filteredIndexPaths indexPathSetAtIndexPath:[NSIndexPath indexPathWithIndex:exposedIndex]];
        node = [[RZFilteredTree alloc] initWithNode:node filteredIndexPaths:childIndexPathSet];
    }
    return node;
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    NSUInteger exposedIndex = [self indexFromExposedIndex:index];
    [[self.node mutableChildren] removeObjectAtIndex:exposedIndex];
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    NSUInteger exposedIndex = [self indexFromExposedIndex:index];
    [[self.node mutableChildren] insertObject:object atIndex:exposedIndex];
}

- (void)addObserver:(nonnull id<RZTreeObserver>)observer
{
    RZRaize(NO, @"Do not observe filtered nodes %@", self);
}

- (void)willBeginUpdatesForNode:(RZTree *)node
{
    RZRaize(NO, @"Internal filter %@ should never recieve updates (%@)", self, node);
}

@end
