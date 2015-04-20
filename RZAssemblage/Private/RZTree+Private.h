//
//  RZTree+Private.h
//  RZTree
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTree.h"
#import "RZChangeSet+Private.h"
#import "RZAssemblageDefines.h"
#import "RZIndexPathSet.h"

@interface RZTree () <RZTreeObserver>

@property (strong, nonatomic, nullable) RZChangeSet *changeSet;
@property (strong, nonatomic, readonly, nonnull) NSPointerArray *observers;

@property (nonatomic) NSUInteger updateCount;

@end

@interface RZTree (Protected)

// These methods should be implemented by subclasses.
- (NSUInteger)countOfElements;
- (nullable id)objectInElementsAtIndex:(NSUInteger)index;
- (void)removeObjectFromElementsAtIndex:(NSUInteger)index;
- (void)insertObject:(nonnull NSObject *)object inElementsAtIndex:(NSUInteger)index;
- (NSUInteger)elementsIndexOfObject:(nonnull id)object;

- (nullable RZTree *)nodeAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfNode:(nonnull RZTree *)node;

- (void)addMonitorsForObject:(nonnull id)anObject;
- (void)removeMonitorsForObject:(nonnull id)anObject;

@end
