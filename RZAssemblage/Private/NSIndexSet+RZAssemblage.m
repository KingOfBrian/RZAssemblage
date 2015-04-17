//
//  NSIndexSet+RZAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 4/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "NSIndexSet+RZAssemblage.h"

@implementation NSIndexSet (RZAssemblage)

- (NSUInteger)rz_countOfIndexesInRangesBeforeOrContainingIndex:(NSUInteger)index
{
    __block NSUInteger count = 0;
    [self enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        if ( index >= range.location ) {
            count += range.length;
        }
    }];
    return count;
}

@end
