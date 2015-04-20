//
//  RZAssemblageTableViewDataSource.h
//  RZTree
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RZTree;
@class RZAssemblageTableViewCellFactory;

@interface RZAssemblageTableViewDataSource : NSObject <UITableViewDataSource>

- (id)initWithAssemblage:(RZTree *)node
            forTableView:(UITableView *)tableView
             cellFactory:(RZAssemblageTableViewCellFactory *)cellFactory;

@property (strong, nonatomic, readonly) RZTree *assemblage;

@property (strong, nonatomic, readonly) RZAssemblageTableViewCellFactory *cellFactory;

@property (weak, nonatomic, readonly) UITableView *tableView;

@property (weak, nonatomic) id<UITableViewDataSource> dataSource;

@property (assign, nonatomic) BOOL animateChanges;

@property (nonatomic, assign) UITableViewRowAnimation addSectionAnimation;

/**
 *  Specify the UITableViewRowAnimation style for section removals.
 *  @note Defaults to UITableViewRowAnimationFade.
 */
@property (nonatomic, assign) UITableViewRowAnimation removeSectionAnimation;

/**
 *  Specify the UITableViewRowAnimation style for object additions.
 *  @note Defaults to UITableViewRowAnimationFade.
 */
@property (nonatomic, assign) UITableViewRowAnimation addObjectAnimation;

/**
 *  Specify the UITableViewRowAnimation style for object removals.
 *  @note Defaults to UITableViewRowAnimationFade.
 */
@property (nonatomic, assign) UITableViewRowAnimation removeObjectAnimation;

/**
 *  Specify the UITableViewRowAnimation style for object updates.
 *  @note Defaults to UITableViewRowAnimationFade.
 */
@property (nonatomic, assign) UITableViewRowAnimation updateObjectAnimation;

- (id)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));

@end

// Stub methods for the data source, to make the compiler happy.  These
// messassages will never be sent.
#define RZAssemblageTableViewDataSourceIsControllingCells() \
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section __attribute__((unavailable))\
{ return NSNotFound; }\
\
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath\
{ return nil; }
