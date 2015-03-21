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
    NSIndexPath *indexPath = nil;

    if ( self.length > 0 ) {
        NSUInteger *indexes = (NSUInteger *)malloc(self.length * sizeof(NSUInteger));
        [self getIndexes:indexes];

        indexPath = [NSIndexPath indexPathWithIndexes:indexes + 1 length:self.length - 1];

        free(indexes);
    }
    else {
        indexPath = [[NSIndexPath alloc] init];
    }

    return indexPath;
}

- (NSIndexPath *)rz_indexPathByPrependingIndex:(NSUInteger)index
{
    return [self rz_indexPathByInsertingIndex:index atPosition:0];
}

- (NSIndexPath *)rz_indexPathByInsertingIndex:(NSUInteger)index atPosition:(NSUInteger)position
{
    if ( position > self.length ) {
        [NSException raise:NSInvalidArgumentException format:@"NSIndexPath index %lu out of bounds of index path %@", (unsigned long)index, self];
    }

    NSUInteger *indexes = (NSUInteger *)malloc(self.length * sizeof(NSUInteger));
    [self getIndexes:indexes];

    NSUInteger *newIndexes = (NSUInteger *)malloc((self.length + 1) * sizeof(NSUInteger));
    memcpy(newIndexes, indexes, position * sizeof(NSUInteger));
    newIndexes[position] = index;
    memcpy(newIndexes + position + 1, indexes + position, (self.length - position) * sizeof(NSUInteger));

    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:newIndexes length:self.length + 1];

    free(indexes);
    free(newIndexes);

    return indexPath;
}

- (NSIndexPath *)rz_indexPathByReplacingIndexAtPosition:(NSUInteger)position withIndex:(NSUInteger)index
{
    RZRaize(position < self.length, @"NSIndexPath index %lu out of bounds of index path %@", (unsigned long)index, self);

    NSUInteger *indexes = (NSUInteger *)malloc(self.length * sizeof(NSUInteger));
    [self getIndexes:indexes];
    indexes[position] = index;

    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexes length:self.length];

    free(indexes);

    return indexPath;
}

- (NSIndexPath *)rz_indexPathWithLastIndexShiftedBy:(NSInteger)shift
{
    NSUInteger end = self.length - 1;
    NSUInteger index = [self indexAtPosition:end];
    return [self rz_indexPathByReplacingIndexAtPosition:end withIndex:index + shift];
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

@end
