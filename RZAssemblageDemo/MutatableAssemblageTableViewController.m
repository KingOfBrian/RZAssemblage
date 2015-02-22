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
#import "RZAssemblageTableViewDataSource.h"
#import "RZJoinAssemblage.h"
#import "RZFilteredAssemblage.h"

@interface MutatableAssemblageTableViewController () <RZAssemblageTableViewDataSourceProxy>

@property (strong, nonatomic) RZAssemblage *assemblage;

@property (strong, nonatomic) RZAssemblageTableViewDataSource *dataSource;

@property (assign, nonatomic) NSUInteger index;
@property (strong, nonatomic) NSArray *mutableAssemblages;
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
    RZAssemblage *m1 = [[RZAssemblage alloc] initWithArray:@[@"1", @"2", @"3", @"4"]];
    RZAssemblage *m2 = [[RZAssemblage alloc] initWithArray:@[@"4", @"5", @"6", ]];
    RZAssemblage *m3 = [[RZAssemblage alloc] initWithArray:@[@"7", @"8", @"9", ]];
    RZAssemblage *m4 = [[RZAssemblage alloc] initWithArray:@[@"10", @"11", @"12", ]];
    self.index = 12;
    self.mutableAssemblages = @[m1, m2, m3, m4];

    RZJoinAssemblage *f1 = [[RZJoinAssemblage alloc] initWithArray:@[m3, m4]];
    RZFilteredAssemblage *filtered = [[RZFilteredAssemblage alloc] initWithAssemblage:f1];
    filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *numberString, NSDictionary *bindings) {
        return [numberString integerValue] % 2;
    }];
    self.assemblage = [[RZAssemblage alloc] initWithArray:@[m1, m2, filtered]];

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
    return [NSString stringWithFormat:@"%@", @(self.index)];
}

- (NSUInteger)randomSectionIndex
{
    return [self randomIndexForAssemblage:self.assemblage];
}

- (NSUInteger)randomIndexForAssemblage:(RZAssemblage *)assemblage
{
    NSUInteger count = [assemblage numberOfChildren];
    return count == 0 ? NSNotFound : arc4random() % count;
}

- (NSIndexPath *)randomExistingIndexPath
{
    NSIndexPath *indexPath = nil;
    // Find an indexPath.  If the section we point to has no items, pick another section.
    while ( indexPath == nil ) {
        NSUInteger section = [self randomSectionIndex];
        RZAssemblage *assemblage = [self.assemblage objectAtIndex:section];
        NSUInteger row = [self randomIndexForAssemblage:assemblage];
        indexPath = row == NSNotFound ? nil : [NSIndexPath indexPathForRow:row inSection:section];
    }

    return indexPath;
}

- (void)move
{
    NSIndexPath *fromIndexPath = [self randomExistingIndexPath];

    [self.assemblage moveObjectAtIndexPath:fromIndexPath
                               toIndexPath:[self randomExistingIndexPath]];
}

- (void)testHowDoesItWorkMove
{
    // This move actually works, but a move from 0:1 -> 0:1 doesn't appear like it should work.
    RZAssemblage *m1 = self.mutableAssemblages[0];
    [m1 openBatchUpdate];
    [m1 removeObjectAtIndex:0];
    [m1 removeObjectAtIndex:0];
    [m1 addObject:@"2"];
    [m1 removeObjectAtIndex:0];
    [m1 closeBatchUpdate];
}

- (void)addRow
{
    NSUInteger section = [self randomSectionIndex];
    RZAssemblage *assemblage = [self.mutableAssemblages objectAtIndex:section];
    [assemblage addObject:[self nextValue]];
}

- (void)removeRow
{
    NSUInteger section = [self randomSectionIndex];
    RZAssemblage *assemblage = [self.mutableAssemblages objectAtIndex:section];
    NSUInteger row = [self randomIndexForAssemblage:assemblage];
    if ( row != NSNotFound ) {
        [assemblage openBatchUpdate];
        [assemblage removeObjectAtIndex:row];
        [assemblage closeBatchUpdate];
    }
}

- (void)random
{
    NSArray *actions = @[
//                         [NSValue valueWithPointer:@selector(testHowDoesItWorkMove)],
                         [NSValue valueWithPointer:@selector(move)],
                         [NSValue valueWithPointer:@selector(addRow)],
                         [NSValue valueWithPointer:@selector(removeRow)],
                         ];

    NSUInteger index = arc4random() % actions.count;
    NSValue *boxedSelector = actions[index];
    SEL selector = [boxedSelector pointerValue];
    NSLog(@"@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
    SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING([self performSelector:selector]);
}

- (void)clear
{
    [self.assemblage openBatchUpdate];
    for ( RZAssemblage *assemblage in self.mutableAssemblages ) {
        while ( [assemblage numberOfChildren] > 2 ) {
            [assemblage removeLastObject];
        }
        while ( [assemblage numberOfChildren] < 2 ) {
            [assemblage addObject:[self nextValue]];
        }
    }
    [self.assemblage closeBatchUpdate];
}

@end
