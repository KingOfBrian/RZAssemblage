//
//  RZChangeSet.h
//  RZAssemblage
//
//  Created by Brian King on 2/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RZMutableIndexPathSet;
@class RZAssemblage;

typedef NSIndexPath *(^RZAssemblageChangeSetIndexPathTransform)(NSIndexPath *indexPath);

@interface RZAssemblageChangeSet : NSObject

+ (NSIndexSet *)sectionIndexSetFromIndexPaths:(NSArray *)indexPaths;
+ (NSArray *)rowIndexPathsFromIndexPaths:(NSArray *)indexPaths;

@property (strong, nonatomic, readonly) NSArray *insertedIndexPaths;
@property (strong, nonatomic, readonly) NSArray *updatedIndexPaths;
@property (strong, nonatomic, readonly) NSArray *removedIndexPaths;

- (id)removedObjectAtIndexPath:(NSIndexPath *)indexPath;

@property (strong, nonatomic, readonly) NSDictionary *moveFromToIndexPaths;

- (void)generateMoveEventsFromAssemblage:(RZAssemblage *)assemblage;

@end
