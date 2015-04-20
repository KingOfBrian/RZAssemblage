//
//  RZJoinTree.m
//  RZTree
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZJoinedTree.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZTree+Private.h"
#import "RZAssemblageDefines.h"

@implementation RZJoinedTree

- (instancetype)initWithNodes:(NSArray *)nodes
{
    self = [super init];
    for ( RZTree *node in nodes ) {
        [self addMonitorsForObject:node];
        RZRaize([node isKindOfClass:[RZTree class]], @"All objects in RZJoinedTree must be an RZTree");
    }
    _nodes = nodes;
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p join %@", self.class, self, self.nodes];
}

#pragma mark - RZTree

- (NSUInteger)countOfElements
{
    NSUInteger count = 0;
    for ( RZTree *assemblage in self.nodes ) {
        count += [assemblage countOfElements];
    }
    return count;
}

- (id)objectInElementsAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    id object = nil;
    for ( RZTree *node in self.nodes ) {
        NSUInteger count = [node countOfElements];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            object = [node objectInElementsAtIndex:currentIndex];
            break;
        }
        offset += count;
    }
    return object;
}

- (id)nodeAtIndex:(NSUInteger)index;
{
    NSUInteger offset = 0;
    id object = nil;
    for ( RZTree *node in self.nodes ) {
        NSUInteger count = [node countOfElements];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            object = [node nodeAtIndex:currentIndex];
            break;
        }
        offset += count;
    }
    return object;
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    for ( RZTree *node in self.nodes ) {
        NSUInteger count = [node countOfElements];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            NSMutableArray *joinedProxy = [node mutableChildren];
            [joinedProxy removeObjectAtIndex:currentIndex];
            break;
        }
        offset += count;
    }
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    for ( RZTree *node in self.nodes ) {
        NSUInteger count = [node countOfElements];
        NSUInteger currentIndex = index - offset;
        if ( currentIndex <= count) {
            NSMutableArray *joinedProxy = [node mutableChildren];
            [joinedProxy insertObject:object atIndex:currentIndex];
            break;
        }
        offset += count;
    }
}

#pragma mark - RZAssemblageDelegate

- (void)node:(RZTree *)node didEndUpdatesWithChangeSet:(RZChangeSet *)changeSet
{
    [self.changeSet mergeChangeSet:changeSet withIndexPathTransform:^NSIndexPath *(NSIndexPath *indexPath) {
        NSUInteger offset = [self indexOffsetForAssemblage:node];
        return [indexPath rz_indexPathWithLastIndexShiftedBy:offset];
    }];
    [self closeBatchUpdate];
}

#pragma mark - Private

- (NSUInteger)indexOffsetForAssemblage:(RZTree *)childAssemblage
{
    NSUInteger count = 0;
    for ( RZTree *node in self.nodes ) {
        if ( node == childAssemblage ) {
            break;
        }
        count += [node countOfElements];
    }
    return count;
}

- (NSUInteger)indexOfNodeContainingParentIndex:(NSUInteger)parentIndex;
{
    NSUInteger index = 0;
    for ( RZTree *node in self.nodes ) {
        NSUInteger count = [node countOfElements];
        if ( parentIndex <= count ) {
            break;
        }
        index++;
        parentIndex -= count;
    }
    return index;
}

@end
