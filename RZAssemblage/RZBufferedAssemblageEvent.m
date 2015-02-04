//
//  RZBufferedAssemblageEvent.m
//  RZAssemblage
//
//  Created by Brian King on 2/3/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBufferedAssemblageEvent.h"
#import "NSIndexPath+RZAssemblage.h"

@implementation RZBufferedAssemblageEvent

+ (instancetype)eventForObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZBufferedAssemblageEvent *event = [[self alloc] init];
    event.object = object;
    event.indexPath = indexPath;
    return event;
}

- (NSUInteger)maxIndexPathLength
{
    return self.indexPath.length;
}

- (void)updateIndexesForInsertAtIndexPath:(NSIndexPath *)indexPath
{
    self.indexPath = [self.indexPath rz_indexPathShiftedAtIndexPath:indexPath by:1];
}

- (void)updateIndexesForRemoveAtIndexPath:(NSIndexPath *)indexPath
{
    self.indexPath = [self.indexPath rz_indexPathShiftedAtIndexPath:indexPath by:-1];
}

@end

@implementation RZBufferedAssemblageMoveEvent

+ (instancetype)eventForObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    RZBufferedAssemblageMoveEvent *event = [self eventForObject:object atIndexPath:fromIndexPath];
    event.toIndexPath = toIndexPath;
    return event;
}

- (NSUInteger)maxIndexPathLength
{
    return MAX([super maxIndexPathLength], self.toIndexPath.length);
}

- (void)updateIndexesForInsertAtIndexPath:(NSIndexPath *)indexPath
{
    [super updateIndexesForInsertAtIndexPath:indexPath];
    self.toIndexPath = [self.toIndexPath rz_indexPathShiftedAtIndexPath:indexPath by:-1];
}

- (void)updateIndexesForRemoveAtIndexPath:(NSIndexPath *)indexPath
{
    [super updateIndexesForRemoveAtIndexPath:indexPath];
    self.toIndexPath = [self.toIndexPath rz_indexPathShiftedAtIndexPath:indexPath by:-1];
}

@end
