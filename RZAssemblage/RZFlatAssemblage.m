//
//  RZFlatAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZFlatAssemblage.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblage+Private.h"

@implementation RZFlatAssemblage

- (id)initWithArray:(NSArray *)array
{
    self = [super initWithArray:array];
    for ( id<RZAssemblage> assemblage in array ) {
        RZRaize([assemblage conformsToProtocol:@protocol(RZAssemblage)], @"All objects in RZFlatAssemblage must conform to RZAssemblage");
    }
    return self;
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

- (NSIndexPath *)transformIndexPath:(NSIndexPath *)indexPath fromAssemblage:(id<RZAssemblage>)assemblage;
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

- (id<RZAssemblage>)assemblageHoldingIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath indexAtPosition:0];
    indexPath = [indexPath rz_indexPathByRemovingFirstIndex];
    NSUInteger offset = 0;
    id object = nil;
    for ( id<RZAssemblage>assemblage in self.store ) {
        NSUInteger count = [assemblage numberOfChildrenAtIndexPath:nil];
        if ( index - offset < count) {
            object = assemblage;
            break;
        }
        offset += count;
    }
    return object;
}
@end
