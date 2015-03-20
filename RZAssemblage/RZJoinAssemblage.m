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

- (id)initWithArray:(NSArray *)array
{
    self = [super initWithArray:array];
    for ( id<RZAssemblage> assemblage in array ) {
        RZRaize([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"All objects in RZJoinAssemblage must conform to RZAssemblage");
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p join %@", self.class, self, self.childrenStorage];
}

#pragma mark - RZAssemblage

- (NSUInteger)countOfChildren
{
    NSUInteger count = 0;
    for ( id<RZAssemblage>assemblage in self.childrenStorage ) {
        count += [assemblage childCountAtIndexPath:nil];
    }
    return count;
}

- (id)objectInChildrenAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    id object = nil;
    for ( id<RZAssemblage>assemblage in self.childrenStorage ) {
        NSUInteger count = [assemblage childCountAtIndexPath:nil];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            object = [assemblage childAtIndexPath:[NSIndexPath indexPathWithIndex:currentIndex]];
            break;
        }
        offset += count;
    }
    return object;
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    for ( id<RZAssemblage>assemblage in self.childrenStorage ) {
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
    for ( id<RZAssemblage>assemblage in self.childrenStorage ) {
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
    for ( id<RZAssemblage> partAssemblage in self.childrenStorage ) {
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
    for ( id<RZAssemblage> partAssemblage in self.childrenStorage ) {
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
