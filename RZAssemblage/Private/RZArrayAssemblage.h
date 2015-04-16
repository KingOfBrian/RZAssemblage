//
//  RZArrayAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 3/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage.h"

@interface RZArrayAssemblage : RZAssemblage

- (instancetype)initWithArray:(NSArray *)array;

- (instancetype)initWithArray:(NSArray *)array representingObject:(id)representingObject;

@property (strong, nonatomic) id representedObject;

@property (strong, nonatomic) NSMutableArray *childrenStorage;

@end

@interface RZStaticArrayAssemblage : RZArrayAssemblage

@end