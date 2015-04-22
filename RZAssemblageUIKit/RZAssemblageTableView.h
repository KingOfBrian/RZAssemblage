//
//  RZAssemblageTableView.h
//  RZTree
//
//  Created by Brian King on 3/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RZTree;
@class RZAssemblageTableViewCellFactory;

@interface RZAssemblageTableView : UITableView

@property (strong, nonatomic) RZAssemblageTableViewCellFactory *cellFactory;

@property (weak, nonatomic) RZTree *tree;

/**
 * Ignore assemblage delegate events while set to YES.  This should be enabled
 * while table view delegate mutation is occurring.
 *
 * NOTE: This will crash if you move an object into a filtered section that causes
 * the item to be filtered in the new section.  This can be fixed by informing the data
 * source of the expected change, and then reconciling if the change set does not occur.
 */
@property (assign, nonatomic) BOOL ignoreAssemblageChanges;

@end
