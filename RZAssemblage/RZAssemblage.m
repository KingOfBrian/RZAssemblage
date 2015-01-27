//
//  RZBaseAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage+Private.h"

#define RZ_MUST_OVERRIDE [NSException raise:NSInvalidArgumentException format:@"Subclass must over-ride %@", NSStringFromSelector(_cmd)]

@implementation RZAssemblage

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath;
{
    RZ_MUST_OVERRIDE;
    return NSNotFound;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    RZ_MUST_OVERRIDE;
    return nil;
}

- (NSUInteger)indexForObject:(id)object
{
    RZ_MUST_OVERRIDE;
    return NSNotFound;
}

- (NSIndexPath *)appendIndexPath:(NSIndexPath *)indexPath forAssemblage:(id<RZAssemblageAccess>)assemblage
{
    NSIndexPath *newIndexPath = [NSIndexPath indexPathWithIndex:[self indexForObject:assemblage]];
    NSAssert(newIndexPath && newIndexPath.length == 1, @"");
    for ( NSUInteger position = 0; position < indexPath.length; position++ ) {
        NSUInteger index = [indexPath indexAtPosition:position];
        newIndexPath = [newIndexPath indexPathByAddingIndex:index];
    }
    return newIndexPath;
}

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblageAccess>)assemblage
{
    if ( self.updateCount == 0 ) {
        [self.delegate willBeginUpdatesForAssemblage:self];
    }
    self.updateCount += 1;
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *newIndexPath = [self appendIndexPath:indexPath forAssemblage:assemblage];
    [self.delegate assemblage:self didInsertObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *newIndexPath = [self appendIndexPath:indexPath forAssemblage:assemblage];
    [self.delegate assemblage:self didRemoveObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *newIndexPath = [self appendIndexPath:indexPath forAssemblage:assemblage];
    [self.delegate assemblage:self didUpdateObject:object atIndexPath:newIndexPath];
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSIndexPath *newFromIndexPath = [self appendIndexPath:fromIndexPath forAssemblage:assemblage];
    NSIndexPath *newToIndexPath = [self appendIndexPath:toIndexPath forAssemblage:assemblage];
    [self.delegate assemblage:self didMoveObject:object fromIndexPath:newFromIndexPath toIndexPath:newToIndexPath];
}

- (void)didEndUpdatesForEnsemble:(id<RZAssemblageAccess>)assemblage
{
    self.updateCount -= 1;

    if ( self.updateCount == 0 ) {
        [self.delegate didEndUpdatesForEnsemble:self];
    }
}

@end
