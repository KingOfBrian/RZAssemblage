//
//  RZJoinAssemblage.m
//  RZTree
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZJoinAssemblage.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZTree+Private.h"
#import "RZAssemblageDefines.h"

@implementation RZJoinAssemblage

- (instancetype)initWithAssemblages:(NSArray *)assemblages
{
    self = [super init];
    for ( RZTree *assemblage in assemblages ) {
        [self addMonitorsForObject:assemblage];
        RZRaize([assemblage isKindOfClass:[RZTree class]], @"All objects in RZJoinAssemblage must be an RZTree");
    }
    _assemblages = assemblages;
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p join %@", self.class, self, self.assemblages];
}

#pragma mark - RZTree

- (NSUInteger)countOfElements
{
    NSUInteger count = 0;
    for ( RZTree *assemblage in self.assemblages ) {
        count += [assemblage countOfElements];
    }
    return count;
}

- (id)objectInElementsAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    id object = nil;
    for ( RZTree *assemblage in self.assemblages ) {
        NSUInteger count = [assemblage countOfElements];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            object = [assemblage objectInElementsAtIndex:currentIndex];
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
    for ( RZTree *assemblage in self.assemblages ) {
        NSUInteger count = [assemblage countOfElements];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            object = [assemblage nodeAtIndex:currentIndex];
            break;
        }
        offset += count;
    }
    return object;
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    for ( RZTree *assemblage in self.assemblages ) {
        NSUInteger count = [assemblage countOfElements];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            NSMutableArray *joinedProxy = [assemblage mutableChildren];
            [joinedProxy removeObjectAtIndex:currentIndex];
            break;
        }
        offset += count;
    }
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    for ( RZTree *assemblage in self.assemblages ) {
        NSUInteger count = [assemblage countOfElements];
        NSUInteger currentIndex = index - offset;
        if ( currentIndex <= count) {
            NSMutableArray *joinedProxy = [assemblage mutableChildren];
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
    for ( RZTree *partAssemblage in self.assemblages ) {
        if ( partAssemblage == childAssemblage ) {
            break;
        }
        count += [partAssemblage countOfElements];
    }
    return count;
}

- (NSUInteger)indexOfNodeContainingParentIndex:(NSUInteger)parentIndex;
{
    NSUInteger index = 0;
    for ( RZTree *partAssemblage in self.assemblages ) {
        NSUInteger count = [partAssemblage countOfElements];
        if ( parentIndex <= count ) {
            break;
        }
        index++;
        parentIndex -= count;
    }
    return index;
}

@end
