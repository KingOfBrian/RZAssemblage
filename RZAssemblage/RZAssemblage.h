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

#import "RZAssemblageChangeSet.h"

OBJC_EXTERN NSString *const RZAssemblageUpdateKey;

@class NSFetchedResultsController;

typedef NS_OPTIONS(NSUInteger, RZAssemblageEnumerationOptions) {
    RZAssemblageEnumerationNoOptions = 0,
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

+ (RZAssemblage *)assemblageForArray:(NSArray *)array;
+ (RZAssemblage *)assemblageForArray:(NSArray *)array representedObject:(id)representedObject;
+ (RZAssemblage *)joinedAssemblages:(NSArray *)array;
+ (RZAssemblage *)assemblageTreeWithObject:(id)object arrayKeypaths:(NSArray *)keypaths;
+ (RZAssemblage *)assemblageTreeWithObject:(id)object arrayTreeKeypath:(NSArray *)keypaths;
+ (RZAssemblage *)assemblageWithObject:(id)object leafKeypaths:(NSArray *)keypaths;
+ (RZAssemblage *)assemblageForFetchedResultsController:(NSFetchedResultsController *)frc;
//+ (RZAssemblage *)assemblageTreeWithObject:(id)object setKeypaths:(NSArray *)keypaths sortDescriptors:(NSArray *)sortDescriptors;

/**
 *  Return the object that this assemblage represents.
 */
- (id)representedObject;

/**
 * Return an array of objects representing the children of this node.
 */
- (NSArray *)children;

/**
 * Return a mutable array of objects representing the children of this node.
 */
- (NSMutableArray *)mutableChildren;

/**
 * Return the node at the specified index path.
 */
- (RZAssemblage *)assemblageAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Return the node value at the specified index path.
 */
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Enumerate all nodes of the assemblage.  This does a depth first enumeration of all nodes, but it
 * will skip nodes with no representedObject.
 */
- (void)enumerateObjectsUsingBlock:(void (^)(id obj, NSIndexPath *indexPath, BOOL *stop))block;

- (void)enumerateObjectsWithOptions:(RZAssemblageEnumerationOptions)options usingBlock:(void (^)(id obj, NSIndexPath *indexPath, BOOL *stop))block;

/**
 * The delegate to inform of changes.
 */
@property (weak, nonatomic) id<RZAssemblageDelegate> delegate;

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

#import "RZFilterAssemblage.h"

#import "RZAssemblageTableView.h"
#import "RZAssemblageTableViewDataSource.h"
#import "RZAssemblageTableViewCellFactory.h"
#import "RZAssemblageCollectionViewDataSource.h"
#import "RZAssemblageCollectionViewCellFactory.h"

