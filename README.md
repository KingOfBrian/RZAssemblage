# RZArborist - Composable UIKit Data Sources
RZArborist (Formerly RZAssemblage) simplifies the creation of UI data sources by composing data into observable trees, of sections and rows, which are connected to a UITableView or UICollectionView. It enables NSFetchedResultControllerDelegate style observation on regular array properties and further simplifies data source creation to eliminate the usual boring and error prone data source implementations.

What does that mean for you?

## Section based on two arrays
Below will create a 2 section tree, based off of two array properties. Using KVO, these arrays will generate change notifications similar to NSFetchedResultsController

```obj-c
RZTree *friends = [RZTree nodeWithObject:self.person descendingKeypaths:@[@"friends"]];
RZTree *enemies = [RZTree nodeWithObject:self.person descendingKeypaths:@[@"enemies"]];
RZTree *data = [RZTree nodeWithChildren:@[friends, enemies]];
```

## Place Holder Sections
The design of an application can require static data to be placed on top of a neatly-sectioned NSFetchedResultsController. A Join node allows your sections to be easily offset.

```obj-c
RZTree *friends  = [RZTree nodeBackedByFetchedResultsController:friendListFRC];
RZTree *staticData = [RZTree nodeWithChildren:@[@"Row 1", @"Row 2"]];
RZTree *data = [RZTree nodeWithJoinedNodes:@[staticData, friends]];
```

## Filter 
Add predicate based filtering to any of these trees, with an RZFilterableTree.

```obj-c
RZTree<RZFilterableTree> *filtered = [data filterableNodeWithNode:data];
filtered.filter = [NSPredicate predicateWithFormat:@"..."];
```

## IndexPath mutation
It is easy to respond to mutation requests from the delegate with tree mutations. These will mutate all nodes that support mutation -- all except NSFetchedResultsController backed nodes.

```obj-c
[data moveObjectAtIndexPath:fromFriendsIndexPath toIndexPath:toEnemiesIndexPath];
[data removeObjectAtIndexPath:deleteIndexPath];
[data insertObject:@"Placeholder" atIndexPath:insertIndexPath];
```

All of the above mutations will result in proper animations on the backing view.

## Simple Cell Factory
With uniform data lookup, cell creation is easy.

```obj-c
- (void)viewDidLoad 
{
    [self.cellFactory configureCellForClass:[Person class] reuseIdentifier:@"Cell" block:^(UITableViewCell *cell, Person *person, NSIndexPath *indexPath) {
        cell.imageView.image = person.avatar;
        cell.textLabel.text = person.firstName;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.data objectAtIndexPath:indexPath];
    if ( [object isKindOfClass:[Person class]] ) {
    ...
```

## Cocoa Integration
RZTree's can be built from a number of native Cocoa sources, like an array, a Key Value Coding compliant array property, or an NSFetchedResultsController. There are also a few 'transform' nodes that just transform indexes, and do not represent data. Both `[RZTree nodeWithJoinedNodes:@[]]` and `[RZTree filterableNodeWithNode:node]` are examples of this. To simplify integration further, every RZTree has a `children` and `mutableChildren` property that will return a proxy array that will access or mutate the tree through a more familiar array interface.

## Update Notification
Update notifications can occur from any object in the RZTree. For an object to notify change events, the object must implement `+ (NSSet *)keyPathsForValuesAffectingRZTreeUpdateKey` and return the keypaths that should trigger an update. Core Data Objects using NSFetchedResultsController do not need to implement this method.


## UIKit
RZTree provides a cell factory and a data source for both UITableView and UICollectionView. The cell factory provides blocks to bind objects to cells, and the data source loads data from the tree, and monitors changes to the tree for updating.

### UITableView

Due to the API design of UITableView, and how both the delegate and dataSource properties provide views, there's a UITableView subclass to simplify binding. It will internally intercept both the delegate and dataSource API's and respond to API methods that provide views, and relay all other messages back to the delegate and dataSource properties that are externally configured. This subclass is not required to use RZTree, but simplifies wiring things up.

## History
RZTree conceptually originated from RZCollectionList. The name RZArborist was chosen to emphasize it's tree like nature, after a more confusing name of RZAssemblage.


