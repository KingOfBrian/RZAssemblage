//
//  RZChangeSet+Private.h
//  RZTree
//
//  Created by Brian King on 2/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZChangeSet.h"
#import "RZIndexPathSet.h"

typedef NSIndexPath *(^RZChangeSetIndexPathTransform)(NSIndexPath *indexPath);

@interface RZChangeSet ()

@property (assign, nonatomic) BOOL shiftIndexes;
@property (strong, nonatomic) RZMutableIndexPathSet *inserts;
@property (strong, nonatomic) RZMutableIndexPathSet *updates;

@property (strong, nonatomic) NSMutableDictionary *removedObjectsByIndexPath;
@property (strong, nonatomic) NSMutableDictionary *moveFromToIndexPathMap;

- (void)insertAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateAtIndexPath:(NSIndexPath *)indexPath;
- (void)removeObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)moveAtIndexPath:(NSIndexPath *)index1 toIndexPath:(NSIndexPath *)index2;

- (void)mergeChangeSet:(RZChangeSet *)changeSet withIndexPathTransform:(RZChangeSetIndexPathTransform)transform;

@end
