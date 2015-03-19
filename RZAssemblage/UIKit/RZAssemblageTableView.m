//
//  RZAssemblageTableView.m
//  RZAssemblage
//
//  Created by Brian King on 3/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageTableView.h"

@interface RZAssemblageTableView ()

@property (strong, nonatomic, readonly) RZAssemblageTableViewDataSource *internalDataSource;

@end

@implementation RZAssemblageTableView

@synthesize cellFactory = _cellFactory;
@synthesize internalDataSource = _internalDataSource;

- (void)setAssemblage:(id<RZAssemblage>)assemblage
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

- (RZTableViewCellFactory *)cellFactory
{
    if ( _cellFactory == nil ) {
        _cellFactory = [[RZTableViewCellFactory alloc] init];
    }
    return _cellFactory;
}

- (void)setDataSource:(id<RZAssemblageTableViewDataSource>)dataSource
{
    if ( _internalDataSource ) {
        _internalDataSource.dataSource = dataSource;
    }
    else {
        [super setDataSource:dataSource];
    }
}

- (BOOL)ignoreAssemblageChanges
{
    return self.assemblage.delegate == nil;
}

- (void)setIgnoreAssemblageChanges:(BOOL)ignoreAssemblageChanges
{
    self.assemblage.delegate = ignoreAssemblageChanges ? nil : self.internalDataSource;
}

@end
