//
//  PersonListViewController.m
//  RZAssemblage
//
//  Created by Brian King on 3/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "PersonListViewController.h"
#import "AppDelegate.h"
#import "PersonViewController.h"

#import "RZAssemblage.h"
#import "RZFRCAssemblage.h"
#import "RZAssemblageTableView.h"
#import "RZAssemblageTableViewDataSource.h"
#import "Person.h"
#import "Team.h"

@interface PersonListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) RZAssemblage *assemblage;

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
    RZFRCAssemblage *content = [[RZFRCAssemblage alloc] initWithFetchedResultsController:[self fetchedResultsController]];
    NSError *error = nil;
    [content load:&error];
    NSAssert(error == nil, @"");
    self.assemblage = content;
    self.tableView.assemblage = self.assemblage;
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
    Team *t = [self.assemblage childAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
    return t.name;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person *p = [self.assemblage childAtIndexPath:indexPath];
    PersonViewController *pvc = [[PersonViewController alloc] initWithPerson:p];
    [self.navigationController pushViewController:pvc animated:YES];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return [(AppDelegate *)[UIApplication sharedApplication].delegate managedObjectContext];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"team.name" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[self managedObjectContext] sectionNameKeyPath:@"team.name" cacheName:nil];
    return fetchedResultsController;
}

@end
