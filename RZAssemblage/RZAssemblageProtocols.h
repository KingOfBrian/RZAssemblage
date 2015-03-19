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
 */
@protocol RZAssemblage <NSObject, NSCopying>

- (id)representedObject;

/**
 *  Return an array representing all the children of the assemblage at indexPath.
 */
- (NSArray *)arrayProxyForIndexPath:(NSIndexPath *)indexPath;

/**
 *  Return a mutable array representing all the children of the assemblage at indexPath.
 *
 *  If the assemblage does not support mutation, this will return nil.
 */
- (NSMutableArray *)mutableArrayProxyForIndexPath:(NSIndexPath *)indexPath;

/**
 *  Return the number of children at the indexPath
 */
- (NSUInteger)childCountAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Return the child at the indexPath.
 */
- (id)childAtIndexPath:(NSIndexPath *)indexPath;

/**
 * The delegate to inform of changes.
 */
@property (weak, nonatomic) id<RZAssemblageDelegate> delegate;

- (void)notifyObjectUpdate:(id)object;

@end

/**
 *  This protocol informs the delegate of changes to the assemblage.
 */
@protocol RZAssemblageDelegate <NSObject>

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet;

@optional
- (void)willBeginUpdatesForAssemblage:(id<RZAssemblage>)assemblage;

@end
