//
//  RZBaseAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RZAssemblageProtocols.h"

OBJC_EXTERN NSString *const RZAssemblageUpdateKey;

@protocol RZAssemblageDelegate;

@interface RZAssemblage : NSObject <RZAssemblage>

+ (RZAssemblage *)assemblageForArray:(NSArray *)array;
+ (RZAssemblage *)assemblageForArray:(NSArray *)array representedObject:(id)representedObject;
+ (RZAssemblage *)joinedAssemblages:(NSArray *)array;
+ (RZAssemblage *)assemblageTreeWithObject:(id)object arrayKeypaths:(NSArray *)keypaths;
+ (RZAssemblage *)assemblageTreeWithObject:(id)object arrayTreeKeypath:(NSArray *)keypaths;

- (void)openBatchUpdate;
- (void)notifyObjectUpdate:(id)object;
- (void)closeBatchUpdate;

- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;
- (void)moveObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@end
