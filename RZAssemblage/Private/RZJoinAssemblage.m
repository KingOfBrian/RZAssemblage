//
//  RZJoinAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZJoinAssemblage.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblage+Private.h"
#import "RZAssemblageDefines.h"

@implementation RZJoinAssemblage

- (instancetype)initWithAssemblages:(NSArray *)assemblages
{
    self = [super init];
    for ( RZAssemblage *assemblage in assemblages ) {
        [self addMonitorsForObject:assemblage];
        RZRaize([assemblage isKindOfClass:[RZAssemblage class]], @"All objects in RZJoinAssemblage must be an RZAssemblage");
    }
    _assemblages = assemblages;
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p join %@", self.class, self, self.assemblages];
}

#pragma mark - RZAssemblage

- (NSUInteger)countOfElements
{
    NSUInteger count = 0;
    for ( RZAssemblage *assemblage in self.assemblages ) {
        count += [assemblage countOfElements];
    }
    return count;
}

- (id)objectInElementsAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    id object = nil;
    for ( RZAssemblage *assemblage in self.assemblages ) {
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
    for ( RZAssemblage *assemblage in self.assemblages ) {
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
    for ( RZAssemblage *assemblage in self.assemblages ) {
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
    for ( RZAssemblage *assemblage in self.assemblages ) {
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

- (void)assemblage:(RZAssemblage *)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    [self.changeSet mergeChangeSet:changeSet withIndexPathTransform:^NSIndexPath *(NSIndexPath *indexPath) {
        NSUInteger offset = [self indexOffsetForAssemblage:assemblage];
        return [indexPath rz_indexPathWithLastIndexShiftedBy:offset];
    }];
    [self closeBatchUpdate];
}

#pragma mark - Private

- (NSUInteger)indexOffsetForAssemblage:(RZAssemblage *)childAssemblage
{
    NSUInteger count = 0;
    for ( RZAssemblage *partAssemblage in self.assemblages ) {
        if ( partAssemblage == childAssemblage ) {
            break;
        }
        count += [partAssemblage countOfElements];
    }
    return count;
}

- (NSUInteger)indexOfAssemblageContainingParentIndex:(NSUInteger)parentIndex;
{
    NSUInteger index = 0;
    for ( RZAssemblage *partAssemblage in self.assemblages ) {
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
