//
//  RZAssemblageTableView.h
//  RZAssemblage
//
//  Created by Brian King on 3/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RZAssemblageTableViewDataSource.h"
@class RZTableViewCellFactory;

@interface RZAssemblageTableView : UITableView

@property (strong, nonatomic) RZTableViewCellFactory *cellFactory;

@property (weak, nonatomic) id<RZAssemblage> assemblage;

@property (weak, nonatomic) id<RZAssemblageTableViewDataSource> dataSource;

@property (assign, nonatomic) BOOL ignoreAssemblageChanges;

@end
