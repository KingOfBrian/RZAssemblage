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

- (void)beginUpdates;

- (void)endUpdates;

@end
