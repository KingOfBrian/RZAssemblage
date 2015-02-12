//
//  RZAssemblageTableViewDataSource.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageTableViewDataSource.h"
#import "RZAssemblageDefines.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblageChangeSet.h"
#import "RZMutableIndexPathSet.h"

@interface RZAssemblageTableViewDataSource() <UITableViewDataSource, RZAssemblageDelegate>

@property (weak, nonatomic, readonly) NSObject<RZAssemblageTableViewDataSourceProxy> *dataSource;

@end

@implementation RZAssemblageTableViewDataSource

+ (BOOL)isSectionIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.length == 1;
}

- (id)initWithAssemblage:(RZAssemblage *)assemblage
            forTableView:(UITableView *)tableView
          withDataSource:(id<RZAssemblageTableViewDataSourceProxy>)dataSource
{
    self = [super init];
    if ( self ) {
        _assemblage = assemblage;
        _assemblage.delegate = self;
        _tableView = tableView;
        _tableView.dataSource = self;
        _dataSource = dataSource;
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
    NSUInteger count = [self.assemblage numberOfChildrenAtIndexPath:nil];
    RZDataSourceLog(@"%@", @(count));
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = [self.assemblage numberOfChildrenAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
    RZDataSourceLog(@"%@", @(count));
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.assemblage objectAtIndexPath:indexPath];
    UITableViewCell *cell = [self.dataSource tableView:tableView cellForObject:object atIndexPath:indexPath];
    [self.dataSource tableView:tableView updateCell:cell forObject:object atIndexPath:indexPath];
    return cell;
}

#pragma mark - RZAssemblageDelegate

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
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
    for ( NSIndexPath *indexPath in changeSet.updatedIndexPaths ) {
        NSAssert(indexPath.length == 2, @"");
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        id object = [assemblage objectAtIndexPath:indexPath];
        [self.dataSource tableView:self.tableView
                        updateCell:cell
                         forObject:object
                       atIndexPath:indexPath];
    }
#warning moves

    [self.tableView endUpdates];
}

- (void)willBeginUpdatesForAssemblage:(RZAssemblage *)assemblage
{
    RZDataSourceLog(@"%@", assemblage);
}

- (void)didEndUpdatesForEnsemble:(RZAssemblage *)assemblage
{
    RZDataSourceLog(@"%@", assemblage);
}

#pragma - Relay Optional UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.dataSource respondsToSelector:_cmd] ? [self.dataSource tableView:tableView titleForHeaderInSection:section] : nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [self.dataSource respondsToSelector:_cmd] ? [self.dataSource tableView:tableView titleForFooterInSection:section] : nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.dataSource respondsToSelector:_cmd] ? [self.dataSource tableView:tableView canEditRowAtIndexPath:indexPath] : NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.dataSource respondsToSelector:_cmd] ? [self.dataSource tableView:tableView canMoveRowAtIndexPath:indexPath] : NO;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self.dataSource respondsToSelector:_cmd] ? [self.dataSource sectionIndexTitlesForTableView:tableView] : nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return [self.dataSource respondsToSelector:_cmd] ? [self.dataSource tableView:tableView
                                                      sectionForSectionIndexTitle:title
                                                                          atIndex:index] : index;
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
