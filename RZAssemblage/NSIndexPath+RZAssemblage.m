//
//  NSIndexPath+RZAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageDefines.h"

@implementation NSIndexPath(RZAssemblage)

- (NSIndexPath *)rz_indexPathByRemovingFirstIndex
{
    NSIndexPath *remainingIndexPath = nil;
    if ( self.length > 0 ) {
        NSUInteger *indexes = calloc(self.length, sizeof(NSUInteger));
        [self getIndexes:indexes];
        remainingIndexPath = [NSIndexPath indexPathWithIndexes:indexes + 1 length:self.length - 1];
        free(indexes);
    }
    return remainingIndexPath;
}

- (NSIndexPath *)rz_indexPathByPrependingIndex:(NSUInteger)index
{
    NSIndexPath *indexPath = nil;
    NSUInteger *indexes = calloc(self.length + 1, sizeof(NSUInteger));
    [self getIndexes:indexes + 1];
    indexes[0] = index;
    indexPath = [NSIndexPath indexPathWithIndexes:indexes length:self.length + 1];
    free(indexes);
    return indexPath;
}

- (NSIndexPath *)rz_indexPathByUpdatingIndex:(NSUInteger)index atPosition:(NSUInteger)position
{
    RZRaize(position < self.length, @"Position is larger than the length of the index path.")
    NSIndexPath *indexPath = nil;
    NSUInteger *indexes = calloc(self.length, sizeof(NSUInteger));
    [self getIndexes:indexes];
    indexes[position] = index;
    indexPath = [NSIndexPath indexPathWithIndexes:indexes length:self.length];
    free(indexes);
    return indexPath;
}

- (NSIndexPath *)rz_indexPathShiftedAtIndexPath:(NSIndexPath *)indexPath by:(NSUInteger)change
{
    NSIndexPath *result = nil;
    if ( indexPath.length <= self.length ) {
        NSUInteger indexPosition = indexPath.length - 1;
        NSUInteger mutationIndex = [indexPath indexAtPosition:indexPosition];
        NSUInteger indexAtDepth = [self indexAtPosition:indexPosition];
        if ( mutationIndex <= indexAtDepth ) {
            result = [self rz_indexPathByUpdatingIndex:indexAtDepth + change atPosition:indexPosition];
        }
    }
    return result;
}

- (NSIndexPath *)rz_indexPathWithLastIndexShiftedBy:(NSInteger)shift
{
    NSUInteger end = self.length - 1;
    NSUInteger index = [self indexAtPosition:end];
    return [self rz_indexPathByUpdatingIndex:index + shift atPosition:end];
}

- (NSUInteger)rz_lastIndex
{
    return self.length == 0 ? NSNotFound : [self indexAtPosition:self.length - 1];
}

- (NSString *)rz_shortDescription
{
    NSMutableArray *indexes = [NSMutableArray array];
    for ( NSUInteger i = 0; i < self.length; i++ ) {
        [indexes addObject:[NSString stringWithFormat:@"%zd", [self indexAtPosition:i]]];
    }
    return [indexes componentsJoinedByString:@":"];
}

- (void)rz_enumerateUsingBlock:(RZIndexPathIndexBlock)block
{
    NSParameterAssert(block);
    for ( NSUInteger i = 0; i < self.length; i++ ) {
        NSUInteger index = [self indexAtPosition:i];
        BOOL stop = NO;
        block(index, &stop);
        if ( stop ) {
            break;
        }
    }
}

@end
