//
//  RZAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

// This protocol is the API used by data sources
@protocol RZAssemblageAccess <NSObject>

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

@end

// This protocol is used by assemblage's to implement nesting
@protocol RZAssemblageNesting <RZAssemblageAccess>

- (NSUInteger)indexForObject:(id)object;

@end

// This protocol is used by assemblage's to notify changes
@protocol RZAssemblageDelegate <NSObject>

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblageAccess>)assemblage;
- (void)assemblage:(id<RZAssemblageAccess>)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)assemblage:(id<RZAssemblageAccess>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)assemblage:(id<RZAssemblageAccess>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)assemblage:(id<RZAssemblageAccess>)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)didEndUpdatesForEnsemble:(id<RZAssemblageAccess>)assemblage;

@end