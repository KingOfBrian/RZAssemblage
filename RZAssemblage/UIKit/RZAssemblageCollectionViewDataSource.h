//
//  RZAssemblageCollectionViewDataSource.h
//  RZAssemblage
//
//  Created by Brian King on 3/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RZAssemblage.h"
#import "RZAssemblageCollectionViewCellFactory.h"

@interface RZAssemblageCollectionViewDataSource : NSObject <UICollectionViewDataSource, RZAssemblageDelegate>

- (id)initWithAssemblage:(RZAssemblage *)assemblage
       forCollectionView:(UICollectionView *)collectionView
             cellFactory:(RZAssemblageCollectionViewCellFactory *)cellFactory;

@property (strong, nonatomic, readonly) RZAssemblage *assemblage;

@property (strong, nonatomic, readonly) RZAssemblageCollectionViewCellFactory *cellFactory;

@property (weak, nonatomic, readonly) UICollectionView *collectionView;

@property (weak, nonatomic) id<UICollectionViewDataSource> dataSource;

@property (assign, nonatomic) BOOL animateChanges;

- (id)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));

@end
