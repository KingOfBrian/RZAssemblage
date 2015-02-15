//
//  RZAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RZAssemblageDelegate;
@class RZAssemblageChangeSet;

/**
 * The RZAssemblage protocol allows objects to be composed into trees of objects that can be 
 * uniformly accessed via NSIndexPath, and allow change events to percolate up the tree.
 */
@protocol RZAssemblage <NSObject, NSCopying>

/**
 * The number of children contained by this assemblage.
 */
- (NSUInteger)numberOfChildren;

/**
 * Return the assemblage at the specified index.
 */
- (id)objectAtIndex:(NSUInteger)index;

/**
 * Traverse the assemblage tree to the assemblage at the specified indexPath
 * and return the number of children.
 *
 * NOTE: An exception is raised if any object specified in the indexPath does not conform to RZAssemblage
 */
- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Traverse the assemblage tree and return the object at the specified index path
 */
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Return a copy of the objects that are direct descendants of this assemblage
 */
@property (copy, nonatomic, readonly) NSArray *allObjects;

@property (weak, nonatomic) id<RZAssemblageDelegate> delegate;

@end

// This protocol is used by assemblage's to notify changes
@protocol RZAssemblageDelegate <NSObject>

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet;

@optional
- (void)willBeginUpdatesForAssemblage:(id<RZAssemblage>)assemblage;

@end
