//
//  RZAssemblageCollectionViewDataSource.m
//  RZAssemblage
//
//  Created by Brian King on 3/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageCollectionViewDataSource.h"
#import "RZAssemblage.h"
#import "RZAssemblageCollectionViewCellFactory.h"
#import "RZAssemblageDefines.h"
#import "RZAssemblageChangeSet.h"

@interface RZAssemblageCollectionViewDataSource () <RZAssemblageObserver>

@end

@implementation RZAssemblageCollectionViewDataSource

- (id)initWithAssemblage:(RZAssemblage *)assemblage
       forCollectionView:(UICollectionView *)collectionView
             cellFactory:(RZAssemblageCollectionViewCellFactory *)cellFactory;
{
    self = [super init];
    if ( self ) {
        _assemblage = assemblage;
        _collectionView = collectionView;
        _cellFactory = cellFactory;
    }
    return self;
}

#pragma mark - Required UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    NSUInteger count = [[self.assemblage children] count];
    RZDataSourceLog(@"%@", @(count));
    return count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSUInteger count = [[self.assemblage assemblageAtIndexPath:[NSIndexPath indexPathWithIndex:section]] children].count;
    RZDataSourceLog(@"%@", @(count));
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.assemblage objectAtIndexPath:indexPath];
    UICollectionViewCell *cell = [self.cellFactory cellForObject:object
                                                     atIndexPath:indexPath
                                              fromCollectionView:self.collectionView];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.assemblage objectAtIndexPath:indexPath];

    UICollectionReusableView *view = [self.cellFactory reusableViewOfKind:kind
                                                                forObject:object
                                                              atIndexPath:indexPath
                                                       fromCollectionView:collectionView];
    return view;
}

- (void)assemblage:(RZAssemblage *)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    [changeSet generateMoveEventsFromAssemblage:assemblage];
    RZDataSourceLog(@"Update = %@", changeSet);
    [self.collectionView performBatchUpdates:^{
        NSIndexSet *indexesToDelete = [RZAssemblageChangeSet sectionIndexSetFromIndexPaths:changeSet.removedIndexPaths];
        NSIndexSet *indexesToInsert = [RZAssemblageChangeSet sectionIndexSetFromIndexPaths:changeSet.insertedIndexPaths];

        if ( indexesToDelete.count ) {
            [self.collectionView deleteSections:indexesToDelete];
        }
        if ( indexesToInsert.count ) {
            [self.collectionView insertSections:indexesToInsert];
        }

        NSArray *insertRows = [RZAssemblageChangeSet rowIndexPathsFromIndexPaths:changeSet.insertedIndexPaths];
        NSArray *deleteRows = [RZAssemblageChangeSet rowIndexPathsFromIndexPaths:changeSet.removedIndexPaths];
        NSArray *updateRows = [RZAssemblageChangeSet rowIndexPathsFromIndexPaths:changeSet.updatedIndexPaths];

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
