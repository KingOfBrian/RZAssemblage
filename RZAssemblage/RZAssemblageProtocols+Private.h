//
//  RZAssemblageProtocols+Private.m
//  RZAssemblage
//
//  Created by Brian King on 1/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RZAssemblageMutationTraversalSupport <RZAssemblageMutationTraversal>

- (BOOL)traversalMutatesIndexPaths;

// Determine the index path to present to the delegate, given the indexPath specified by the child assemblage
- (NSIndexPath *)indexPathFromChildIndexPath:(NSIndexPath *)indexPath fromAssemblage:(id<RZAssemblage>)assemblage;

// Determine the child index path
- (NSIndexPath *)childIndexPathFromIndexPath:(NSIndexPath *)indexPath;

- (id<RZAssemblageMutationTraversalSupport>)assemblageToTraverseForIndexPath:(NSIndexPath *)indexPath canBeEmpty:(BOOL)canBeEmpty;

@end
