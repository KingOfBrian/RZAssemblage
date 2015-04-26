//
//  RZAssemblageTableViewDataSource.m
//  RZTree
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageTableViewDataSource.h"
#import "RZAssemblageTableViewCellFactory.h"
#import "RZAssemblageDefines.h"
#import "RZChangeSet.h"
#import "RZTree.h"

@interface RZAssemblageTableViewDataSource() <RZTreeObserver>

@end

@implementation RZAssemblageTableViewDataSource

+ (BOOL)isSectionIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.length == 1;
}

- (id)initWithAssemblage:(RZTree *)node
            forTableView:(UITableView *)tableView
             cellFactory:(RZAssemblageTableViewCellFactory *)cellFactory;
{
    self = [super init];
    if ( self ) {
        _tree = node;
        [_tree addObserver:self];
        _cellFactory = cellFactory;
        _tableView = tableView;
        _addSectionAnimation = UITableViewRowAnimationFade;
        _removeSectionAnimation = UITableViewRowAnimationFade;
        _addObjectAnimation = UITableViewRowAnimationFade;
        _updateObjectAnimation = UITableViewRowAnimationFade;
        _removeObjectAnimation = UITableViewRowAnimationFade;
    }
    return self;
}

#pragma mark - Required UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSUInteger count = self.tree.children.count;
    RZDataSourceLog(@"%@", @(count));
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = self.tree[section].children.count;
    RZDataSourceLog(@"%@", @(count));
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.tree objectAtIndexPath:indexPath];
    UITableViewCell *cell = [self.cellFactory cellForObject:object atIndexPath:indexPath fromTableView:self.tableView];
    return cell;
}

#pragma mark - RZAssemblageDelegate

- (void)node:(RZTree *)node didEndUpdatesWithChangeSet:(RZChangeSet *)changeSet
{
    [changeSet generateMoveEventsFromNode:node];
    RZDataSourceLog(@"Update = %@", changeSet);
    // The RZAssemblageChangeSet needs a better API here.
    [self.tableView beginUpdates];
    // Process section insert / removes
    for ( NSIndexPath *indexPath in changeSet.removedIndexPaths ) {
        if ( indexPath.length == 1 ) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:[indexPath indexAtPosition:0]]
                          withRowAnimation:self.removeSectionAnimation];
        }
    }
    for ( NSIndexPath *indexPath in changeSet.insertedIndexPaths ) {
        if ( indexPath.length == 1 ) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:[indexPath indexAtPosition:0]]
                          withRowAnimation:self.addSectionAnimation];
        }
    }
    for ( NSIndexPath *indexPath in changeSet.removedIndexPaths ) {
        if ( indexPath.length == 2 ) {
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                  withRowAnimation:self.removeObjectAnimation];
        }
    }
    for ( NSIndexPath *indexPath in changeSet.insertedIndexPaths ) {
        if ( indexPath.length == 2 ) {
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:self.addObjectAnimation];
        }
    }
    [changeSet.moveFromToIndexPaths enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *fromIndexPath, NSIndexPath *toIndexPath, BOOL *stop) {
        if ( fromIndexPath.length == 2 ) {
            [self.tableView moveRowAtIndexPath:fromIndexPath
                                   toIndexPath:toIndexPath];
        }
    }];
    for ( NSIndexPath *indexPath in changeSet.updatedIndexPaths ) {
        NSAssert(indexPath.length == 2, @"");
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        // Update the cell if it is visible.
        if ( cell ) {
            id object = [self.tree objectAtIndexPath:indexPath];
            [self.cellFactory configureCell:cell forObject:object atIndexPath:indexPath];
        }
    }

    [self.tableView endUpdates];
}

#pragma - Relay Optional UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *result = nil;
    if ( [self.dataSource respondsToSelector:_cmd] ) {
        result = [self.dataSource tableView:tableView titleForHeaderInSection:section];
    }
    return result;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *result = nil;
    if ( [self.dataSource respondsToSelector:_cmd] ) {
        result = [self.dataSource tableView:tableView titleForFooterInSection:section];
    }
    return result;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL result = NO;
    if ( [self.dataSource respondsToSelector:_cmd] ) {
        result = [self.dataSource tableView:tableView canEditRowAtIndexPath:indexPath];
    }
    return result;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL result = NO;
    if ( [self.dataSource respondsToSelector:_cmd] ) {
        result = [self.dataSource tableView:tableView canMoveRowAtIndexPath:indexPath];
    }
    return result;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSArray *result = nil;
    if ( [self.dataSource respondsToSelector:_cmd] ) {
        result = [self.dataSource sectionIndexTitlesForTableView:tableView];
    }
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSInteger result = NSNotFound;
    if ( [self.dataSource respondsToSelector:_cmd] ) {
        result = [self.dataSource tableView:tableView
                sectionForSectionIndexTitle:title
                                    atIndex:index];
    }
    return result;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.dataSource respondsToSelector:_cmd] ? [self.dataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath]:nil;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sIndexPath toIndexPath:(NSIndexPath *)dIndexPath
{
    [self.dataSource respondsToSelector:_cmd] ? [self.dataSource tableView:tableView moveRowAtIndexPath:sIndexPath toIndexPath:dIndexPath]:nil;
}

@end
