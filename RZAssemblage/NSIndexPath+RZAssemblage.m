//
//  NSIndexPath+RZAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "NSIndexPath+RZAssemblage.h"

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

- (NSUInteger)rz_lastIndex
{
    return self.length == 0 ? NSNotFound : [self indexAtPosition:self.length - 1];
}

@end
