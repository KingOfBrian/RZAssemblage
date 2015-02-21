//
//  RZChangeSet+Private.h
//  RZAssemblage
//
//  Created by Brian King on 2/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZAssemblageChangeSet.h"

@interface RZAssemblageChangeSet ()

@property (strong, nonatomic) RZMutableIndexPathSet *inserts;
@property (strong, nonatomic) RZMutableIndexPathSet *updates;
@property (strong, nonatomic) RZMutableIndexPathSet *removes;

@property (strong, nonatomic) NSMutableDictionary *moveFromToIndexPathMap;

- (void)insertAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateAtIndexPath:(NSIndexPath *)indexPath;
- (void)removeAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveAtIndexPath:(NSIndexPath *)index1 toIndexPath:(NSIndexPath *)index2;

- (void)mergeChangeSet:(RZAssemblageChangeSet *)changeSet withIndexPathTransform:(RZAssemblageChangeSetIndexPathTransform)transform;

@end
