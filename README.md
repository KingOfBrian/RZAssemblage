# RZAssemblage - Composable Data Sources
RZAssemblage allows composing separate sources of data (Static Arrays or NSFetchedResultsControllers) into a unified NSIndexPath space.  Any changes to the backing data store will percolate up the assemblage and emit change events that the data source objects can use to update the view with proper change animations.

# Cell Creation
  A primary goal of RZAssemblage is to simplify cell creation.  This entails passing the object in the assemblage along with index path to the delegate.  This allows the cell creation code to change from `switch` and `if ( indexPath.section == MagicNumber )` with `if ( [object isKindOf:[DataModel class]] ) `.

# Compose data sources
A UITableView will often not map directly to an array.  Juggling the data correctly is boring and error prone, and getting animations to work correctly is usually not worth it.  Lets imagine a jumbled tableview.  The first section contains a persons information, the second section is a list of friends, with a spinner when the data is loading.   And the third section has an action button, like delete or share.

```
RZAssemblage *section1 = [[RZPropertyAssemblage alloc] initWithObject:person keys:@[@"firstName", @"lastName", @"streetAddress"]];
RZAssemblage *friends  = [[RZFRCAssemblage alloc] initWithFetchedResultsController:friendListFRC];
RZAssemblage *loading  = [[RZMutableAssemblage alloc] initWithArray:@"Loading"];
RZAssemblage *section2 = [[RZJoinAssemblage alloc] initWithArray:@[friends, loading]];
RZAssemblage *section3 = [[RZAssemblage alloc] initWithArray:@[@"Delete", @"Share"]];
RZAssemblage *tableAssemblage = [[RZAssemblage alloc] initWithArray:@[section1, section2, section3]];
```

Then a web request will be made that imports the persons friends into core data.  To disable the spinner, call

```
[loading removeLastObject];
```


## API Note

One key thing to notice when reading the API, is the use of NSIndexPath does not use the fixed section/row index paths that are common in UIKit.  An NSIndexPath with a length of 1 will represent a section, and an NSIndexPath with a length of 2 will represent a row or item.  This is done to simplify the API and composability of the assemblage, but RZAssemblage could also be used to back an arbitrarily deep tree widget.

## History

RZAssemblage conceptually originated from RZCollectionList.  The RZCollectionList API was a bit confusing, especially around names (RZCollectionListCollectionViewDataSourceDelegate!), and sections.   The key design difference with RZAssemblage is that sectioning is composed and not built into any of the assemblages.  The name "Assemblage" was chosen to minimize conceptual collisions, as it is a noun that is not, and probably will not be used by anyone else.


