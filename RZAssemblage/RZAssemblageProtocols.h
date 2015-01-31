//
//  RZAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol RZAssemblageDelegate;

// This protocol is the API used by data sources
@protocol RZAssemblage <NSObject>

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;


@property (weak, nonatomic) id<RZAssemblageDelegate> delegate;

@end

@protocol RZAssemblageMutationTraversal <RZAssemblage>

// Index Path mutation.
// These methods will assert if the index path lands on an assemblage that does not support RZMutableAssemblageSupport.
- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2;

@end

@protocol RZAssemblageMutationTraversalSupport <NSObject>

// Determine the index path to present to the delegate, given the indexPath specified by the child assemblage
- (NSIndexPath *)indexPathFromChildIndexPath:(NSIndexPath *)indexPath fromAssemblage:(id<RZAssemblage>)assemblage;

// Determine the child index path
- (NSIndexPath *)childIndexPathFromIndexPath:(NSIndexPath *)indexPath;

// Determine if the index path should terminate on this assemblage
- (BOOL)leafNodeForIndexPath:(NSIndexPath *)indexPath;

- (id<RZAssemblageMutationTraversal>)assemblageToTraverseForIndexPath:(NSIndexPath *)indexPath canBeEmpty:(BOOL)canBeEmpty;

@end

@protocol RZMutableAssemblageSupport <RZAssemblage>

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeObjectAtIndex:(NSUInteger)index;

@end

// This protocol is used by assemblage's to notify changes
@protocol RZAssemblageDelegate <NSObject>

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblage>)assemblage;
- (void)assemblage:(id<RZAssemblage>)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)assemblage:(id<RZAssemblage>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)assemblage:(id<RZAssemblage>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)assemblage:(id<RZAssemblage>)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)didEndUpdatesForEnsemble:(id<RZAssemblage>)assemblage;

@end
