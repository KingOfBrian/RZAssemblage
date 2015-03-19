//
//  RZTableViewFactory.m
//  RZAssemblage
//
//  Created by Brian King on 3/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTableViewCellFactory.h"

@interface RZTableViewCellFactory ()

@property (strong, nonatomic, readonly) NSMutableDictionary *classToReuseIdentifier;
@property (strong, nonatomic, readonly) NSMutableDictionary *reuseIdentifierToBlock;

@end

@implementation RZTableViewCellFactory

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        _classToReuseIdentifier = [NSMutableDictionary dictionary];
        _reuseIdentifierToBlock = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)configureCellForClass:(Class)objectClass reuseIdentifier:(NSString *)reuseIdentifier block:(RZTableViewCellFactoryBlock)block
{
    NSParameterAssert(objectClass);
    NSParameterAssert(reuseIdentifier);
    NSParameterAssert(block);
    NSAssert(self.classToReuseIdentifier[NSStringFromClass(objectClass)] == nil, @"Class is already configured");
    NSAssert(self.reuseIdentifierToBlock[reuseIdentifier] == nil, @"Reuse identifier is already configured");
    self.classToReuseIdentifier[NSStringFromClass(objectClass)] = reuseIdentifier;
    self.reuseIdentifierToBlock[reuseIdentifier] = [block copy];
}

- (void)configureReusableViewForClass:(Class)objectClass reuseIdentifier:(NSString *)reuseIdentifier block:(RZTableViewReusableViewFactoryBlock)block;
{
    NSParameterAssert(objectClass);
    NSParameterAssert(reuseIdentifier);
    NSParameterAssert(block);
    NSAssert(self.classToReuseIdentifier[NSStringFromClass(objectClass)] == nil, @"Class is already configured");
    NSAssert(self.reuseIdentifierToBlock[reuseIdentifier] == nil, @"Reuse identifier is already configured");
    self.classToReuseIdentifier[NSStringFromClass(objectClass)] = reuseIdentifier;
    self.reuseIdentifierToBlock[reuseIdentifier] = [block copy];
}

- (NSString *)reuseIdentifierForObject:(id)object
{
    __block NSString *identifier = nil;
    [self.classToReuseIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString *classname, NSString *reuseIdentifier, BOOL *stop) {
        if ( [object isKindOfClass:NSClassFromString(classname)] ) {
            identifier = reuseIdentifier;
            *stop = YES;
        }
    }];
    return identifier;
}

- (UITableViewCell *)cellForObject:(id)object atIndexPath:(NSIndexPath *)indexPath fromTableView:(UITableView *)tableView
{
    NSString *identifier = [self reuseIdentifierForObject:object];
    NSAssert(identifier != nil, @"Unable to find re-use identifer for %@", object);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [self configureCell:cell forObject:object atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSParameterAssert(cell);
    NSParameterAssert(object);
    NSParameterAssert(indexPath);
    NSString *identifier = [self reuseIdentifierForObject:object];
    RZTableViewCellFactoryBlock configureBlock = self.reuseIdentifierToBlock[identifier];
    configureBlock(cell, object, indexPath);
}

- (UITableViewHeaderFooterView *)reusableViewForObject:(id)object fromTableView:(UITableView *)tableView
{
    NSString *identifier = [self reuseIdentifierForObject:object];
    UITableViewHeaderFooterView *reusableView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:identifier];
    NSAssert(reusableView != nil, @"Reuse Identifier '%@' is not registered with tableview", identifier);
    RZTableViewReusableViewFactoryBlock configureBlock = self.reuseIdentifierToBlock[identifier];
    configureBlock(reusableView, object);
    return reusableView;
}

@end
