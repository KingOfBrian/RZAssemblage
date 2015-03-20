//
//  RZChangeSet.h
//  RZAssemblage
//
//  Created by Brian King on 2/7/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZAssemblageProtocols.h"
@class RZMutableIndexPathSet;

typedef NSIndexPath *(^RZAssemblageChangeSetIndexPathTransform)(NSIndexPath *indexPath);

typedef NS_ENUM(NSUInteger, RZAssemblageMutationType) {
    RZAssemblageMutationTypeInsert = 0,
    RZAssemblageMutationTypeUpdate,
    RZAssemblageMutationTypeRemove,
    RZAssemblageMutationTypeMove
};

@interface RZAssemblageChangeSet : NSObject

+ (NSIndexSet *)sectionIndexSetFromIndexPaths:(NSArray *)indexPaths;
+ (NSArray *)rowIndexPathsFromIndexPaths:(NSArray *)indexPaths;

@property (copy, nonatomic) id<RZAssemblage> startingAssemblage;

@property (strong, nonatomic, readonly) NSArray *insertedIndexPaths;
@property (strong, nonatomic, readonly) NSArray *updatedIndexPaths;
@property (strong, nonatomic, readonly) NSArray *removedIndexPaths;
@property (strong, nonatomic, readonly) NSDictionary *moveFromToIndexPaths;

- (void)generateMoveEventsFromAssemblage:(id<RZAssemblage>)assemblage;

@end
