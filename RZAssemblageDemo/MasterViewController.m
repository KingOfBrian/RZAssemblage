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
#import "RZAssemblageTableViewDataSource.h"

@interface MasterViewController () <RZAssemblageTableViewDataSourceProxy>

@property (strong, nonatomic) RZAssemblage *assemblage;
@property (strong, nonatomic) RZAssemblageTableViewDataSource *dataSource;
@end

@implementation MasterViewController

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
    self.assemblage = [[RZAssemblage alloc] initWithArray:@[
                                                            [[RZAssemblage alloc] initWithArray:@[red, blue, mutable, filtered]],
                                                            [[RZAssemblage alloc] initWithArray:@[@"String Value A", @"String Value B"]],
                                                            ]];
    self.dataSource = [[RZAssemblageTableViewDataSource alloc] initWithAssemblage:self.assemblage
                                                                     forTableView:self.tableView
                                                                   withDataSource:self];
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
    if ( [object isKindOfClass:[UIViewController class]] ) {
        cell.textLabel.text = [(UIViewController *)object title];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.textLabel.text = object;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

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
    id object = [self.assemblage objectAtIndexPath:indexPath];
    if ( [object isKindOfClass:[UIViewController class]] ) {
        [self.navigationController pushViewController:object animated:YES];
    }
    else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
