//
//  RZAssemblageTableViewDataSource.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RZAssemblage.h"

@protocol RZAssemblageTableViewDataSourceProxy <NSObject>

- (UITableViewCell*)tableView:(UITableView *)tableView cellForObject:(id)object atIndexPath:(NSIndexPath*)indexPath;
- (void)tableView:(UITableView *)tableView updateCell:(UITableViewCell*)cell forObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

@optional

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section;
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end

@interface RZAssemblageTableViewDataSource : NSObject <UITableViewDataSource, RZAssemblageDelegate>

- (id)initWithAssemblage:(RZAssemblage *)assemblage
            forTableView:(UITableView *)tableView
          withDataSource:(id<RZAssemblageTableViewDataSourceProxy>)dataSource;

@property (strong, nonatomic, readonly) id<RZAssemblage> assemblage;

@property (weak, nonatomic, readonly) UITableView *tableView;

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

@end
