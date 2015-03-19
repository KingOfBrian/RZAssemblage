//
//  FilteredAssemblageTableViewController.m
//  RZAssemblage
//
//  Created by Brian King on 2/1/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "FilteredAssemblageTableViewController.h"
#import "RZAssemblageTableView.h"
#import "RZFilteredAssemblage.h"

@interface FilteredAssemblageTableViewController () <RZAssemblageTableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) RZAssemblage *data;
@property (strong, nonatomic) RZAssemblage *assemblage;
@property (strong, nonatomic) RZFilteredAssemblage *filtered;

@property (assign, nonatomic) NSUInteger divisbleBy;

@end

@implementation FilteredAssemblageTableViewController

- (instancetype)init
{
    self = [super initWithNibName:nil bundle:nil];
    if ( self ) {
        self.title = @"Filtered Table View";
        self.divisbleBy = 1;
    }
    return self;
}


- (void)loadView
{
    self.view = [[RZAssemblageTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

- (RZAssemblageTableView *)tableView
{
    return (id)self.view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableArray *oneHundered = [NSMutableArray array];
    for ( NSUInteger i = 0; i < 100; i++ ) {
        [oneHundered addObject:@(i+1)];
    }
    self.data = [[RZAssemblage alloc] initWithArray:oneHundered];
    self.filtered = [[RZFilteredAssemblage alloc] initWithAssemblage:self.data];
    self.assemblage = [[RZAssemblage alloc] initWithArray:@[self.filtered]];

    self.filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *numberString, NSDictionary *bindings) {
        return YES;
    }];

    self.tableView.assemblage = self.assemblage;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView.cellFactory configureCellForClass:[NSNumber class] reuseIdentifier:@"Cell" block:^(UITableViewCell *cell, NSNumber *object, NSIndexPath *indexPath) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ [%@:%@]",
                               object,
                               @([indexPath section]),
                               @([indexPath row])];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }];

    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithTitle:@"C" style:UIBarButtonItemStyleDone target:self action:@selector(clearData)],
                                                [[UIBarButtonItem alloc] initWithTitle:@"A" style:UIBarButtonItemStyleDone target:self action:@selector(addData)],
                                                [[UIBarButtonItem alloc] initWithTitle:@"F" style:UIBarButtonItemStyleDone target:self action:@selector(filterBump)],
                                                ];
}

- (void)clearData
{
    [self.data openBatchUpdate];
    while ( [self.data numberOfChildren] != 0 ) {
        [self.data removeObjectAtIndex:0];
    }
    [self.data closeBatchUpdate];
}

- (void)addData
{
    [self.data openBatchUpdate];
    for ( NSUInteger i = 0; i < 5; i++ ) {
        [self.data addObject:@(i+1)];
    }
    [self.data closeBatchUpdate];
}

- (void)filterBump
{
    self.divisbleBy = self.divisbleBy > 0 && self.divisbleBy < 5 ? self.divisbleBy + 1 : 1;
    self.filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSNumber *num, NSDictionary *bindings) {
        return [num integerValue] % self.divisbleBy == 0;
    }];
    NSLog(@"Showing filters divisible by %@ = %@", @(self.divisbleBy + 1), @([self.assemblage numberOfChildrenAtIndexPath:[NSIndexPath indexPathWithIndex:0]]));
}

@end