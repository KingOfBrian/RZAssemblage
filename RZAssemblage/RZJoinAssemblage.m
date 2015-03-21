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
    for ( id<RZAssemblage> assemblage in assemblages ) {
        [self addMonitorsForObject:assemblage];
        RZRaize([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"All objects in RZJoinAssemblage must conform to RZAssemblage");
    }
    _assemblages = assemblages;
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p join %@", self.class, self, self.assemblages];
}

#pragma mark - RZAssemblage

- (NSUInteger)countOfChildren
{
    NSUInteger count = 0;
    for ( id<RZAssemblage>assemblage in self.assemblages ) {
        count += [assemblage childCountAtIndexPath:nil];
    }
    return count;
}

- (id)nodeInChildrenAtIndex:(NSUInteger)index;
{
    NSUInteger offset = 0;
    id object = nil;
    for ( RZAssemblage *assemblage in self.assemblages ) {
        NSUInteger count = [assemblage childCountAtIndexPath:nil];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            object = [assemblage nodeInChildrenAtIndex:currentIndex];
            break;
        }
        offset += count;
    }
    return object;
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    for ( id<RZAssemblage>assemblage in self.assemblages ) {
        NSUInteger count = [assemblage childCountAtIndexPath:nil];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            NSMutableArray *joinedProxy = [assemblage mutableArrayForIndexPath:nil];
            [joinedProxy removeObjectAtIndex:currentIndex];
            break;
        }
        offset += count;
    }
}

- (void)insertObject:(NSObject *)object inChildrenAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    for ( id<RZAssemblage>assemblage in self.assemblages ) {
        NSUInteger count = [assemblage childCountAtIndexPath:nil];
        NSUInteger currentIndex = index - offset;
        if ( currentIndex <= count) {
            NSMutableArray *joinedProxy = [assemblage mutableArrayForIndexPath:nil];
            [joinedProxy insertObject:object atIndex:currentIndex];
            break;
        }
        offset += count;
    }
}

#pragma mark - RZAssemblageDelegate

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    [self.changeSet mergeChangeSet:changeSet withIndexPathTransform:^NSIndexPath *(NSIndexPath *indexPath) {
        NSUInteger offset = [self indexOffsetForAssemblage:assemblage];
        return [indexPath rz_indexPathWithLastIndexShiftedBy:offset];
    }];
    [self closeBatchUpdate];
}

#pragma mark - Private

- (NSUInteger)indexOffsetForAssemblage:(id<RZAssemblage>)childAssemblage
{
    NSUInteger count = 0;
    for ( id<RZAssemblage> partAssemblage in self.assemblages ) {
        if ( partAssemblage == childAssemblage ) {
            break;
        }
        count += [partAssemblage childCountAtIndexPath:nil];
    }
    return count;
}

- (NSUInteger)indexOfAssemblageContainingParentIndex:(NSUInteger)parentIndex;
{
    NSUInteger index = 0;
    for ( id<RZAssemblage> partAssemblage in self.assemblages ) {
        NSUInteger count = [partAssemblage childCountAtIndexPath:nil];
        if ( parentIndex <= count ) {
            break;
        }
        index++;
        parentIndex -= count;
    }
    return index;
}

@end
