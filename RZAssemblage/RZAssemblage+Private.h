//
//  RZAssemblage+Private.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage.h"
#import "RZAssemblageChangeSet+Private.h"

@interface RZAssemblage() <RZAssemblageDelegate>

@property (copy, nonatomic) NSMutableArray *childrenStorage;

@property (strong, nonatomic) RZAssemblageChangeSet *changeSet;

@property (nonatomic) NSUInteger updateCount;

// These methods should be implemented by subclasses.
- (NSUInteger)countOfChildren;
- (id)objectInChildrenAtIndex:(NSUInteger)index;
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index;
- (void)insertObject:(NSObject *)object inChildrenAtIndex:(NSUInteger)index;

@end
