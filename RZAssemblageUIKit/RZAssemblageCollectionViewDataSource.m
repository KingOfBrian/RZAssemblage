//
//  RZAssemblageCollectionViewDataSource.m
//  RZTree
//
//  Created by Brian King on 3/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageCollectionViewDataSource.h"
#import "RZTree.h"
#import "RZAssemblageCollectionViewCellFactory.h"
#import "RZAssemblageDefines.h"
#import "RZChangeSet.h"

@interface RZAssemblageCollectionViewDataSource () <RZTreeObserver>

@end

@implementation RZAssemblageCollectionViewDataSource

- (id)initWithAssemblage:(RZTree *)node
       forCollectionView:(UICollectionView *)collectionView
{
    return [self initWithAssemblage:node forCollectionView:collectionView cellFactory:nil];
}

- (id)initWithAssemblage:(RZTree *)node
       forCollectionView:(UICollectionView *)collectionView
             cellFactory:(RZAssemblageCollectionViewCellFactory *)cellFactory
{
    NSParameterAssert(node);
    NSParameterAssert(collectionView);
    self = [super init];
    if ( self ) {
        _tree = node;
        _collectionView = collectionView;
        _collectionView.dataSource = self;
        _cellFactory = cellFactory != nil ? cellFactory : [[RZAssemblageCollectionViewCellFactory alloc] init];
    }
    return self;
}

#pragma mark - Required UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSUInteger count = [[self.tree children] count];
    RZDataSourceLog(@"%@", @(count));
    return count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSUInteger count = [[self.tree[section] children] count];
    RZDataSourceLog(@"%@", @(count));
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.tree objectAtIndexPath:indexPath];
    UICollectionViewCell *cell = [self.cellFactory cellForObject:object
                                                     atIndexPath:indexPath
                                              fromCollectionView:self.collectionView];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.tree objectAtIndexPath:indexPath];

    UICollectionReusableView *view = [self.cellFactory reusableViewOfKind:kind
                                                                forObject:object
                                                              atIndexPath:indexPath
                                                       fromCollectionView:collectionView];
    return view;
}

- (void)node:(RZTree *)node didEndUpdatesWithChangeSet:(RZChangeSet *)changeSet
{
    [changeSet generateMoveEventsFromNode:node];
    RZDataSourceLog(@"Update = %@", changeSet);
    [self.collectionView performBatchUpdates:^{
        NSIndexSet *indexesToDelete = [RZChangeSet sectionIndexSetFromIndexPaths:changeSet.removedIndexPaths];
        NSIndexSet *indexesToInsert = [RZChangeSet sectionIndexSetFromIndexPaths:changeSet.insertedIndexPaths];

        if ( indexesToDelete.count ) {
            [self.collectionView deleteSections:indexesToDelete];
        }
        if ( indexesToInsert.count ) {
            [self.collectionView insertSections:indexesToInsert];
        }

        NSArray *insertRows = [RZChangeSet rowIndexPathsFromIndexPaths:changeSet.insertedIndexPaths];
        NSArray *deleteRows = [RZChangeSet rowIndexPathsFromIndexPaths:changeSet.removedIndexPaths];
        NSArray *updateRows = [RZChangeSet rowIndexPathsFromIndexPaths:changeSet.updatedIndexPaths];

        if ( insertRows.count ) {
            [self.collectionView insertItemsAtIndexPaths:insertRows];
        }
        if ( deleteRows.count ) {
            [self.collectionView deleteItemsAtIndexPaths:deleteRows];
        }
        if ( updateRows.count ) {
            [self.collectionView reloadItemsAtIndexPaths:updateRows];
        }

        [changeSet.moveFromToIndexPaths enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *fromIndexPath, NSIndexPath *toIndexPath, BOOL *stop) {
            if ( fromIndexPath.length == 2 ) {
                [self.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
            }
        }];
    } completion:^(BOOL finished) {

    }];
}

@end
