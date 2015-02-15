//
//  RZMutableAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZAssemblage.h"
#import "RZAssemblageProtocols.h"

@interface RZMutableAssemblage : RZAssemblage

// Remote change notification
- (void)notifyObjectUpdate:(id)object;

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)addObject:(id)anObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)removeLastObject;

@end

@interface RZAssemblage (RZAssemblageMutation)

- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2;

@end
