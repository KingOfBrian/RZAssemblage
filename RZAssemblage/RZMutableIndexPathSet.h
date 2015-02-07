//
//  RZMutableIndexPathSet.h
//  RZAssemblage
//
//  Created by Brian King on 2/5/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RZMutableIndexPathNodeBlock)(NSIndexPath *containingIndexPath, NSIndexSet *indexes, BOOL *stop);
typedef void(^RZMutableIndexPathBlock)(NSIndexPath *indexPath, BOOL *stop);

@interface RZMutableIndexPathSet : NSObject

+ (instancetype)mutableIndexPathSet;

@property (strong, nonatomic, readonly) NSIndexSet *rootIndexes;

- (void)addIndex:(NSUInteger)index;
- (void)removeIndex:(NSUInteger)index;

- (void)addIndexPath:(NSIndexPath *)indexPath;
- (void)removeIndexPath:(NSIndexPath *)indexPath;

- (BOOL)containsIndexPath:(NSIndexPath *)indexPath;

- (void)shiftIndexesStartingAtIndexPath:(NSIndexPath *)IndexPath by:(NSUInteger)shift;
- (void)shiftIndexesStartingAfterIndexPath:(NSIndexPath *)IndexPath by:(NSUInteger)shift;

- (void)enumerateSortedIndexPathNodesUsingBlock:(RZMutableIndexPathNodeBlock)block;
- (void)enumerateSortedIndexPathsUsingBlock:(RZMutableIndexPathBlock)block;


@end
