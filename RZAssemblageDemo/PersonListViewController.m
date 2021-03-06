//
//  PersonListViewController.m
//  RZTree
//
//  Created by Brian King on 3/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "PersonListViewController.h"
#import "AppDelegate.h"
#import "PersonViewController.h"

@import RZAssemblage;
@import RZAssemblageUIKit;
// @import RZAssemblageTestData fails... Why?!
#import "RZAssemblageTestData.h"


@interface PersonListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) RZTree *data;

@end

@implementation PersonListViewController

- (instancetype)init
{
    self = [super initWithNibName:nil bundle:nil];
    if ( self ) {
        self.title = @"RZSocial Network";
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
    // This assemblage is a normal FRC with sections.
    NSFetchedResultsController *frc = [[RZAssemblageTestData shared] frcForPersonsByTeam];
    RZTree *content = [RZTree nodeForFetchedResultsController:frc];
    NSError *error = nil;
    [frc performFetch:&error];
    NSAssert(error == nil, @"");
    self.data = content;
    self.tableView.tree = self.data;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView.cellFactory configureCellForClass:[Person class] reuseIdentifier:@"Cell" block:^(UITableViewCell *cell, Person *person, NSIndexPath *indexPath) {
        cell.textLabel.text = [person.firstName stringByAppendingFormat:@" %@", person.lastName];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }];
}

RZAssemblageTableViewDataSourceIsControllingCells()

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    Team *t = [self.data objectAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
    return t.name;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person *p = [self.data objectAtIndexPath:indexPath];
    PersonViewController *pvc = [[PersonViewController alloc] initWithPerson:p];
    [self.navigationController pushViewController:pvc animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
