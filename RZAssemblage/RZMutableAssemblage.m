//
//  RZMutableAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZMutableAssemblage.h"
#import "RZAssemblage+Private.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageDefines.h"

@interface RZMutableAssemblage()

@property (copy, nonatomic) NSMutableArray *store;

@end

@implementation RZMutableAssemblage

- (instancetype)initWithArray:(NSArray *)array
{
    NSParameterAssert(array);
    self = [super initWithArray:array];
    if ( self ) {
        _store = [array mutableCopy];
    }
    return self;
}

#pragma mark - Basic Mutation


- (void)addObject:(id)anObject
{
    [self insertObject:anObject atIndex:self.store.count];
}

- (void)removeLastObject
{
    [self beginUpdates];
    NSUInteger index = self.store.count - 1;
    [self.store removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self endUpdates];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Insert %@ at %zd", self, anObject, index);
    NSParameterAssert(anObject);
    [self assignDelegateIfObjectIsAssemblage:anObject];
    [self beginUpdates];
    [self.store insertObject:anObject atIndex:index];
    [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self endUpdates];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Remove at %zd", self, index);
    [self beginUpdates];
    [self.store removeObjectAtIndex:index];
    [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self endUpdates];
}

- (void)notifyObjectUpdate:(id)anObject
{
    NSParameterAssert(anObject);
    NSUInteger index = [self.store indexOfObject:anObject];
    RZAssemblageLog(@"%p:Update %@ at %zd", self, anObject, index);
    NSAssert(index != NSNotFound, @"Object is not part of assemblage");
    [self beginUpdates];
    [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self endUpdates];
}

@end

@implementation RZAssemblage (RZAssemblageMutation)

- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
{
    RZAssemblageLog(@"Insert %@ at %@", anObject, indexPath);
    id<RZAssemblage> assemblage = nil;
    NSIndexPath *newIndexPath = nil;

    [self lookupIndexPath:indexPath forRemoval:NO
               assemblage:&assemblage newIndexPath:&newIndexPath];

    RZRaize([assemblage isKindOfClass:[RZMutableAssemblage class]], @"IndexPath %@ must be mutable, not %@", indexPath, assemblage);
    RZMutableAssemblage *mutable = (id)assemblage;
    [mutable insertObject:anObject atIndex:[newIndexPath rz_lastIndex]];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    RZAssemblageLog(@"Remove %@", indexPath);
    id<RZAssemblage> assemblage = nil;
    NSIndexPath *newIndexPath = nil;

    [self lookupIndexPath:indexPath forRemoval:YES
               assemblage:&assemblage newIndexPath:&newIndexPath];

    RZRaize([assemblage isKindOfClass:[RZMutableAssemblage class]], @"IndexPath %@ must be mutable, not %@", indexPath, assemblage);
    RZMutableAssemblage *mutable = (id)assemblage;
    [mutable removeObjectAtIndex:[newIndexPath rz_lastIndex]];
}

- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2
{
    if ( [indexPath1 isEqual:indexPath2] ) {
        return;
    }
    RZAssemblageLog(@"Move %@ -> %@", indexPath1, indexPath2);
    [self beginUpdates];
    id object = [self objectAtIndexPath:indexPath1];
    [self removeObjectAtIndexPath:indexPath1];
    [self insertObject:object atIndexPath:indexPath2];
    [self endUpdates];
}

@end
