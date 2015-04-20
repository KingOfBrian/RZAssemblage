//
//  RZAssemblageCollectionViewDataSource.h
//  RZTree
//
//  Created by Brian King on 3/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RZTree;
@class RZAssemblageCollectionViewCellFactory;

@interface RZAssemblageCollectionViewDataSource : NSObject <UICollectionViewDataSource>

- (id)initWithAssemblage:(RZTree *)node
       forCollectionView:(UICollectionView *)collectionView
             cellFactory:(RZAssemblageCollectionViewCellFactory *)cellFactory;

@property (strong, nonatomic, readonly) RZTree *assemblage;

@property (strong, nonatomic, readonly) RZAssemblageCollectionViewCellFactory *cellFactory;

@property (weak, nonatomic, readonly) UICollectionView *collectionView;

@property (weak, nonatomic) id<UICollectionViewDataSource> dataSource;

@property (assign, nonatomic) BOOL animateChanges;

- (id)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));

@end
