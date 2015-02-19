//
//  RZAssemblage+Private.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage.h"
#import "RZAssemblageChangeSet.h"
#import "RZAssemblageMutationRelay.h"

@interface RZAssemblage() <RZAssemblageMutationRelay, RZAssemblageDelegate> {
@protected
    NSMutableArray *_store;
}

@property (copy, nonatomic) NSMutableArray *store;

@property (strong, nonatomic) RZAssemblageChangeSet *changeSet;

@property (nonatomic) NSUInteger updateCount;

- (void)assignDelegateIfObjectIsAssemblage:(id)anObject;

@end
