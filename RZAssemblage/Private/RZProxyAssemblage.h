//
//  RZProxyAssemblage.h
//  RZTree
//
//  Created by Brian King on 3/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZArrayAssemblage.h"

@interface RZProxyAssemblage : RZArrayAssemblage

- (instancetype)initWithObject:(id)object keypath:(NSString *)keypath;
- (instancetype)initWithObject:(id)object keypaths:(NSArray *)keypaths;
- (instancetype)initWithObject:(id)object childKey:(NSString *)keypaths;

@end
