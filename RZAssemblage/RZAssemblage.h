//
//  RZAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double RZAssemblageVersionNumber;
FOUNDATION_EXPORT const unsigned char RZAssemblageVersionString[];

#import "RZAssemblageChangeSet.h"

OBJC_EXTERN NSString * __nonnull const RZAssemblageUpdateKey;

@class NSFetchedResultsController;

typedef NS_OPTIONS(NSUInteger, RZAssemblageEnumerationOptions) {
    RZAssemblageEnumerationNoOptions = kNilOptions,
    RZAssemblageEnumerationBreadthFirst = 1 << 1, // Default is depth first
    RZAssemblageEnumerationIncludeNilRepresentedObject = 1 << 2, // Default is to skip nil representations
};

@protocol RZAssemblageDelegate;

/**
 *  RZAssemblage allows objects to be composed into trees of objects that can be
 *  accessed via NSIndexPath.  It also allows the mutation of the tree to percolate
 *  up the tree, and sync with supported UI elements.
 */
@interface RZAssemblage : NSObject

+ (nonnull RZAssemblage *)assemblageForArray:(nonnull NSArray *)array;
+ (nonnull RZAssemblage *)assemblageForArray:(nonnull NSArray *)array representedObject:(nullable id)representedObject;
+ (nonnull RZAssemblage *)assemblageForFetchedResultsController:(nonnull NSFetchedResultsController *)frc;
+ (nonnull RZAssemblage *)joinedAssemblages:(nonnull NSArray *)array;
+ (nonnull RZAssemblage *)assemblageTreeWithObject:(nonnull id)object descendingKeypaths:(nonnull NSArray *)keypaths;
+ (nonnull RZAssemblage *)assemblageTreeWithObject:(nonnull id)object repeatingKeypath:(nonnull NSString *)keypath;
+ (nonnull RZAssemblage *)assemblageWithObject:(nonnull id)object leafKeypaths:(nonnull NSArray *)keypaths;

/**
 *  Return the object that this assemblage represents.
 */
- (nullable id)representedObject;

/**
 * Return an array of objects representing the children of this node.
 */
- (nonnull NSArray *)children;

/**
 * Return a mutable array of objects representing the children of this node. 
 *
 * If this node does not support proxy mutation, a nil object is returned.
 */
- (nullable NSMutableArray *)mutableChildren;

/**
 * Return the node at the specified index path. 
 *
 * This will raise an exception if an invalid index path is specified.
 */
- (nonnull RZAssemblage *)assemblageAtIndexPath:(nonnull NSIndexPath *)indexPath;

/**
 * Return the node value at the specified index path. 
 *
 * If nil is specified as an indexPath, it will be treated as an empty index path
 * This will return nil if there's no representedObject at the index path.
 * This will raise an exception if an invalid index path is specified.
 */
- (nullable id)objectAtIndexPath:(nullable NSIndexPath *)indexPath;

/**
 * Enumerate all nodes of the assemblage.  This does a depth first enumeration of all nodes, but it
 * will skip nodes with no representedObject.
 */
- (void)enumerateObjectsUsingBlock:(nonnull void (^)(id __nullable obj, NSIndexPath * __nonnull indexPath, BOOL * __nonnull stop))block;

- (void)enumerateObjectsWithOptions:(RZAssemblageEnumerationOptions)options usingBlock:(nonnull void (^)(id __nullable obj, NSIndexPath * __nonnull indexPath, BOOL * __nonnull stop))block;

/**
 * Short hand to look up a child node.
 */
- (nonnull RZAssemblage *)objectAtIndexedSubscript:(NSUInteger)index;

/**
 * Short hand to access a contained object. If the index path points to a node, the representedObject is returned,
 * otherwise, the representedObject is returned.
 */
- (nullable id)objectForKeyedSubscript:(nonnull NSIndexPath *)indexPath;

/**
 * The delegate to inform of changes.
 */
@property (weak, nonatomic, nullable) id<RZAssemblageDelegate> delegate;

/**
 *  Open a batch of updates.   This will hold onto all changes until a matching
 *  number of closeBatchUpdate messages are sent.
 */
- (void)openBatchUpdate;

/**
 *  Notify a change to an object.   This is not required if the Key Value Observing is used.
 */
- (void)notifyObjectUpdate:(nonnull id)object;

/**
 *  Close a batch of updates.
 */
- (void)closeBatchUpdate;

/**
 *  Insert an object into the assemblage tree at the index path.
 */
- (void)insertObject:(nonnull id)object atIndexPath:(nullable NSIndexPath *)indexPath;

/**
 *  Remove the object at the specified index path.
 */
- (void)removeObjectAtIndexPath:(nullable NSIndexPath *)indexPath;

/**
 *  Move an object from the specified index path to the specified index path.
 *  This change will be notified as a remove and an insert, unless generateMoveEventsFromAssemblage
 *  is called.
 */
- (void)moveObjectAtIndexPath:(nullable NSIndexPath *)fromIndexPath toIndexPath:(nullable NSIndexPath *)toIndexPath;

@end

/**
 *  This protocol informs the delegate of changes to the assemblage.
 */
@protocol RZAssemblageDelegate <NSObject>

- (void)assemblage:(nonnull RZAssemblage *)assemblage didEndUpdatesWithChangeSet:(nonnull RZAssemblageChangeSet *)changeSet;

@optional
- (void)willBeginUpdatesForAssemblage:(nonnull RZAssemblage *)assemblage;

@end

#import "RZFilterAssemblage.h"
