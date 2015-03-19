//
//  RZAssemblageTableView.h
//  RZAssemblage
//
//  Created by Brian King on 3/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RZAssemblageTableViewDataSource.h"
@class RZAssemblageTableViewCellFactory;

@interface RZAssemblageTableView : UITableView

@property (strong, nonatomic) RZAssemblageTableViewCellFactory *cellFactory;

@property (weak, nonatomic) id<RZAssemblage> assemblage;

@property (weak, nonatomic) id<RZAssemblageTableViewDataSource> dataSource;

/**
 * Ignore assemblage delegate events while set to YES.  This should be enabled
 * while table view delegate mutation is occurring.
 *
 * NOTE: This will crash if you move an object into a filtered section that is filtered.
 */
@property (assign, nonatomic) BOOL ignoreAssemblageChanges;

@end
