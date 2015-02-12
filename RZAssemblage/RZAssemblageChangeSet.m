//
//  RZChangeSet.m
//  RZAssemblage
//
//  Created by Brian King on 2/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageChangeSet.h"
#import "RZMutableIndexPathSet.h"
#import "NSIndexPath+RZAssemblage.h"

@interface RZAssemblageChangeSet ()

@property (copy, nonatomic) id<RZAssemblage> startingAssemblage;

@property (strong, nonatomic) RZMutableIndexPathSet *inserts;
@property (strong, nonatomic) RZMutableIndexPathSet *updates;
@property (strong, nonatomic) RZMutableIndexPathSet *removes;
@property (strong, nonatomic) RZMutableIndexPathSet *moves;

@end

@implementation RZAssemblageChangeSet

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        _inserts = [RZMutableIndexPathSet mutableIndexPathSet];
        _updates = [RZMutableIndexPathSet mutableIndexPathSet];
        _removes = [RZMutableIndexPathSet mutableIndexPathSet];
        _moves   = [RZMutableIndexPathSet mutableIndexPathSet];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p \nI=%@, U=%@, R=%@, M=Not Supported>", self.class, self,
            self.insertedIndexPaths, self.updatedIndexPaths, self.removedIndexPaths];
}

- (NSArray *)insertedIndexPaths
{
    return self.inserts.sortedIndexPaths;
}

- (NSArray *)removedIndexPaths
{
    return self.removes.sortedIndexPaths;
}

- (NSArray *)updatedIndexPaths
{
    return self.updates.sortedIndexPaths;
}

- (void)beginUpdateWithAssemblage:(id<RZAssemblage>)assemblage
{
    if ( self.updateCount == 0 ) {
        self.startingAssemblage = assemblage;
    }
    _updateCount++;
}

- (void)endUpdateWithAssemblage:(id<RZAssemblage>)assemblage
{
    _updateCount--;
}

- (void)insertAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates shiftIndexesStartingAtIndexPath:indexPath by:1];
    [self.inserts shiftIndexesStartingAtIndexPath:indexPath by:1];
    [self.moves shiftIndexesStartingAtIndexPath:indexPath by:1];

    [self.inserts addIndexPath:indexPath];
}

- (void)updateAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates addIndexPath:indexPath];
}

- (void)removeAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL insertWasRemoved = [self.inserts containsIndexPath:indexPath];

    [self.updates shiftIndexesStartingAfterIndexPath:indexPath by:-1];
    [self.inserts shiftIndexesStartingAfterIndexPath:indexPath by:-1];
    [self.moves shiftIndexesStartingAfterIndexPath:indexPath by:-1];

    // Do nothing if the removal was an un-propagated insertion
    if ( insertWasRemoved == NO) {
        // If the index has already been removed, shift it down till it finds an empty index.
        NSIndexPath *indexPathToRemove = indexPath;
        while ( [self.removes containsIndexPath:indexPathToRemove] ) {
            indexPathToRemove = [indexPathToRemove rz_indexPathWithLastIndexShiftedBy:1];
        }
        [self.removes addIndexPath:indexPathToRemove];
    }
}

- (void)moveAtIndexPath:(NSIndexPath *)index1 toIndexPath:(NSIndexPath *)index2
{
    if ( [self.updates containsIndexPath:index1] ) {
        [self.updates removeIndexPath:index1];
        [self.updates addIndexPath:index2];
    }
    [self.moves addIndexPath:index2];
}

- (void)clearInsertAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates shiftIndexesStartingAtIndexPath:indexPath by:-1];
    [self.inserts shiftIndexesStartingAtIndexPath:indexPath by:-1];
    [self.moves shiftIndexesStartingAtIndexPath:indexPath by:-1];

    [self.inserts removeIndexPath:indexPath];

}

- (void)clearRemoveAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates shiftIndexesStartingAfterIndexPath:indexPath by:1];
    [self.inserts shiftIndexesStartingAfterIndexPath:indexPath by:1];
    [self.moves shiftIndexesStartingAfterIndexPath:indexPath by:1];

    [self.removes removeIndexPath:indexPath];
}

- (void)clearUpdateAtIndexPath:(NSIndexPath *)indexPath
{
    [self.updates removeIndexPath:indexPath];
}

- (void)mergeChangeSet:(RZAssemblageChangeSet *)changeSet
withIndexPathTransform:(RZAssemblageChangeSetIndexPathTransform)transform
{
    NSParameterAssert(transform);
    [changeSet.inserts enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        NSIndexPath *newIndexPath = transform(indexPath);
        [self insertAtIndexPath:newIndexPath];
    }];
    [changeSet.removes enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        NSIndexPath *newIndexPath = transform(indexPath);
        [self removeAtIndexPath:newIndexPath];
    }];
    [changeSet.updates enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        NSIndexPath *newIndexPath = transform(indexPath);
        [self updateAtIndexPath:newIndexPath];
    }];
    [changeSet.moves enumerateSortedIndexPathsUsingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
    }];

}

@end
