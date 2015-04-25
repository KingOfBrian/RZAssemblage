//
//  RZTestHelpers.m
//  RZAssemblage
//
//  Created by Brian King on 4/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTestHelpers.h"

@implementation NSIndexPath (RZTestHelpers)

+ (NSIndexPath *)indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section
{
    NSUInteger indexes[2];
    indexes[0] = section;
    indexes[1] = row;
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexes length:2];
    return indexPath;
}

@end


@implementation RZMutableIndexPathSet(Test)

- (BOOL)containsIndex:(NSUInteger)index
{
    return [self containsIndexPath:[NSIndexPath indexPathWithIndex:index]];
}

@end

