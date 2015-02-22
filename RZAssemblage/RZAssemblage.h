//
//  RZBaseAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RZAssemblageProtocols.h"

@protocol RZAssemblageDelegate;

@interface RZAssemblage : NSObject <RZAssemblage, RZAssemblageMutation>

- (instancetype)init __attribute__((unavailable));

- (instancetype)initWithArray:(NSArray *)array;

- (void)openBatchUpdate;

- (void)insertObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveObjectAtIndexPath:(NSIndexPath *)indexPath1 toIndexPath:(NSIndexPath *)indexPath2;

- (void)closeBatchUpdate;

@end
