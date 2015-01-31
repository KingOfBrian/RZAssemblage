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

@interface RZMutableAssemblage : RZAssemblage <RZMutableAssemblageSupport>

- (instancetype)initWithArray:(NSArray *)array;

// Remote change notification
- (void)notifyObjectUpdate:(id)object;
- (void)addObject:(id)anObject;
- (void)removeLastObject;

@end
