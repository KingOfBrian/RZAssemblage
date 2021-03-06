//
//  PersonViewController.m
//  RZTree
//
//  Created by Brian King on 3/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "PersonViewController.h"

@import RZAssemblage;
@import RZAssemblageUIKit;
#import "RZAssemblageTestData.h"

@interface PersonViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) Person *person;
@property (strong, nonatomic) RZTree *data;

@end

@implementation PersonViewController

- (instancetype)initWithPerson:(Person *)person
{
    self = [super initWithNibName:nil bundle:nil];
    if ( self ) {
        self.person = person;
        self.title = person.firstName;
    }
    return self;
}

- (void)loadView
{
    self.view = [[RZAssemblageTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
}

- (RZAssemblageTableView *)tableView
{
    return (id)self.view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Create a flat FRC on person with a predicate that restricts the results to friends of this person
    NSFetchedResultsController *frc = [[RZAssemblageTestData shared] frcForFriendsOfPerson:self.person];
    RZTree *friends = [RZTree nodeForFetchedResultsController:frc];
    NSError *error = nil;
    [frc performFetch:&error];
    NSAssert(error == nil, @"");

    // Create a proxy assemblage for enemies. Same result as above, but slightly easier. Note that you can remove enemies, since this assemblage is mutable.
    RZTree *enemies = [RZTree nodeWithObject:self.person descendingKeypaths:@[@"enemiesByFirstName"]];

    // Create a leaf assemblage for some attributes we want to display
    NSArray *keypaths = @[@"team.name", @"firstName", @"lastName"];
    RZTree *info = [RZTree nodeWithObject:self.person leafKeypaths:keypaths];

    self.data = [RZTree nodeWithChildren:@[info, friends, enemies]];
    self.tableView.tree = self.data;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell-Person"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell-String"];
    [self.tableView.cellFactory configureCellForClass:[Person class] reuseIdentifier:@"Cell-Person" block:^(UITableViewCell *cell, Person *person, NSIndexPath *indexPath) {
        cell.textLabel.text = [person.firstName stringByAppendingFormat:@" %@", person.lastName];
    }];
    [self.tableView.cellFactory configureCellForClass:[NSString class] reuseIdentifier:@"Cell-String" block:^(UITableViewCell *cell, NSString *value, NSIndexPath *indexPath) {
        cell.textLabel.text = [[self typeForIndexPath:indexPath] stringByAppendingFormat:@": %@", value];
    }];
}

- (NSString *)typeForIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.row == 0 ) {
        return @"Team";
    }
    else if ( indexPath.row == 1 ) {
        return @"First Name";
    }
    else {
        return @"Last Name";
    }
}

RZAssemblageTableViewDataSourceIsControllingCells()

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ( section == 0 ) {
        return @"Information";
    }
    else if ( section == 1 ) {
        return @"Friends";
    }
    else if ( section == 2 ) {
        return @"Enemies";
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ( section == 0 ) {
        return @"Click row above to edit";
    }
    else if ( section == 1 ) {
        return @"Swipe to delete does not work in section above (NSFRC backed)";
    }
    else if ( section == 2 ) {
        return @"Swipe to delete does work in section above (KVC observed)";
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.data objectAtIndexPath:indexPath];
    if ( [object isKindOfClass:[Person class]] ) {
        PersonViewController *pvc = [[PersonViewController alloc] initWithPerson:object];
        [self.navigationController pushViewController:pvc animated:YES];
    }
    else {
        NSString *title = [@"Edit " stringByAppendingString:[self typeForIndexPath:indexPath]];
        UIAlertView *editAlert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        editAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [editAlert textFieldAtIndex:0].text = [self.data objectAtIndexPath:indexPath];
        editAlert.tag = [indexPath indexAtPosition:indexPath.length - 1];
        [editAlert show];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ( buttonIndex != alertView.cancelButtonIndex ) {
        NSString *name = [alertView textFieldAtIndex:0].text;
        NSMutableArray *a = [[self.data nodeAtIndexPath:[NSIndexPath indexPathWithIndex:0]] mutableChildren];
        [a replaceObjectAtIndex:alertView.tag withObject:name];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:[indexPath indexAtPosition:0]];
    return [[self.data nodeAtIndexPath:sectionIndexPath] mutableChildren] != nil;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editingStyle == UITableViewCellEditingStyleDelete ) {
        [self.data removeObjectAtIndexPath:indexPath];
    }
}


@end
