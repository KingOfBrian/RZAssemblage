//
//  PersonViewController.m
//  RZAssemblage
//
//  Created by Brian King on 3/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "PersonViewController.h"

@import RZAssemblage;
#import "RZAssemblageTestData.h"

@interface PersonViewController () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) Person *person;
@property (strong, nonatomic) RZAssemblage *assemblage;

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
    NSFetchedResultsController *frc = [self fetchedResultsController];
    RZAssemblage *friends = [RZAssemblage assemblageForFetchedResultsController:frc];
    NSError *error = nil;
    [frc performFetch:&error];
    NSAssert(error == nil, @"");

    // Create a proxy assemblage for enemies. Same result as above, but slightly easier. Note that you can remove enemies, since this assemblage is mutable.
    RZAssemblage *enemies = [RZAssemblage assemblageTreeWithObject:self.person arrayKeypaths:@[@"enemiesByFirstName"]];

    // Create a leaf assemblage for some attributes we want to display
    NSArray *keypaths = @[@"team.name", @"firstName", @"lastName"];
    RZAssemblage *info = [RZAssemblage assemblageWithObject:self.person leafKeypaths:keypaths];

    self.assemblage = [RZAssemblage assemblageForArray:@[info, friends, enemies]];
    self.tableView.assemblage = self.assemblage;
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
    Person *p = [self.assemblage objectAtIndexPath:indexPath];
    if ( [p isKindOfClass:[Person class]] ) {
        PersonViewController *pvc = [[PersonViewController alloc] initWithPerson:p];
        [self.navigationController pushViewController:pvc animated:YES];
    }
    else {
        NSString *title = [@"Edit " stringByAppendingString:[self typeForIndexPath:indexPath]];
        UIAlertView *editAlert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        editAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [editAlert textFieldAtIndex:0].text = [self.assemblage objectAtIndexPath:indexPath];
        editAlert.tag = [indexPath indexAtPosition:indexPath.length - 1];
        [editAlert show];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ( buttonIndex != alertView.cancelButtonIndex ) {
        NSString *name = [alertView textFieldAtIndex:0].text;
        NSMutableArray *a = [[self.assemblage assemblageAtIndexPath:[NSIndexPath indexPathWithIndex:0]] mutableChildren];
        [a replaceObjectAtIndex:alertView.tag withObject:name];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *sectionIndexPath = [NSIndexPath indexPathWithIndex:[indexPath indexAtPosition:0]];
    return [[self.assemblage assemblageAtIndexPath:sectionIndexPath] mutableChildren] != nil;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editingStyle == UITableViewCellEditingStyleDelete ) {
        [self.assemblage removeObjectAtIndexPath:indexPath];
    }
}

- (NSFetchedResultsController *)fetchedResultsController
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"self in %@", self.person.friends];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[self.person managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
    return fetchedResultsController;
}

@end
