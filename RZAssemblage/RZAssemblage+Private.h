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

@interface RZAssemblage() <RZAssemblageDelegate>

@property (strong, nonatomic) RZAssemblageChangeSet *changeSet;

@property (nonatomic) NSUInteger updateCount;

@end

@interface RZAssemblage (Protected)

// These methods should be implemented by subclasses.
- (NSUInteger)countOfElements;
- (id)objectInElementsAtIndex:(NSUInteger)index;
- (void)removeObjectFromElementsAtIndex:(NSUInteger)index;
- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index;
- (NSUInteger)elementsIndexOfObject:(id)object;


- (RZAssemblage *)nodeAtIndex:(NSUInteger)index;
- (void)addMonitorsForObject:(id)anObject;
- (void)removeMonitorsForObject:(id)anObject;

@end
