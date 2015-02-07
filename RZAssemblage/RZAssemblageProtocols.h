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
@protocol RZAssemblage <NSObject, NSCopying>

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)numberOfChildren;
- (id)objectAtIndex:(NSUInteger)index;

@property (copy, nonatomic, readonly) NSArray *allObjects;

@property (weak, nonatomic) id<RZAssemblageDelegate> delegate;

- (void)lookupIndexPath:(NSIndexPath *)indexPath forRemoval:(BOOL)forRemoval
             assemblage:(out id<RZAssemblage> *)assemblage newIndexPath:(out NSIndexPath **)newIndexPath;

@end

// This protocol is used by assemblage's to notify changes
#warning flesh out delegate once the pattern is proven.  Easier (to drag around the change set)
@protocol RZAssemblageDelegate <NSObject>

- (void)assemblage:(id<RZAssemblage>)assemblage didChange:(RZAssemblageChangeSet *)changeSet;

@end
