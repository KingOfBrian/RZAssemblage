//
//  RZAssemblageTableView.m
//  RZAssemblage
//
//  Created by Brian King on 3/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageTableView.h"
#import "RZAssemblageTableViewDataSource.h"
#import "RZAssemblageTableViewCellFactory.h"
#import "RZAssemblage.h"

@interface RZAssemblageTableView ()

@property (strong, nonatomic, readonly) RZAssemblageTableViewDataSource *internalDataSource;

@end

@implementation RZAssemblageTableView

@synthesize cellFactory = _cellFactory;
@synthesize internalDataSource = _internalDataSource;

- (void)setAssemblage:(RZAssemblage *)assemblage
{
    _assemblage = assemblage;

    if ( _assemblage ) {
        _internalDataSource = [[RZAssemblageTableViewDataSource alloc] initWithAssemblage:_assemblage
                                                                             forTableView:self
                                                                              cellFactory:self.cellFactory];
        _internalDataSource.dataSource = (id)super.dataSource;
        super.dataSource = _internalDataSource;
    }
    else if ( _internalDataSource ) {
        super.dataSource = _internalDataSource.dataSource;
        _internalDataSource = nil;
    }
}

- (RZAssemblageTableViewCellFactory *)cellFactory
{
    if ( _cellFactory == nil ) {
        _cellFactory = [[RZAssemblageTableViewCellFactory alloc] init];
    }
    return _cellFactory;
}

- (void)setDataSource:(id<UITableViewDataSource>)dataSource
{
    if ( _internalDataSource ) {
        _internalDataSource.dataSource = dataSource;
    }
    else {
        [super setDataSource:dataSource];
    }
}

- (void)setIgnoreAssemblageChanges:(BOOL)ignoreAssemblageChanges
{
    _ignoreAssemblageChanges = ignoreAssemblageChanges;
    if ( ignoreAssemblageChanges ) {
        [self.assemblage removeObserver:(id)self.internalDataSource];
    }
    else {
        [self.assemblage addObserver:(id)self.internalDataSource];
    }
}

@end
