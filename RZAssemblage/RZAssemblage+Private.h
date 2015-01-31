//
//  RZAssemblage+Private.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage.h"
#import "RZAssemblageProtocols+Private.h"

#define RZRaize(expression, fmt, ...) if ( expression == NO ) { [NSException raise:NSInternalInconsistencyException format:fmt, ##__VA_ARGS__]; }

@interface RZAssemblage() <RZAssemblageDelegate, RZAssemblageMutationTraversalSupport> {
@protected
    NSArray *_store;
}

@property (copy, nonatomic) NSArray *store;

@property (assign, nonatomic) NSUInteger updateCount;

- (void)assignDelegateIfObjectIsAssemblage:(id)anObject;

@end
