//
//  RZIndexPathSet.h
//
//  Created by Brian King on 2/5/15.
//

// Copyright 2014 Raizlabs and other contributors
// http://raizlabs.com/
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

#pragma mark - RZIndexPathSet

@interface RZIndexPathSet : NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, readonly) NSUInteger count;

+ (instancetype)set;
+ (instancetype)setWithIndexPath:(NSIndexPath *)indexPath;
+ (instancetype)setWithIndexPathsInArray:(NSArray *)indexPaths;
+ (instancetype)setWithIndexPaths:(NSSet *)indexPaths;
+ (instancetype)setWithIndexPathSet:(RZIndexPathSet *)indexPathSet;

- (BOOL)containsIndexPath:(NSIndexPath *)indexPath;

- (NSIndexSet *)indexesAtIndexPath:(NSIndexPath *)parentPath;
- (void)enumerateIndexesUsingBlock:(void (^)(NSIndexPath *parentPath, NSIndexSet *indexes, BOOL *stop))block;

- (NSArray *)sortedIndexPaths;
- (void)enumerateIndexPathsUsingBlock:(void (^)(NSIndexPath *indexPath, BOOL *stop))block;

@end

#pragma mark - RZMutableIndexPathSet

@interface RZMutableIndexPathSet : RZIndexPathSet

- (void)shiftIndexesStartingAtIndexPath:(NSIndexPath *)indexPath by:(NSInteger)delta;
- (void)shiftIndexesStartingAfterIndexPath:(NSIndexPath *)indexPath by:(NSInteger)delta;

- (void)addIndexPath:(NSIndexPath *)indexPath;
- (void)addIndexPathsInArray:(NSArray *)indexPaths;
- (void)addIndexPaths:(NSSet *)indexPaths;
- (void)addIndexes:(NSIndexSet *)indexSet;

- (void)removeIndexPath:(NSIndexPath *)indexPath;
- (void)removeIndexPathsInArray:(NSArray *)indexPaths;
- (void)removeIndexPaths:(NSSet *)indexPaths;

- (void)unionSet:(RZIndexPathSet *)indexPathSet;
- (void)intersectSet:(RZIndexPathSet *)indexPathSet;
- (void)minusSet:(RZIndexPathSet *)indexPathSet;

- (void)removeAllIndexPaths;

@end

#pragma mark - NSIndexPath+RZExtensions

@interface NSIndexPath (RZExtensions)

- (NSIndexPath *)rz_indexPathByPrependingIndex:(NSUInteger)index;
- (NSIndexPath *)rz_indexPathByRemovingFirstIndex;

- (NSIndexPath *)rz_indexPathByInsertingIndex:(NSUInteger)index atPosition:(NSUInteger)position;
- (NSIndexPath *)rz_indexPathByReplacingIndexAtPosition:(NSUInteger)position withIndex:(NSUInteger)index;

- (NSUInteger)rz_lastIndex;

@end
