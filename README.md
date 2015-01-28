RZAssemblage is a simplistic (and incomplete) replacement for RZCollectionList.  It's goals are:
- Associate objects with index paths for easy cell creation
- Sync state between objects and tableview / collectionview
- Compose various data types into index paths.  IE: 1 section of static data and 1 section of coredata data
- Minimize tracked state
- Minimize API naming conflicts (It's the first synonym of collection that wasn't already used)

One key thing to notice when reading the API, is the use of NSIndexPath does not use the fixed section/row index paths that are common in UIKit.  An NSIndexPath has a length attribute, and in UIKit backed assemblages, an index path with 1 index is used for sections, and an index path with 2 indexes is used for rows or items.   This is done to simplify the composition complexity, but RZAssemblage could also be used to back an arbitrarily deep tree widget if desired.

It knowingly avoids multiple observers, and it naively avoids: 
- filtering
- sorting
- Change notification re-ordering


