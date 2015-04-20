//
//  RZChangeSet.h
//  RZTree
//
//  Created by Brian King on 2/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RZTree;

@interface RZChangeSet : NSObject

+ (NSIndexSet *)sectionIndexSetFromIndexPaths:(NSArray *)indexPaths;
+ (NSArray *)rowIndexPathsFromIndexPaths:(NSArray *)indexPaths;

@property (strong, nonatomic, readonly) NSArray *insertedIndexPaths;
@property (strong, nonatomic, readonly) NSArray *updatedIndexPaths;
@property (strong, nonatomic, readonly) NSArray *removedIndexPaths;
@property (strong, nonatomic, readonly) NSDictionary *moveFromToIndexPaths;

- (id)removedObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)generateMoveEventsFromNode:(RZTree *)node;

@end
