//
//  RZAssemblageCollectionViewCellFactory.h
//  RZTree
//
//  Created by Brian King on 3/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^RZCollectionViewCellFactoryBlock)(id tableViewCell, id object, NSIndexPath *indexPath);
typedef void(^RZCollectionViewReusableViewFactoryBlock)(id reusableView, id object);

@interface RZAssemblageCollectionViewCellFactory : NSObject

- (void)configureCellForClass:(Class)objectClass reuseIdentifier:(NSString *)reuseIdentifier block:(RZCollectionViewCellFactoryBlock)block;
- (void)configureReusableViewForClass:(Class)objectClass kind:(NSString *)kind reuseIdentifier:(NSString *)reuseIdentifier block:(RZCollectionViewReusableViewFactoryBlock)block;

- (UICollectionViewCell *)cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath fromCollectionView:(UICollectionView *)collectionView;

- (UICollectionReusableView *)reusableViewOfKind:(NSString *)elementKind forObject:(id)object atIndexPath:(NSIndexPath *)indexPath fromCollectionView:(UICollectionView *)collectionView;


@end
