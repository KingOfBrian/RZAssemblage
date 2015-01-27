//
//  RZMutableAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZAssemblage.h"

@interface RZMutableAssemblage : RZAssemblage <RZAssemblageAccess>

- (instancetype)initWithArray:(NSArray *)array;

- (void)beginUpdates;
- (void)endUpdates;
- (void)beginUpdateAndEndUpdateNextRunloop;

- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;
- (void)notifyObjectUpdate:(id)object;

@end
