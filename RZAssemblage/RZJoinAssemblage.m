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
    return [NSString stringWithFormat:@"<%@: %p join %@", self.class, self, self.store];
}

- (id)objectAtIndex:(NSUInteger)index
{
    NSUInteger offset = 0;
    id object = nil;
    for ( id<RZAssemblage>assemblage in self.store ) {
        NSUInteger count = [assemblage numberOfChildrenAtIndexPath:nil];
        NSUInteger currentIndex = index - offset;
        if ( index - offset < count) {
            object = [assemblage objectAtIndexPath:[NSIndexPath indexPathWithIndex:currentIndex]];
            break;
        }
        offset += count;
    }
    return object;
}

- (NSUInteger)numberOfChildren
{
    NSUInteger count = 0;
    for ( id<RZAssemblage>assemblage in self.store ) {
        count += [assemblage numberOfChildrenAtIndexPath:nil];
    }
    return count;
}

- (NSUInteger)indexCountPrecedingAssemblage:(id<RZAssemblage>)childAssemblage
{
    NSUInteger count = 0;
    for ( id<RZAssemblage> partAssemblage in self.store ) {
        if ( partAssemblage == childAssemblage ) {
            break;
        }
        count += [partAssemblage numberOfChildrenAtIndexPath:nil];
    }
    return count;
}

- (NSUInteger)indexOfAssemblageContainingParentIndex:(NSUInteger)parentIndex;
{
    NSUInteger index = 0;
    for ( id<RZAssemblage> partAssemblage in self.store ) {
        NSUInteger count = [partAssemblage numberOfChildrenAtIndexPath:nil];
        if ( parentIndex <= count ) {
            break;
        }
        index++;
        parentIndex -= count;
    }
    return index;
}

- (void)lookupIndexPath:(NSIndexPath *)indexPath forRemoval:(BOOL)forRemoval
             assemblage:(out id<RZAssemblage> *)assemblage newIndexPath:(out NSIndexPath **)newIndexPath;
{
    NSUInteger index = [indexPath indexAtPosition:0];
    NSUInteger assemblageIndex = [self indexOfAssemblageContainingParentIndex:index];
    id<RZAssemblage> nextAssemblage = [self.store objectAtIndex:assemblageIndex];

    indexPath = [indexPath rz_indexPathByRemovingFirstIndex];
    index -= [self indexCountPrecedingAssemblage:nextAssemblage];
    indexPath = [indexPath rz_indexPathByPrependingIndex:index];

    [nextAssemblage lookupIndexPath:indexPath forRemoval:forRemoval
                         assemblage:assemblage newIndexPath:newIndexPath];
}

@end
