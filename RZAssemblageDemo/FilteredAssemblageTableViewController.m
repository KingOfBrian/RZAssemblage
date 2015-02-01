//
//  FilteredAssemblageTableViewController.m
//  RZAssemblage
//
//  Created by Brian King on 2/1/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "FilteredAssemblageTableViewController.h"
#import "RZMutableAssemblage.h"
#import "RZAssemblageTableViewDataSource.h"
#import "RZFilteredAssemblage.h"

@interface FilteredAssemblageTableViewController () <RZAssemblageTableViewDataSourceProxy>

@property (strong, nonatomic) RZAssemblage *assemblage;
@property (strong, nonatomic) RZFilteredAssemblage *filtered;

@property (strong, nonatomic) RZAssemblageTableViewDataSource *dataSource;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    NSMutableArray *oneHundered = [NSMutableArray array];
    for ( NSUInteger i = 0; i < 100; i++ ) {
        [oneHundered addObject:[NSString stringWithFormat:@"%@", @(i+1)]];
    }
    RZAssemblage *a1 = [[RZAssemblage alloc] initWithArray:oneHundered];
    self.filtered = [[RZFilteredAssemblage alloc] initWithAssemblage:a1];
    self.assemblage = [[RZAssemblage alloc] initWithArray:@[self.filtered]];

    self.filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *numberString, NSDictionary *bindings) {
        return YES;
    }];

    self.dataSource = [[RZAssemblageTableViewDataSource alloc] initWithAssemblage:self.assemblage
                                                                     forTableView:self.tableView
                                                                   withDataSource:self];

    self.navigationItem.rightBarButtonItems = @[
                                                [[UIBarButtonItem alloc] initWithTitle:@"F" style:UIBarButtonItemStyleDone target:self action:@selector(filterBump)],
                                                ];
}

- (void)filterBump
{
    self.divisbleBy = self.divisbleBy > 0 && self.divisbleBy < 5 ? self.divisbleBy + 1 : 1;
    self.filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSNumber *num, NSDictionary *bindings) {
        return [num integerValue] % self.divisbleBy == 0;
    }];
    NSLog(@"Showing filters divisible by %@ = %@", @(self.divisbleBy + 1), @([self.assemblage numberOfChildrenAtIndexPath:[NSIndexPath indexPathWithIndex:0]]));
}

- (UITableViewCell*)tableView:(UITableView *)tableView
cellForObject:(id)object
atIndexPath:(NSIndexPath*)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView
updateCell:(UITableViewCell*)cell
forObject:(id)object
atIndexPath:(NSIndexPath*)indexPath
{
    cell.textLabel.text = [NSString stringWithFormat:@"%@ [%@:%@]",
                           object,
                           @([indexPath section]),
                           @([indexPath row])];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

@end