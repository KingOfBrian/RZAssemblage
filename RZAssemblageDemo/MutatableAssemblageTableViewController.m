//
//  MutatableAssemblageTableViewController.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "MutatableAssemblageTableViewController.h"
#import "RZMutableAssemblage.h"
#import "RZAssemblageTableViewDataSource.h"

// Use this for a hack
#import "RZAssemblage+Private.h"

@interface MutatableAssemblageTableViewController () <RZAssemblageTableViewDataSourceProxy>

@property (strong, nonatomic) RZMutableAssemblage *assemblage;

@property (strong, nonatomic) RZMutableAssemblage *section;

@property (strong, nonatomic) RZAssemblageTableViewDataSource *dataSource;

@property (assign, nonatomic) NSUInteger index;

@end

@implementation MutatableAssemblageTableViewController

- (instancetype)init
{
    self = [super initWithNibName:nil bundle:nil];
    if ( self ) {
        self.title = @"Mutable Table View";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.assemblage = [[RZMutableAssemblage alloc] initWithArray:@[
                                                                   [[RZMutableAssemblage alloc] initWithArray:@[@"1", @"2", @"3", @"4"]],
                                                                   [[RZMutableAssemblage alloc] initWithArray:@[@"5", @"6"]],
                                                                   ]];
    self.dataSource = [[RZAssemblageTableViewDataSource alloc] initWithAssemblage:self.assemblage
                                                                     forTableView:self.tableView
                                                                   withDataSource:self];

    self.navigationItem.rightBarButtonItems = @[
                                                self.editButtonItem,
                                                [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStyleDone target:self action:@selector(addItemToSection)],
                                                [[UIBarButtonItem alloc] initWithTitle:@"N" style:UIBarButtonItemStyleDone target:self action:@selector(nextSection)],
                                                ];
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
    cell.textLabel.text = object;
    cell.accessoryType = UITableViewCellAccessoryNone;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    return [NSString stringWithFormat:@"Section %@", @(section + 1)];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.assemblage removeObjectAtIndexPath:indexPath];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {

    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.assemblage beginUpdates];
    id object = [self.assemblage objectAtIndexPath:fromIndexPath];
    [self.assemblage insertObject:object atIndexPath:toIndexPath];
    [self.assemblage removeObjectAtIndexPath:fromIndexPath];
    [self.assemblage endUpdates];
}


- (NSString *)nextValue
{
    self.index++;
    return [NSString stringWithFormat:@"Item %@", @(self.index)];
}

- (void)addItemToSection
{
    [self.section beginUpdateAndEndUpdateNextRunloop];
    if ( self.section ) {
        [self.section addObject:[self nextValue]];
    }
    else {
        [self.assemblage addObject:[[RZMutableAssemblage alloc] initWithArray:@[]]];
    }
}

- (void)nextSection
{
    [self.section beginUpdateAndEndUpdateNextRunloop];
    NSArray *store = self.assemblage.store;
    if ( self.section == nil ) {
        self.section = store.firstObject;
    }
    else {
        NSUInteger index = [self.assemblage indexForObject:self.section] + 1;
        if ( index == store.count ) {
            self.section = nil;
        }
        else {
            self.section = [self.assemblage objectAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
        }
    }
}

@end
