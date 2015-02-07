//
//  RZMutableIndexPathSet.m
//  RZAssemblage
//
//  Created by Brian King on 2/5/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZMutableIndexPathSet.h"
#import "NSIndexPath+RZAssemblage.h"

@interface RZIndexNode : NSObject

+ (instancetype)indexNodeWithIndex:(NSUInteger)index;

@property () NSUInteger index;
@property () BOOL present;
@property (strong) NSMutableArray *childNodes;

@end

@implementation RZIndexNode

- (instancetype)init
{
    self = [super init];
    self.childNodes = [NSMutableArray array];
    return self;
}

+ (instancetype)rootIndexNode
{
    return [[self alloc] init];
}

+ (instancetype)indexNodeWithIndex:(NSUInteger)index
{
    RZIndexNode *indexNode = [[self alloc] init];
    indexNode.index = index;
    return indexNode;
}

+ (NSComparator)comparator
{
    return ^NSComparisonResult(RZIndexNode *obj1, RZIndexNode *obj2) {
        NSUInteger index1 = obj1.index;
        NSUInteger index2 = obj2.index;
        NSComparisonResult result = NSNotFound;
        if ( index1 < index2 ) {
            result = NSOrderedDescending;
        }
        else if ( index1 == index2 ) {
            result = NSOrderedSame;
        }
        else {
            result = NSOrderedAscending;
        }
        return result;
    };
}

- (void)addSortedNodeForIndex:(NSUInteger)index
{
    RZIndexNode *childNode = [RZIndexNode indexNodeWithIndex:index];

    NSRange range = NSMakeRange(0, self.childNodes.count);
    NSUInteger sortedIndex = [self.childNodes indexOfObject:childNode
                                              inSortedRange:range
                                                    options:NSBinarySearchingInsertionIndex
                                            usingComparator:self.class.comparator];

    [self.childNodes insertObject:childNode atIndex:sortedIndex];
}

- (RZIndexNode *)indexNodeForIndex:(NSUInteger)index createNew:(BOOL)createNew;
{
    RZIndexNode *childNode = nil;
    for ( RZIndexNode *node in self.childNodes ) {
        if ( node.index == index ) {
            childNode = node;
            break;
        }
    }
    if ( childNode == nil && createNew ) {
        [self addSortedNodeForIndex:index];
    }
    return childNode;
}

- (RZIndexNode *)indexNodeForIndexPath:(NSIndexPath *)indexPath createNew:(BOOL)createNew;
{
    RZIndexNode *node = self;
    for ( NSUInteger i = 0; i < indexPath.length; i++ ) {
        NSUInteger index = [indexPath indexAtPosition:i];
        node = [node indexNodeForIndex:index createNew:createNew];
    }
    return node;
}

- (void)removeIndexNodeRepresentingIndex:(NSUInteger)index
{
    __block NSUInteger childNodeIndex = NSNotFound;
    [self.childNodes enumerateObjectsUsingBlock:^(RZIndexNode *node, NSUInteger idx, BOOL *stop) {
        if ( node.index == idx ) {
            childNodeIndex = idx;
            *stop = YES;
        }
    }];
    [self.childNodes removeObjectAtIndex:childNodeIndex];
}

- (NSIndexSet *)childIndexSet
{
    NSMutableIndexSet *childIndexSet = [NSMutableIndexSet indexSet];
    for ( RZIndexNode *childNode in self.childNodes ) {
        if ( childNode.present ) {
            [childIndexSet addIndex:childNode.index];
        }
    }
    return childIndexSet;
}

- (void)shiftIndexesStartingAtIndex:(NSUInteger)index by:(NSInteger)shift
{
    for ( RZIndexNode *childNode in self.childNodes ) {
        if ( childNode.index >= index ) {
            childNode.index += shift;
        }
    }
}

- (void)enumerateNodesFromIndexPath:(NSIndexPath *)indexPath withBlock:(RZMutableIndexPathNodeBlock)block
{
    if ( indexPath == nil ) {
        indexPath = [NSIndexPath indexPathWithIndex:self.index];
    }
    else {
        indexPath = [indexPath indexPathByAddingIndex:self.index];
    }
    BOOL stop = NO;
    NSIndexSet *childIndexSet = self.childIndexSet;
    if ( childIndexSet.count ) {
        block(indexPath, self.childIndexSet, &stop);
        if ( stop ) {
            return;
        }
    }
    for ( RZIndexNode *childNode in self.childNodes ) {
        [childNode enumerateNodesFromIndexPath:indexPath withBlock:block];
    }
}

- (void)enumerateIndexPathsFromIndexPath:(NSIndexPath *)indexPath withBlock:(RZMutableIndexPathBlock)block
{
    if ( indexPath == nil ) {
        indexPath = [NSIndexPath indexPathWithIndex:self.index];
    }
    else {
        indexPath = [indexPath indexPathByAddingIndex:self.index];
    }
    BOOL stop = NO;
    if ( self.present ) {
        block(indexPath, &stop);
        if ( stop ) {
            return;
        }
    }
    for ( RZIndexNode *childNode in self.childNodes ) {
        [childNode enumerateIndexPathsFromIndexPath:indexPath withBlock:block];
    }
}

@end

@interface RZMutableIndexPathSet()

@property (strong, nonatomic) RZIndexNode *indexNode;

@end

@implementation RZMutableIndexPathSet

+ (instancetype)mutableIndexPathSet
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        _indexNode = [RZIndexNode rootIndexNode];
    }
    return self;
}

- (NSIndexSet *)rootIndexes;
{
    return self.indexNode.childIndexSet;
}

#pragma mark - Mutation

- (void)addIndex:(NSUInteger)index
{
    RZIndexNode *indexNode = [self.indexNode indexNodeForIndex:index createNew:YES];
    indexNode.present = YES;
}

- (void)removeIndex:(NSUInteger)index
{
    [self.indexNode removeIndexNodeRepresentingIndex:index];
}

- (void)addIndexPath:(NSIndexPath *)indexPath
{
    RZIndexNode *indexNode = [self.indexNode indexNodeForIndexPath:indexPath createNew:YES];
    indexNode.present = YES;
}

- (void)removeIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger leafIndex = [indexPath indexAtPosition:indexPath.length - 1];
    NSIndexPath *parentIndexPath = [indexPath indexPathByRemovingLastIndex];
    RZIndexNode *parentNode = [self.indexNode indexNodeForIndexPath:parentIndexPath createNew:NO];
    [parentNode removeIndexNodeRepresentingIndex:leafIndex];
}

- (BOOL)containsIndexPath:(NSIndexPath *)indexPath
{
    RZIndexNode *indexNode = [self.indexNode indexNodeForIndexPath:indexPath createNew:NO];
    return indexNode.present;
}

- (void)shiftIndexesStartingAtIndexPath:(NSIndexPath *)indexPath by:(NSUInteger)shift
{
    NSUInteger index = [indexPath rz_lastIndex];
    indexPath = [indexPath indexPathByRemovingLastIndex];
    RZIndexNode *indexNode = [self.indexNode indexNodeForIndexPath:indexPath createNew:NO];
    [indexNode shiftIndexesStartingAtIndex:index by:shift];
}

- (void)shiftIndexesStartingAfterIndexPath:(NSIndexPath *)indexPath by:(NSUInteger)shift
{
    [self shiftIndexesStartingAtIndexPath:[indexPath rz_indexPathWithLastIndexShiftedBy:1] by:shift];
}

- (void)enumerateSortedIndexPathNodesUsingBlock:(RZMutableIndexPathNodeBlock)block
{
    [self.indexNode enumerateNodesFromIndexPath:nil withBlock:block];
}

- (void)enumerateSortedIndexPathsUsingBlock:(RZMutableIndexPathBlock)block
{
    [self.indexNode enumerateIndexPathsFromIndexPath:nil withBlock:block];
}

@end
