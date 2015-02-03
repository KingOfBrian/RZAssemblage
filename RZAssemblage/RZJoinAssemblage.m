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
    return [NSString stringWithFormat:@"<%@: %p joinen %@", self.class, self, self.store];
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

- (BOOL)leafNodeForIndexPath:(NSIndexPath *)indexPath
{
    // Index Path operations should never terminate here.
    return NO;
}

- (NSIndexPath *)indexPathFromChildIndexPath:(NSIndexPath *)indexPath fromAssemblage:(id<RZAssemblage>)assemblage
{
    // Increase the index path based on the assemblage that it comes from.
    NSUInteger index = [indexPath indexAtPosition:0];
    NSIndexPath *baseIndexPath = [indexPath rz_indexPathByRemovingFirstIndex];
    for ( id<RZAssemblage> partAssemblage in self.store ) {
        if ( assemblage == partAssemblage ) {
            break;
        }
        index += [partAssemblage numberOfChildrenAtIndexPath:nil];
    }
    return [baseIndexPath rz_indexPathByPrependingIndex:index];
}

- (NSIndexPath *)childIndexPathFromIndexPath:(NSIndexPath *)indexPath
{
    // Decrease the first index in the index path until it fits in an assemblage.
    NSUInteger index = [indexPath indexAtPosition:0];
    NSIndexPath *baseIndexPath = [indexPath rz_indexPathByRemovingFirstIndex];

    for ( id<RZAssemblage> partAssemblage in self.store ) {
        if ( index < [partAssemblage numberOfChildrenAtIndexPath:nil] ) {
            break;
        }
        index -= [partAssemblage numberOfChildrenAtIndexPath:nil];
    }
    return [baseIndexPath rz_indexPathByPrependingIndex:index];
}

- (NSUInteger)indexOfAssemblageContainingParentIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = 0;
    NSUInteger parentIndex = [indexPath indexAtPosition:0];

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

- (id<RZAssemblageMutationTraversalSupport>)assemblageToTraverseForIndexPath:(NSIndexPath *)indexPath canBeEmpty:(BOOL)canBeEmpty
{
    NSUInteger index = [self indexOfAssemblageContainingParentIndexPath:indexPath];
    id<RZAssemblageMutationTraversal> assemblage = [self.store objectAtIndex:index];
    if ( canBeEmpty == NO && [assemblage numberOfChildrenAtIndexPath:nil] == 0 ) {
        index++;
    }
    return [self.store objectAtIndex:index];
}

@end
