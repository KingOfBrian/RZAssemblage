//
//  RZBaseAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double RZAssemblageVersionNumber;
FOUNDATION_EXPORT const unsigned char RZAssemblageVersionString[];

#import "RZIndexPathSet.h"
#import "RZAssemblageChangeSet.h"
#import "NSIndexPath+RZAssemblage.h"

OBJC_EXTERN NSString *const RZAssemblageUpdateKey;

@protocol RZAssemblageDelegate;

/**
 *  RZAssemblage allows objects to be composed into trees of objects that can be
 *  accessed via NSIndexPath.  It also allows the mutation of the tree to percolate
 *  up the tree, and sync with supported UI elements.
 */
@interface RZAssemblage : NSObject

+ (RZAssemblage *)assemblageForArray:(NSArray *)array;
+ (RZAssemblage *)assemblageForArray:(NSArray *)array representedObject:(id)representedObject;
+ (RZAssemblage *)joinedAssemblages:(NSArray *)array;
+ (RZAssemblage *)assemblageTreeWithObject:(id)object arrayKeypaths:(NSArray *)keypaths;
+ (RZAssemblage *)assemblageTreeWithObject:(id)object arrayTreeKeypath:(NSArray *)keypaths;

/**
 *  Return the object that this assemblage represents.
 */
- (id)representedObject;

/**
 *  Return a mutable array proxy representing the children of the node at indexPath
 *
 *  If the assemblage does not support mutation, this will return nil.
 */
- (NSMutableArray *)mutableArrayForIndexPath:(NSIndexPath *)indexPath;

/**
 *  Return an array representing the children of the node at index path
 */
- (NSArray *)arrayForIndexPath:(NSIndexPath *)indexPath;

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

/**
 *  Return a snapshot of the tree.  This snapshot tree is used to lookup objects
 *  in the tree that were removed from the assemblage.
 */
- (RZAssemblage *)snapshotTree;

/**
 *  Open a batch of updates.   This will hold onto all changes until a matching
 *  number of closeBatchUpdate messages are sent.
 */
- (void)openBatchUpdate;

/**
 *  Notify a change to an object.   This is not required if the Key Value Observing is used.
 */
- (void)notifyObjectUpdate:(id)object;

/**
 *  Close a batch of updates.
 */
- (void)closeBatchUpdate;

/**
 *  Insert an object into the assemblage tree at the index path.
 */
- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

/**
 *  Remove the object at the specified index path.
 */
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Move an object from the specified index path to the specified index path.
 *  This change will be notified as a remove and an insert, unless generateMoveEventsFromAssemblage
 *  is called.
 */
- (void)moveObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@end

/**
 *  This protocol informs the delegate of changes to the assemblage.
 */
@protocol RZAssemblageDelegate <NSObject>

- (void)assemblage:(RZAssemblage *)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet;

@optional
- (void)willBeginUpdatesForAssemblage:(RZAssemblage *)assemblage;

@end
