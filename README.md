# RZArborist - Composable UIKit Data Sources
RZArborist simplifies the creation of UI data sources by composing data into simple, observable trees which are connected to a UITableView or UICollectionView. It enables NSFetchedResultControllerDelegate style observation on regular array properties and further simplifies data source creation to eliminate the usual boring and error prone data source implementations.

What does that mean for you?

*Have a sectioned NSFetchedResultsController that needs some static headers?*
```obj-c
RZTree *friends  = [RZTree nodeBackedByFetchedResultsController:friendListFRC];
RZTree *staticData = [RZTree treeWithChildren:@[@"Row 1", @"Row 2"]];
RZTree *data = [RZTree nodeWithJoinedNodes:@[staticData, friends]];
```

*Want to build a data source from 2 array properties?*
```obj-c
RZTree *friends = [RZTree nodeWithObject:self.person descendingKeypaths:@[@"friends"]];
RZTree *enemies = [RZTree nodeWithObject:self.person descendingKeypaths:@[@"enemies"]];
RZTree *data = [RZTree nodeWithChildren:@[friends, enemies]];
```

*Want the UITableView delegate method that moves an object from section 1 to 2 to actually work?*
```obj-c
[data moveObjectAtIndexPath:fromFriends toIndexPath:toEnemies];
```

*Want a section that reflects a few properties?*
```obj-c
NSArray *keypaths = @[@"team.name", @"firstName", @"lastName"];
RZTree *section = [RZTree nodeWithObject:self.person leafKeypaths:keypaths];
```

*Want to filter static data?*
```obj-c
RZTree<RZFilterableTree> *filtered = [data filterableNodeWithNode:data];
filtered.filter = [NSPredicate predicateWithFormat:@"..."];
```

*Want to do lots of integer and NSIndexPath comparison?*
```obj-c
// No you don't.
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
RZTree conceptually originated from RZCollectionList. The RZCollectionList API was a bit confusing, especially around names (RZCollectionListCollectionViewDataSourceDelegate!), and sections. The name RZArborist was chosen to emphasize it's key like nature, after a more confusing name of RZAssemblage.


