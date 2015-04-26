//
//  RZTableViewFactory.h
//  RZTree
//
//  Created by Brian King on 3/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^RZTableViewCellFactoryBlock)(id tableViewCell, id object, NSIndexPath *indexPath);
typedef void(^RZTableViewReusableViewFactoryBlock)(id reusableView, id object);

@interface RZAssemblageTableViewCellFactory : NSObject

- (void)configureCellForClass:(Class)objectClass reuseIdentifier:(NSString *)reuseIdentifier block:(RZTableViewCellFactoryBlock)block;
- (void)configureReusableViewForClass:(Class)objectClass reuseIdentifier:(NSString *)reuseIdentifier block:(RZTableViewReusableViewFactoryBlock)block;

- (UITableViewCell *)cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath fromTableView:(UITableView *)tableView;
- (void)configureCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

- (UITableViewHeaderFooterView *)reusableViewForObject:(id)object fromTableView:(UITableView *)tableView;

@end

