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

- (void)willBeginUpdatesForAssemblage:(RZAssemblage *)assemblage
{
    RZDataSourceLog(@"%@", assemblage);
    [self.tableView beginUpdates];
}

- (void)assemblage:(RZAssemblage *)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZDataSourceLog(@"%p I[%@] = %@", assemblage, [indexPath rz_shortDescription], object);
    if ( [self.class isSectionIndexPath:indexPath] ) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:[indexPath indexAtPosition:0]]
                      withRowAnimation:self.addSectionAnimation];
    }
    else {
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:self.addObjectAnimation];
    }
}

- (void)assemblage:(RZAssemblage *)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZDataSourceLog(@"%p R[%@] = %@", assemblage, [indexPath rz_shortDescription], object);
    if ( [self.class isSectionIndexPath:indexPath] ) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:[indexPath indexAtPosition:0]]
                      withRowAnimation:self.removeSectionAnimation];
    }
    else {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:self.removeObjectAnimation];
    }
}

- (void)assemblage:(RZAssemblage *)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZDataSourceLog(@"%p U[%@] = %@", assemblage, [indexPath rz_shortDescription], object);
    NSAssert([self.class isSectionIndexPath:indexPath] == NO, @"Do not know what to do for a section update");
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self.dataSource tableView:self.tableView
                    updateCell:cell
                     forObject:object
                   atIndexPath:indexPath];
}

- (void)assemblage:(RZAssemblage *)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    RZDataSourceLog(@"%p M[%@] -> [%@] = %@", assemblage, [fromIndexPath rz_shortDescription], [toIndexPath rz_shortDescription], object);
    if ( [self.class isSectionIndexPath:fromIndexPath] ) {
        [self.tableView moveSection:[fromIndexPath indexAtPosition:0]
                          toSection:[toIndexPath indexAtPosition:0]];
    }
    else {
        [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    }
}

- (void)didEndUpdatesForEnsemble:(RZAssemblage *)assemblage
{
    RZDataSourceLog(@"%@", assemblage);
    [self.tableView endUpdates];
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
