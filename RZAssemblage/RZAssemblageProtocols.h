//
//  RZAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RZAssemblageDelegate;
@class RZAssemblageChangeSet;

// This protocol is the API used by data sources
@protocol RZAssemblage <NSObject>

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)numberOfChildren;
- (id)objectAtIndex:(NSUInteger)index;

@property (copy, nonatomic, readonly) NSArray *allObjects;

@property (weak, nonatomic) id<RZAssemblageDelegate> delegate;

@end

@protocol RZMutableAssemblageSupport <RZAssemblage>

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeObjectAtIndex:(NSUInteger)index;

@end

@protocol RZAssemblageMutationTraversal <RZAssemblage>

// Index Path mutation.
// These methods will assert if the index path lands on an assemblage that does not support RZMutableAssemblageSupport.
- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2;

@end

// This protocol is used by assemblage's to notify changes
#warning flesh out delegate once the pattern is proven.  Easier (to drag around the change set)
@protocol RZAssemblageDelegate <NSObject>

- (void)assemblage:(id<RZAssemblage>)assemblage didChange:(RZAssemblageChangeSet *)changeSet;

@end
