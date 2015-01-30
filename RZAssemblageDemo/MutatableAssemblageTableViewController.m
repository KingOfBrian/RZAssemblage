//
//  MutatableAssemblageTableViewController.m
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#define SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING(code)                        \
_Pragma("clang diagnostic push")                                        \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"")     \
code;                                                                   \
_Pragma("clang diagnostic pop")                                         \

#import "MutatableAssemblageTableViewController.h"
#import "RZMutableAssemblage.h"
#import "RZAssemblageTableViewDataSource.h"

@interface MutatableAssemblageTableViewController () <RZAssemblageTableViewDataSourceProxy>

@property (strong, nonatomic) RZMutableAssemblage *assemblage;

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
                                                                   [[RZMutableAssemblage alloc] initWithArray:@[@"1", @"2", @"3", ]],
                                                                   [[RZMutableAssemblage alloc] initWithArray:@[@"4", @"5", @"6", ]],
                                                                   [[RZMutableAssemblage alloc] initWithArray:@[@"7", @"8", @"9", ]],
                                                                   ]];
    self.dataSource = [[RZAssemblageTableViewDataSource alloc] initWithAssemblage:self.assemblage
                                                                     forTableView:self.tableView
                                                                   withDataSource:self];

    self.navigationItem.rightBarButtonItems = @[
                                                self.editButtonItem,
                                                [[UIBarButtonItem alloc] initWithTitle:@"R" style:UIBarButtonItemStyleDone target:self action:@selector(random)],
                                                [[UIBarButtonItem alloc] initWithTitle:@"C" style:UIBarButtonItemStyleDone target:self action:@selector(clear)],
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
    // Pause the delegate during the move, as the views have already moved.   The data just needs to be kept in sync.
    self.assemblage.delegate = nil;
    [self.assemblage moveObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    self.assemblage.delegate = self.dataSource;
}

- (NSString *)nextValue
{
    self.index++;
    return [NSString stringWithFormat:@"Item %@", @(self.index)];
}

- (NSUInteger)randomSectionIndex
{
    return [self randomIndexForAssemblage:self.assemblage];
}

- (NSUInteger)randomIndexForAssemblage:(RZAssemblage *)assemblage
{
    NSUInteger count = [assemblage numberOfChildrenAtIndexPath:nil];
    return arc4random() % count;
}

- (NSIndexPath *)randomExistingIndexPath
{
    NSUInteger section = [self randomSectionIndex];
    RZAssemblage *assemblage = [self.assemblage objectAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
    NSUInteger row = [self randomIndexForAssemblage:assemblage];
    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (void)move
{
    [self.assemblage moveObjectAtIndexPath:[self randomExistingIndexPath]
                               toIndexPath:[self randomExistingIndexPath]];
}

- (void)addRow
{
    NSUInteger section = [self randomSectionIndex];
    RZMutableAssemblage *assemblage = [self.assemblage objectAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
    [assemblage addObject:[self nextValue]];
}

- (void)removeRow
{
    NSUInteger section = [self randomSectionIndex];
    RZMutableAssemblage *assemblage = [self.assemblage objectAtIndexPath:[NSIndexPath indexPathWithIndex:section]];
    NSUInteger row = [self randomIndexForAssemblage:assemblage];
    [assemblage beginUpdates];
    [assemblage removeObjectAtIndex:row];
    if ( [assemblage numberOfChildren] == 0 ) {
        [self.assemblage removeObjectAtIndex:section];
    }
    [assemblage endUpdates];
}

- (void)random
{
    NSArray *actions = @[
                         [NSValue valueWithPointer:@selector(move)],
                         [NSValue valueWithPointer:@selector(move)],
                         [NSValue valueWithPointer:@selector(addRow)],
                         [NSValue valueWithPointer:@selector(addRow)],
                         [NSValue valueWithPointer:@selector(addRow)],
                         [NSValue valueWithPointer:@selector(removeRow)], // Weight remove less
                         ];

    NSUInteger index = arc4random() % actions.count;
    NSValue *boxedSelector = actions[index];
    SEL selector = [boxedSelector pointerValue];

    SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING([self performSelector:selector]);
}

- (void)clear
{
    [self.assemblage beginUpdates];
    for ( NSUInteger i = 0; i < [self.assemblage numberOfChildren]; i++ ) {
        RZMutableAssemblage *assemblage = [self.assemblage objectAtIndex:i];
        while ( [assemblage numberOfChildren] > 2 ) {
            [assemblage removeLastObject];
        }
    }
    [self.assemblage endUpdates];
}

@end
