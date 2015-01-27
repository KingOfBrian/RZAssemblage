//
//  RZAssemblageTableViewDataSource.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageTableViewDataSource.h"
@interface RZAssemblageTableViewDataSource() <UITableViewDataSource>

@property (weak, nonatomic, readonly) NSObject<RZAssemblageTableViewDataSourceProxy> *dataSource;

@end

@implementation RZAssemblageTableViewDataSource

+ (BOOL)isSectionIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.length == 1;
}

- (id)initWithAssemblage:(id<RZAssemblageAccess>)assemblage
            forTableView:(UITableView *)tableView
          withDataSource:(id<RZAssemblageTableViewDataSourceProxy>)dataSource
{
    self = [super init];
    if ( self ) {
        _assemblage = assemblage;
        _tableView = tableView;
        _dataSource = dataSource;
        _addSectionAnimation = UITableViewRowAnimationFade;
        _removeSectionAnimation = UITableViewRowAnimationFade;
        _addObjectAnimation = UITableViewRowAnimationFade;
        _updateObjectAnimation = UITableViewRowAnimationFade;
        _removeObjectAnimation = UITableViewRowAnimationFade;
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.assemblage numberOfChildrenAtIndexPath:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.assemblage numberOfChildrenAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.assemblage objectAtIndexPath:indexPath];
    return [self.dataSource tableView:tableView cellForObject:object atIndexPath:indexPath];
}

// We could have relay code, but it's of little value.   Forward it along instead.
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [self.dataSource methodSignatureForSelector:aSelector];
    if ( signature ) {
        return signature;
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation invokeWithTarget:self.dataSource];
}

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblageAccess>)assemblage
{
    [self.tableView beginUpdates];
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    if ( [self.class isSectionIndexPath:indexPath] ) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:[indexPath indexAtPosition:0]]
                      withRowAnimation:self.addSectionAnimation];
    }
    else {
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:self.addObjectAnimation];
    }
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    if ( [self.class isSectionIndexPath:indexPath] ) {
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:[indexPath indexAtPosition:0]]
                      withRowAnimation:self.removeSectionAnimation];
    }
    else {
        [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:self.removeObjectAnimation];
    }
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    NSAssert([self.class isSectionIndexPath:indexPath] == NO, @"Do not know what to do for a section update");
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self.dataSource tableView:self.tableView
                    updateCell:cell
                     forObject:object
                   atIndexPath:indexPath];
}

- (void)assemblage:(id<RZAssemblageAccess>)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if ( [self.class isSectionIndexPath:fromIndexPath] ) {
        [self.tableView moveSection:[fromIndexPath indexAtPosition:0]
                          toSection:[toIndexPath indexAtPosition:0]];
    }
    else {
        [self.tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    }
}

- (void)didEndUpdatesForEnsemble:(id<RZAssemblageAccess>)assemblage
{
    [self.tableView endUpdates];
}


@end
