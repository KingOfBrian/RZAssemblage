//
//  NSIndexSet+RZTree.m
//  RZTree
//
//  Created by Brian King on 4/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "NSIndexSet+RZAssemblage.h"

@implementation NSIndexSet (RZAssemblage)

- (NSUInteger)rz_countOfIndexesInRangesBeforeOrContainingIndex:(NSUInteger)index
{
    __block NSUInteger endIndex = index;
    [self enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        if ( endIndex >= range.location ) {
            endIndex += range.length;
        }
    }];
    return endIndex - index;
}

@end
