//
//  RZIndexPathSet.m
//
//  Created by Brian King on 2/5/15.
//

// Copyright 2014 Raizlabs and other contributors
// http://raizlabs.com/
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "RZIndexPathSet.h"
#import "NSIndexPath+RZAssemblage.h"

#pragma mark - RZIndexNode

@interface RZIndexNode : NSObject <NSCopying>

@property (assign, nonatomic) NSUInteger index;
@property (strong, nonatomic) NSMutableArray *sortedChildren;
@property (assign, nonatomic) BOOL present;

@end

@implementation RZIndexNode

+ (instancetype)nodeWithIndex:(NSUInteger)idx
{
    RZIndexNode *node = [[self alloc] init];
    node.index = idx;

    return node;
}

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        self.index = NSNotFound;
        self.sortedChildren = [NSMutableArray array];
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:%p ", [self class], self];

    if ( self.index != NSNotFound ) {
        [description appendFormat:@"i=%zd", self.index];
    }

    if ( self.sortedChildren.count > 0 ) {
        [description appendFormat:@"%@", self.sortedChildren];
    }
    else {
        [description appendString:@">"];
    }

    return [description copy];
}

- (NSComparisonResult)compare:(RZIndexNode *)otherNode
{
    NSComparisonResult result;

    if ( self.index < otherNode.index ) {
        result = NSOrderedAscending;
    }
    else if ( self.index == otherNode.index ) {
        result = NSOrderedSame;
    }
    else {
        result = NSOrderedDescending;
    }

    return result;
}

- (NSIndexSet *)childIndexSet
{
    NSMutableIndexSet *childIndexSet = [NSMutableIndexSet indexSet];

    [self.sortedChildren enumerateObjectsUsingBlock:^(RZIndexNode *child, NSUInteger idx, BOOL *stop) {
        if ( child.present ) {
            [childIndexSet addIndex:child.index];
        }
    }];

    return [childIndexSet copy];
}

- (NSUInteger)indexOfNode:(RZIndexNode *)node withOptions:(NSBinarySearchingOptions)opts
{
    NSUInteger idx;

    if ( node != nil ) {
        NSRange range = NSMakeRange(0, self.sortedChildren.count);
        idx = [self.sortedChildren indexOfObject:node inSortedRange:range options:opts usingComparator:^NSComparisonResult(RZIndexNode *n1, RZIndexNode *n2) {
            return [n1 compare:n2];
        }];
    }
    else {
        idx = NSNotFound;
    }

    return idx;
}

- (RZIndexNode *)childForIndex:(NSUInteger)idx createNew:(BOOL)create;
{
    RZIndexNode *child = [RZIndexNode nodeWithIndex:idx];
    NSUInteger childIdx = [self indexOfNode:child withOptions:NSBinarySearchingFirstEqual];

    if ( childIdx == NSNotFound ) {
        if ( create ) {
            NSUInteger insertIdx = [self indexOfNode:child withOptions:NSBinarySearchingInsertionIndex];
            [self.sortedChildren insertObject:child atIndex:insertIdx];
        }
        else {
            child = nil;
        }
    }
    else {
        child = self.sortedChildren[childIdx];
    }

    return child;
}

- (RZIndexNode *)childForIndexPath:(NSIndexPath *)indexPath createNew:(BOOL)create;
{
    RZIndexNode *node = self;

    for ( NSUInteger i = 0; i < indexPath.length; i++ ) {
        NSUInteger idx = [indexPath indexAtPosition:i];
        node = [node childForIndex:idx createNew:create];
    }
    
    return node;
}

- (void)removeChildWithIndex:(NSUInteger)idx
{
    RZIndexNode *child = [RZIndexNode nodeWithIndex:idx];
    NSUInteger childIdx = [self indexOfNode:child withOptions:NSBinarySearchingFirstEqual];

    if ( childIdx != NSNotFound ) {
        [self.sortedChildren removeObjectAtIndex:childIdx];
    }
}

- (void)shiftIndexesStartingAtIndex:(NSUInteger)idx by:(NSInteger)delta
{
    NSUInteger indexStart = MAX((NSInteger)idx + delta, 0);
    for ( NSUInteger i = indexStart; delta < 0 && i < indexStart + ABS(delta); i++ ) {
        RZIndexNode *shiftedNode = [self childForIndex:i createNew:NO];

        if ( shiftedNode != nil ) {
            NSUInteger childIdx = [self indexOfNode:shiftedNode withOptions:NSBinarySearchingFirstEqual];
            [self.sortedChildren removeObjectAtIndex:childIdx];
        }
    }

    RZIndexNode *pivotNode = [RZIndexNode nodeWithIndex:idx];
    NSUInteger pivotIdx = [self indexOfNode:pivotNode withOptions:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual];

    for ( NSUInteger i = pivotIdx; i < self.sortedChildren.count; i++ ) {
        RZIndexNode *child = self.sortedChildren[i];
        child.index += delta;
    }
}

- (void)enumerateIndexesFromIndexPath:(NSIndexPath *)indexPath withBlock:(void (^)(NSIndexPath *parentPath, NSIndexSet *indexes, BOOL *stop))block stop:(BOOL *)stop
{
    if ( indexPath == nil ) {
        indexPath = [[NSIndexPath alloc] init];
    }
    else {
        indexPath = [indexPath indexPathByAddingIndex:self.index];
    }

    NSIndexSet *childIndexSet = [self childIndexSet];

    if ( childIndexSet.count ) {
        block(indexPath, [self childIndexSet], stop);
    }

    if ( *stop ) {
        return;
    }

    [self.sortedChildren enumerateObjectsUsingBlock:^(RZIndexNode *child, NSUInteger idx, BOOL *subStop) {
        [child enumerateIndexesFromIndexPath:indexPath withBlock:block stop:stop];
        *subStop = *stop;
    }];
}

- (void)enumerateIndexPathsFromIndexPath:(NSIndexPath *)indexPath withBlock:(void (^)(NSIndexPath *indexPath, BOOL *stop))block stop:(BOOL *)stop
{
    if ( indexPath.length > 0 && self.present ) {
        block(indexPath, stop);
    }

    if ( *stop ) {
        return;
    }

    [self.sortedChildren enumerateObjectsUsingBlock:^(RZIndexNode *child, NSUInteger idx, BOOL *subStop) {
        NSIndexPath *childIndexPath = nil;

        if ( indexPath == nil ) {
            childIndexPath = [NSIndexPath indexPathWithIndex:child.index];
        }
        else {
            childIndexPath = [indexPath indexPathByAddingIndex:child.index];
        }

        [child enumerateIndexPathsFromIndexPath:childIndexPath withBlock:block stop:stop];
        *subStop = *stop;
    }];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    RZIndexNode *copy = [RZIndexNode nodeWithIndex:self.index];
    copy.present = self.present;
    NSMutableArray *childrenCopy = [NSMutableArray array];

    [self.sortedChildren enumerateObjectsUsingBlock:^(RZIndexNode *child, NSUInteger idx, BOOL *stop) {
        [childrenCopy addObject:[child copyWithZone:zone]];
    }];

    copy.sortedChildren = childrenCopy;

    return copy;
}

@end

#pragma mark - RZIndexPathSet private interface

@interface RZIndexPathSet ()

@property (strong, nonatomic) RZIndexNode *rootNode;

@end

#pragma mark - RZIndexPathSet

@implementation RZIndexPathSet

+ (instancetype)set
{
    return [[self alloc] init];
}

+ (instancetype)setWithIndexPath:(NSIndexPath *)indexPath
{
    return [self setWithIndexPaths:[NSSet setWithObject:indexPath]];
}

+ (instancetype)setWithIndexPathsInArray:(NSArray *)indexPaths
{
    return [self setWithIndexPaths:[NSSet setWithArray:indexPaths]];
}

+ (instancetype)setWithIndexPaths:(NSSet *)indexPaths
{
    RZIndexPathSet *set = [self set];

    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        RZIndexNode *node = [set.rootNode childForIndexPath:indexPath createNew:YES];
        node.present = YES;
    }];

    return set;
}

+ (instancetype)setWithIndexPathSet:(RZIndexPathSet *)indexPathSet
{
    RZIndexPathSet *set = [[self alloc] init];
    set.rootNode = [indexPathSet.rootNode copy];

    return set;
}

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        self.rootNode = [[RZIndexNode alloc] init];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p %@>", [self class], self, self.rootNode];
}

- (NSUInteger)count
{
    return self.rootNode.sortedChildren.count;
}

- (BOOL)containsIndexPath:(NSIndexPath *)indexPath
{
    return [[self.rootNode childForIndexPath:indexPath createNew:NO] present];
}

- (NSIndexSet *)indexesAtIndexPath:(NSIndexPath *)parentPath
{
    RZIndexNode *node = [self.rootNode childForIndexPath:parentPath createNew:NO];
    return [node childIndexSet];
}

- (void)enumerateIndexesUsingBlock:(void (^)(NSIndexPath *, NSIndexSet *, BOOL *))block
{
    NSParameterAssert(block);

    BOOL stop = NO;
    [self.rootNode enumerateIndexesFromIndexPath:nil withBlock:block stop:&stop];
}

- (NSArray *)sortedIndexPaths
{
    NSMutableArray *indexPaths = [NSMutableArray array];

    @synchronized ( self ) {
        [self enumerateIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
            [indexPaths addObject:indexPath];
        }];
    }

    return [indexPaths copy];
}

- (void)enumerateIndexPathsUsingBlock:(void (^)(NSIndexPath *, BOOL *))block
{
    NSParameterAssert(block);

    BOOL stop = NO;
    [self.rootNode enumerateIndexPathsFromIndexPath:nil withBlock:block stop:&stop];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [RZIndexPathSet setWithIndexPathSet:self];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [RZMutableIndexPathSet setWithIndexPathSet:self];
}

@end

#pragma mark - RZMutableIndexPathSet

@implementation RZMutableIndexPathSet

- (void)shiftIndexesStartingAtIndexPath:(NSIndexPath *)indexPath by:(NSInteger)delta
{
    NSUInteger lastIndex = [indexPath rz_lastIndex];
    indexPath = [indexPath indexPathByRemovingLastIndex];

    RZIndexNode *node = [self.rootNode childForIndexPath:indexPath createNew:NO];
    [node shiftIndexesStartingAtIndex:lastIndex by:delta];
}

- (void)shiftIndexesStartingAfterIndexPath:(NSIndexPath *)indexPath by:(NSInteger)delta
{
    NSUInteger lastIndex = [indexPath rz_lastIndex];

    if ( lastIndex != NSNotFound ) {
        indexPath = [indexPath rz_indexPathByReplacingIndexAtPosition:indexPath.length - 1 withIndex:lastIndex + 1];

        [self shiftIndexesStartingAtIndexPath:indexPath by:delta];
    }
}

- (void)addIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath);
    [self addIndexPaths:[NSSet setWithObject:indexPath]];
}

- (void)addIndexPathsInArray:(NSArray *)indexPaths
{
    NSParameterAssert(indexPaths);
    [self addIndexPaths:[NSSet setWithArray:indexPaths]];
}

- (void)addIndexPaths:(NSSet *)indexPaths
{
    NSParameterAssert(indexPaths);

    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        RZIndexNode *indexNode = [self.rootNode childForIndexPath:indexPath createNew:YES];
        indexNode.present = YES;
    }];
}

- (void)addIndexes:(NSIndexSet *)indexSet
{
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self addIndexPath:[NSIndexPath indexPathWithIndex:idx]];
    }];
}

- (void)removeIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(indexPath);
    [self removeIndexPaths:[NSSet setWithObject:indexPath]];
}

- (void)removeIndexPathsInArray:(NSArray *)indexPaths
{
    NSParameterAssert(indexPaths);
    [self removeIndexPaths:[NSSet setWithArray:indexPaths]];
}

- (void)removeIndexPaths:(NSSet *)indexPaths
{
    NSParameterAssert(indexPaths);

    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        NSUInteger lastIndex = [indexPath rz_lastIndex];
        NSIndexPath *parentPath = [indexPath indexPathByRemovingLastIndex];
        RZIndexNode *parentNode = [self.rootNode childForIndexPath:parentPath createNew:NO];
        [parentNode removeChildWithIndex:lastIndex];
    }];
}

- (void)unionSet:(RZIndexPathSet *)indexPathSet
{
    [indexPathSet enumerateIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        [self addIndexPath:indexPath];
    }];
}

- (void)intersectSet:(RZIndexPathSet *)indexPathSet
{
    [self enumerateIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        if ( ![indexPathSet containsIndexPath:indexPath] ) {
            [self removeIndexPath:indexPath];
        }
    }];
}

- (void)minusSet:(RZIndexPathSet *)indexPathSet
{
    [indexPathSet enumerateIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        [self removeIndexPath:indexPath];
    }];
}

- (void)removeAllIndexPaths
{
    self.rootNode = [[RZIndexNode alloc] init];
}

@end
