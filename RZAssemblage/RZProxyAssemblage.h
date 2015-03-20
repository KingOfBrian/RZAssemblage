//
//  RZProxyAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 3/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZAssemblage.h"

@interface RZProxyAssemblage : RZAssemblage

- (instancetype)initWithObject:(id)object arrayKeyPath:(NSString *)keypath;

@property (copy, nonatomic, readonly) NSString *keypath;

@end
