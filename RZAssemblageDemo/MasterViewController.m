//
//  MasterViewController.m
//  RZAssemblageDemo
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "MasterViewController.h"

#import "MutatableAssemblageTableViewController.h"
#import "FilteredAssemblageTableViewController.h"

#import "RZAssemblage.h"
#import "RZAssemblageTableView.h"

@interface MasterViewController () <RZAssemblageTableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) RZAssemblage *assemblage;

@end

@implementation MasterViewController

- (void)loadView
{
    self.view = [[RZAssemblageTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleHeight;
}

- (RZAssemblageTableView *)tableView
{
    return (id)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIViewController *red = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    red.view.backgroundColor = [UIColor redColor];
    red.title = @"Red View Controller";
    UIViewController *blue = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    blue.view.backgroundColor = [UIColor blueColor];
    blue.title = @"Blue View Controller";

    UIViewController *mutable = [[MutatableAssemblageTableViewController alloc] init];
    UIViewController *filtered = [[FilteredAssemblageTableViewController alloc] init];
    RZAssemblage *section1 = [RZAssemblage assemblageForArray:@[red, blue, mutable, filtered]];
    RZAssemblage *section2 = [RZAssemblage assemblageForArray:@[@"String Value A", @"String Value B"]];
    self.assemblage = [RZAssemblage assemblageForArray:@[section1, section2]];

    self.tableView.assemblage = self.assemblage;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell-String"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell-VC"];

    [self.tableView.cellFactory configureCellForClass:[NSString class] reuseIdentifier:@"Cell-String" block:^(UITableViewCell *cell, NSString *object, NSIndexPath *indexPath) {
        cell.textLabel.text = object;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }];
    [self.tableView.cellFactory configureCellForClass:[UIViewController class] reuseIdentifier:@"Cell-VC" block:^(UITableViewCell *cell, UIViewController *object, NSIndexPath *indexPath) {
        cell.textLabel.text = [object title];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }];
}

RZAssemblageTableViewDataSourceIsControllingCells()

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    if ( section == 0 ) {
        return @"View Controllers";
    }
    else {
        return @"Strings";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.tableView.assemblage childAtIndexPath:indexPath];
    if ( [object isKindOfClass:[UIViewController class]] ) {
        [self.navigationController pushViewController:object animated:YES];
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
