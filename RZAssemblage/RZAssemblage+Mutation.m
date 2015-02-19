//
//  RZAssemblage+Mutation.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage+Mutation.h"
#import "RZAssemblage+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageDefines.h"
#import "RZAssemblageMutationRelay.h"


@implementation RZAssemblage (RZAssemblageMutation)

- (void)addObject:(id)anObject
{
    [self insertObject:anObject atIndex:self.store.count];
}

- (void)removeLastObject
{
    [self openBatchUpdate];
    NSUInteger index = self.store.count - 1;
    [self.store removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Insert %@ at %zd", self, anObject, index);
    NSParameterAssert(anObject);
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self openBatchUpdate];
    [self.store insertObject:anObject atIndex:index];
    [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Remove at %zd", self, index);
    [self openBatchUpdate];
    [self.store removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self.store indexOfObject:anObject];
    RZAssemblageLog(@"%p:Update %@ at %zd", self, anObject, index);
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self openBatchUpdate];
    [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
{
    RZAssemblageLog(@"Insert %@ at %@", anObject, indexPath);
    id<RZAssemblage> assemblage = nil;
    NSIndexPath *newIndexPath = nil;

    [self lookupIndexPath:indexPath forRemoval:NO
               assemblage:&assemblage newIndexPath:&newIndexPath];

    RZConformMutationSupportAtIndexPath(assemblage, indexPath);
    id<RZAssemblageMutation> mutable = (id)assemblage;
    [mutable insertObject:anObject atIndex:[newIndexPath rz_lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RZAssemblageLog(@"Remove %@", indexPath);
    id<RZAssemblage> assemblage = nil;
    NSIndexPath *newIndexPath = nil;

    [self lookupIndexPath:indexPath forRemoval:YES
               assemblage:&assemblage newIndexPath:&newIndexPath];

    RZConformMutationSupportAtIndexPath(assemblage, indexPath);
    id<RZAssemblageMutation> mutable = (id)assemblage;
    [mutable removeObjectAtIndex:[newIndexPath rz_lastIndex]];
}

- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2
{
    if ( [indexPath1 isEqual:indexPath2] ) {
        return;
    }
    RZAssemblageLog(@"Move %@ -> %@", indexPath1, indexPath2);
    [self openBatchUpdate];
    id object = [self objectAtIndexPath:indexPath1];
    [self removeObjectAtIndexPath:indexPath1];
    [self insertObject:object atIndexPath:indexPath2];
    [self closeBatchUpdate];
}

@end
