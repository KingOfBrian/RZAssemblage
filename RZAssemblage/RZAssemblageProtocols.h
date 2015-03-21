//
//  RZAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSIndexPath+RZAssemblage.h"

@protocol RZAssemblageDelegate;
@class RZAssemblageChangeSet;

/**
 * The RZAssemblage protocol allows objects to be composed into trees of objects that can be 
 * uniformly accessed via NSIndexPath, and allow change events to percolate up the tree.
 *
 * The NSCopying implementation should return a copy of the index space and does not preserve
 * any other state.   Any filter, join, FRC based assemblages may return it's content, and not
 * replica's if it's own state if it simplifies the implementation.  Copying is only required for
 * change observation, since the initial index space before a change involving removals must be 
 * known to properly manage binding.
 */
@protocol RZAssemblage <NSObject, NSCopying>

- (id)representedObject;

/**
 *  Return a mutable array proxy representing the children of the indexPath
 *
 *  If the assemblage does not support mutation, this will return nil.
 */
- (NSMutableArray *)mutableArrayForIndexPath:(NSIndexPath *)indexPath;

/**
 *  Return the number of children at the indexPath
 */
- (NSUInteger)childCountAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Return the child at the indexPath.  If the child is an assemblage,
 *  this will return the represented object.
 */
- (id)childAtIndexPath:(NSIndexPath *)indexPath;

/**
 * The delegate to inform of changes.
 */
@property (weak, nonatomic) id<RZAssemblageDelegate> delegate;

@end

/**
 *  This protocol informs the delegate of changes to the assemblage.
 */
@protocol RZAssemblageDelegate <NSObject>

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet;

@optional
- (void)willBeginUpdatesForAssemblage:(id<RZAssemblage>)assemblage;

@end
