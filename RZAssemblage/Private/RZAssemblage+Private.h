//
//  RZAssemblage+Private.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage.h"
#import "RZAssemblageChangeSet+Private.h"
#import "RZAssemblageDefines.h"
#import "RZIndexPathSet.h"

@interface RZAssemblage() <RZAssemblageObserver>

@property (strong, nonatomic, nullable) RZAssemblageChangeSet *changeSet;
@property (strong, nonatomic, readonly, nonnull) NSPointerArray *observers;

@property (nonatomic) NSUInteger updateCount;

@end

@interface RZAssemblage (Protected)

// These methods should be implemented by subclasses.
- (NSUInteger)countOfElements;
- (nullable id)objectInElementsAtIndex:(NSUInteger)index;
- (void)removeObjectFromElementsAtIndex:(NSUInteger)index;
- (void)insertObject:(nonnull NSObject *)object inElementsAtIndex:(NSUInteger)index;
- (NSUInteger)elementsIndexOfObject:(nonnull id)object;

- (nullable RZAssemblage *)nodeAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfAssemblage:(nonnull RZAssemblage *)assemblage;

- (void)addMonitorsForObject:(nonnull id)anObject;
- (void)removeMonitorsForObject:(nonnull id)anObject;

@end
