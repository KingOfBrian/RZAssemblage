# RZTree - Composable Data Sources
RZTree allows composing separate sources of data into a tree to be accessed via NSIndexPath.   It also provides a series of data source objects that bind this data to common UI Views. Any changes that are made to the assemblage percolates up the tree and the data source objects animate and update the backing UI Views.

Assemblages can be built from a number of native Cocoa sources, like an array, an NSFetchedResultsController, or a Key Value Coding compliant array property.  KVC Properties allow your model objects to be updated as objects are added or removed from sections.  There are also a few assemblages that perform processing on the index space, and do not represent data.  Filtered assemblages allow fast NSPredicate based filtering, and Join assemblages will represent multiple child nodes as one index space.  There is no sort assemblage currently, however, an array assemblage can easily be sorted by an array-proxy.

## UIKit
Native UIKit views are represented by very flat trees. The primary goal is to simplify the creation of cells, and to simplify the composition of table view or collection view data sources. To this Aim, RZTree provides a cell factory and a data source for both UITableView and UICollectionView. The cell factory provides blocks to bind objects to cells, and the data source loads data from the assemblage, and monitors changes to the assemblage for updating.

### UITableView

Due to the API design of UITableView, and how both the delegate and dataSource properties provide views, there's a UITableView subclass to simplify binding. It will internally intercept both the delegate and dataSource API's and respond to API methods that provide views, and relay all other messages back to the delegate and dataSource properties that are externally configured. This subclass is not required to use RZTree, but simplifies wiring things up.

## Compose data sources
A UITableView will often not map directly to an array or NSFetchedResultsController.  Juggling the data correctly is boring and error prone, and getting animations to work correctly is usually not worth it.  Lets imagine a jumbled tableview.  The first section contains a persons information, the second section is a list of friends, with a spinner when the data is loading.   And the third section has an action button, like delete or share.

```
RZTree *section1 = [RZTree nodeWithObject:person leafKeypaths:@[@"firstName", @"lastName", @"location"]];
RZTree *friends  = [RZTree nodeBackedByFetchedResultsController:friendListFRC];
RZTree *filteredFriends  = [[RZFilterAssemblage alloc] initWithAssemblage:friends];
RZTree *loading  = [RZTree nodeWithChildren:@[@"Loading"]];
RZTree *section2 = [RZTree nodeWithJoinedNodes:@[filteredFriends, loading]];
RZTree *section3 = [RZTree nodeWithChildren:@[@"Delete", @"Share"]];
RZTree *tableAssemblage = [RZTree nodeWithChildren:@[section1, section2, section3]];
```

Then a web request will be made that imports the persons friends into core data.  To disable the spinner, call

```
[loading removeLastObject];
```


## API Note

One key thing to notice when reading the API, is the use of NSIndexPath does not use the fixed section/row index paths that are common in UIKit.  An NSIndexPath with a length of 1 will represent a section, and an NSIndexPath with a length of 2 will represent a row or item.  This is done to simplify the API and composability of the assemblage, but RZTree could also be used to back an arbitrarily deep tree widget.

## History

RZTree conceptually originated from RZCollectionList.  The RZCollectionList API was a bit confusing, especially around names (RZCollectionListCollectionViewDataSourceDelegate!), and sections.   The key design difference with RZTree is that sectioning is composed and not built into any of the assemblages.  The name "Assemblage" was chosen to minimize conceptual collisions, as it is a noun that is not, and probably will not be used by anyone else.


