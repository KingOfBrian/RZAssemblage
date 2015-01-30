//
//  RZMutableAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZAssemblage.h"

@interface RZMutableAssemblage : RZAssemblage

- (instancetype)initWithArray:(NSArray *)array;

// Batch Updatingd
- (void)beginUpdates;
- (void)endUpdates;
- (void)beginUpdateAndEndUpdateNextRunloop;

// Basic mutation
- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;

// Remote change notification
- (void)notifyObjectUpdate:(id)object;

// Index Path mutation.
// These methods will assert if the index path lands on a non-mutable assemblage.
- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2;

@end
