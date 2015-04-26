//
//  MutatableAssemblageTableViewController.m
//  RZTree
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

@import RZAssemblage;
@import RZAssemblageUIKit;

@interface MutatableAssemblageTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) RZTree *data;

@property (assign, nonatomic) NSUInteger index;
@property (strong, nonatomic) NSArray *mutableNodes;

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

- (void)loadView
{
    self.view = [[RZAssemblageTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

- (RZAssemblageTableView *)tableView
{
    return (id)self.view;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    RZTree *m1 = [RZTree nodeWithChildren:@[@"1", @"2", @"3", @"4"]];
    RZTree *m2 = [RZTree nodeWithChildren:@[@"4", @"5", @"6",]];
    RZTree *m3 = [RZTree nodeWithChildren:@[@"7", @"8", @"9",]];
    RZTree *m4 = [RZTree nodeWithChildren:@[@"10", @"11", @"12",]];
    self.index = 12;
    self.mutableNodes = @[m1, m2, m3, m4];

    RZTree *f1 = [RZTree nodeWithJoinedNodes:@[m3, m4]];

    RZTree<RZFilterableTree> *filtered = [RZTree filterableNodeWithNode:f1];
    filtered.filter = [NSPredicate predicateWithBlock:^BOOL(NSString *numberString, NSDictionary *bindings) {
        return [numberString integerValue] % 2;
    }];
    self.data = [RZTree nodeWithChildren:@[m1, m2, filtered]];

    self.tableView.tree = self.data;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    [self.tableView.cellFactory configureCellForClass:[NSString class] reuseIdentifier:@"Cell" block:^(UITableViewCell *cell, NSString *object, NSIndexPath *indexPath) {
        cell.textLabel.text = object;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }];
    self.navigationItem.rightBarButtonItems = @[
                                                self.editButtonItem,
                                                [[UIBarButtonItem alloc] initWithTitle:@"R" style:UIBarButtonItemStyleDone target:self action:@selector(random)],
                                                [[UIBarButtonItem alloc] initWithTitle:@"C" style:UIBarButtonItemStyleDone target:self action:@selector(clear)],
                                                ];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
}

RZAssemblageTableViewDataSourceIsControllingCells()

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
        [self.data removeObjectAtIndexPath:indexPath];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {

    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    // Pause the delegate during the move, as the views have already moved.   The data just needs to be kept in sync.
    self.tableView.ignoreAssemblageChanges = YES;
    [self.data moveObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    self.tableView.ignoreAssemblageChanges = NO;
}

- (NSString *)nextValue
{
    self.index++;
    return [NSString stringWithFormat:@"%@", @(self.index)];
}

- (NSUInteger)randomPopulatedIndexForArray:(NSArray *)array
{
    return [array count] == 0 ? NSNotFound : arc4random() % [array count];
}

- (NSMutableArray *)randomSection
{
    NSUInteger index = arc4random() % [[self.data children] count];
    return [self.data[index] mutableChildren];
}

- (NSIndexPath *)randomExistingIndexPath
{
    NSMutableArray *sections = [self.data mutableChildren];

    NSIndexPath *indexPath = nil;
    // Find an indexPath.  If the section we point to has no items, pick another section.
    while ( indexPath == nil ) {
        NSUInteger randomSectionIndex = [self randomPopulatedIndexForArray:sections];
        if ( randomSectionIndex != NSNotFound ) {
            NSMutableArray *section = [self.data[randomSectionIndex] mutableChildren];
            NSUInteger row = [self randomPopulatedIndexForArray:section];
            indexPath = row == NSNotFound ? nil : [NSIndexPath indexPathForRow:row inSection:randomSectionIndex];
        }

    }

    return indexPath;
}

- (void)move
{
    NSIndexPath *fromIndexPath = [self randomExistingIndexPath];
    NSIndexPath *toIndexPath = [self randomExistingIndexPath];
    [self.data moveObjectAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

- (void)testHowDoesItWorkMove
{
    // This move actually works, but a move from 0:1 -> 0:1 doesn't appear like it should work.
    NSMutableArray *m1 = [self.mutableNodes[0] mutableChildren];
    [self.mutableNodes[0] openBatchUpdate];
    [m1 removeObjectAtIndex:0];
    [m1 removeObjectAtIndex:0];
    [m1 addObject:@"2"];
    [m1 removeObjectAtIndex:0];
    [self.mutableNodes[0] closeBatchUpdate];
}

- (void)addRow
{
    [[self randomSection] addObject:[self nextValue]];
}

- (void)removeRow
{
    NSIndexPath *indexPath = [self randomExistingIndexPath];
    [self.data removeObjectAtIndexPath:indexPath];
}

- (void)random
{
    NSArray *actions = @[
//                         [NSValue valueWithPointer:@selector(testHowDoesItWorkMove)],
                         [NSValue valueWithPointer:@selector(move)],
                         [NSValue valueWithPointer:@selector(addRow)],
                         [NSValue valueWithPointer:@selector(addRow)],
                         [NSValue valueWithPointer:@selector(addRow)],
                         [NSValue valueWithPointer:@selector(addRow)],
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
    [self.data openBatchUpdate];
    for ( RZTree *node in self.mutableNodes ) {
        NSMutableArray *proxy = [node mutableChildren];
        while ( [proxy count] > 2 ) {
            [proxy removeLastObject];
        }
        while ( [proxy count] < 2 ) {
            [proxy addObject:[self nextValue]];
        }
    }
    [self.data closeBatchUpdate];
}

@end
