//
//  RZAssemblage+Private.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage.h"

@interface NSIndexPath(RZAssemblage)

- (NSIndexPath *)rz_indexPathByRemovingFirstIndex;
- (NSUInteger)rz_lastIndex;

@end


@interface RZAssemblage() <RZAssemblageDelegate> {
@protected
    NSArray *_store;
}

@property (copy, nonatomic) NSArray *store;

@property (assign, nonatomic) NSUInteger updateCount;

- (void)assignDelegateIfObjectIsAssemblage:(id)anObject;

- (NSUInteger)indexForObject:(id)object;

@end
