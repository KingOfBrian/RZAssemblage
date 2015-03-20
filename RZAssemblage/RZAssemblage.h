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

@interface RZAssemblage : NSObject <RZAssemblage>

- (instancetype)init __attribute__((unavailable));

- (instancetype)initWithArray:(NSArray *)array;
- (instancetype)initWithArray:(NSArray *)array representingObject:(id)representingObject;

- (void)openBatchUpdate;
- (void)notifyObjectUpdate:(id)object;
- (void)closeBatchUpdate;

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@end
