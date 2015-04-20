//
//  RZTree.h
//  RZTree
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double RZAssemblageVersionNumber;
FOUNDATION_EXPORT const unsigned char RZAssemblageVersionString[];

OBJC_EXTERN NSString * __nonnull const RZTreeUpdateKey;

@class RZChangeSet;
@class NSFetchedResultsController;
@protocol RZTreeObserver;
@protocol RZFilterableTree;

typedef NS_OPTIONS(NSUInteger, RZTreeEnumerationOptions) {
    RZTreeEnumerationNoOptions = kNilOptions,
    RZTreeEnumerationBreadthFirst = 1 << 1, // Default is depth first
    RZTreeEnumerationIncludeNilRepresentedObject = 1 << 2, // Default is to skip nil representations
};

/**
 *  RZTree helps building trees of objects that can be
 *  accessed via NSIndexPath. It also allows the mutation of the tree to percolate
 *  up the tree, and sync with supported UI elements.
 */
@interface RZTree : NSObject

/**
 * Create a new node with children. All of the children will be observed.
 */
+ (nonnull RZTree *)nodeWithChildren:(nonnull NSArray *)array;

/**
 *  Create a new node representing `object`, with the children. All of the children will be observed, and
 *  the represented object will be observed.
 */
+ (nonnull RZTree *)nodeWithObject:(nullable id)representedObject children:(nonnull NSArray *)array;

/**
 *  Create a new node representing object, and have the children be represented by the array specified
 *  in the first keypath of keypaths. Any mutation to the children of this node will also cause mutation
 *  of the backing array. Any mutation of the children array made with KVC compliant operations will also
 *  update the children of the node.
 *
 *  The children nodes will be created recursively, with the first keypath poped off of the keypaths array.
 *  Every specified keypath should specify an array.
 */
+ (nonnull RZTree *)nodeWithObject:(nonnull id)object descendingKeypaths:(nonnull NSArray *)keypaths;

/**
 *  Create a new node representing object, and have the children be represented by the array at the keypath 
 *  specified. Any mutation to children of this node will also cause mutation of the backing array. Any 
 *  mutation of the children array made with KVC compliant operations will also update the children of the node.
 *
 *  The children nodes will be created by probing the same keypath.
 *  Every specified keypath should specify an array.
 */
+ (nonnull RZTree *)nodeWithObject:(nonnull id)object repeatingKeypath:(nonnull NSString *)keypath;

/**
 *  Create a new node representing object, and have the children be represented by the objects represented in
 *  `keypaths`. 
 *
 *  Every keypath in keypaths should point to a singular object.
 */
+ (nonnull RZTree *)nodeWithObject:(nonnull id)object leafKeypaths:(nonnull NSArray *)keypaths;

/**
 *  Create a new node backed by the NSFetchedResultsController. If the NSFetchedResultsController specifies a 
 *  `sectionNameKeyPath`, the node will have a depth of 2.
 *
 *  If the NSFetchedResultsController does not specify sectionNameKeyPath all indexing will be stripped of the
 *  section, allowing for better composibility (IE: 1 NSFRC for section 1, and 1 NSFRC for section 2)
 */
+ (nonnull RZTree *)nodeBackedByFetchedResultsController:(nonnull NSFetchedResultsController *)frc;

/**
 *  Create a new node that joins the index space of all the joined nodes.  This means that indexing into the second
 *  node will start at the count of the previous node.
 */
+ (nonnull RZTree *)nodeWithJoinedNodes:(nonnull NSArray *)joinedNodes;

/**
 *  Return a filterable node that filters all children of node.
 */
+ (nonnull RZTree<RZFilterableTree> *)filterableNodeWithNode:(nonnull RZTree *)node;

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
- (nonnull RZTree *)nodeAtIndexPath:(nonnull NSIndexPath *)indexPath;

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

- (void)enumerateObjectsWithOptions:(RZTreeEnumerationOptions)options usingBlock:(nonnull void (^)(id __nullable obj, NSIndexPath * __nonnull indexPath, BOOL * __nonnull stop))block;

/**
 * Short hand to look up a child node.
 */
- (nonnull RZTree *)objectAtIndexedSubscript:(NSUInteger)index;

/**
 * Short hand to access a contained object. If the index path points to a node, the representedObject is returned,
 * otherwise, the representedObject is returned.
 */
- (nullable id)objectForKeyedSubscript:(nonnull NSIndexPath *)indexPath;

/**
 *  Register an observer to be notified of changes to the tree.
 */
- (void)addObserver:(nonnull id<RZTreeObserver>)observer;

/**
 *  Unregister an observer.
 */
- (void)removeObserver:(nonnull id<RZTreeObserver>)observer;

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
 *  This change will be notified as a remove and an insert, unless generateMoveEventsFromNode
 *  is called.
 */
- (void)moveObjectAtIndexPath:(nullable NSIndexPath *)fromIndexPath toIndexPath:(nullable NSIndexPath *)toIndexPath;

@end

/**
 *  This protocol informs the delegate of changes to the assemblage.
 */
@protocol RZTreeObserver <NSObject>

- (void)node:(nonnull RZTree *)node didEndUpdatesWithChangeSet:(nonnull RZChangeSet *)changeSet;

@optional
- (void)willBeginUpdatesForNode:(nonnull RZTree *)node;

@end

@protocol RZFilterableTree <NSObject>

- (void)setFilter:(nullable NSPredicate *)filter;

@end