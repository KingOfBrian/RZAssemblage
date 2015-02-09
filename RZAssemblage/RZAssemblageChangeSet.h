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

@property (copy, nonatomic, readonly) id<RZAssemblage> startingAssemblage;

@property (nonatomic, readonly) NSUInteger updateCount;
@property (strong, nonatomic, readonly) RZMutableIndexPathSet *inserts;
@property (strong, nonatomic, readonly) RZMutableIndexPathSet *updates;
@property (strong, nonatomic, readonly) RZMutableIndexPathSet *removes;
@property (strong, nonatomic, readonly) RZMutableIndexPathSet *moves;


- (void)beginUpdateWithAssemblage:(id<RZAssemblage>)assemblage;

- (void)insertAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateAtIndexPath:(NSIndexPath *)indexPath;
- (void)removeAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveAtIndexPath:(NSIndexPath *)index1 toIndexPath:(NSIndexPath *)index2;

- (void)clearInsertAtIndexPath:(NSIndexPath *)indexPath;
- (void)clearRemoveAtIndexPath:(NSIndexPath *)indexPath;
- (void)clearUpdateAtIndexPath:(NSIndexPath *)indexPath;

- (void)mergeChangeSet:(RZAssemblageChangeSet *)changeSet withIndexPathTransform:(RZAssemblageChangeSetIndexPathTransform)transform;

- (void)endUpdateWithAssemblage:(id<RZAssemblage>)assemblage;

@end
