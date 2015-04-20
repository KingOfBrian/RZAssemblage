//
//  RZArrayTree.h
//  RZTree
//
//  Created by Brian King on 3/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTree.h"

@interface RZArrayBackedTree : RZTree

- (instancetype)initWithChildren:(NSArray *)array;

- (instancetype)initWithChildren:(NSArray *)array representingObject:(id)representingObject;

@property (strong, nonatomic) id representedObject;

@property (strong, nonatomic) NSMutableArray *childrenStorage;

@end

@interface RZStaticArrayTree : RZArrayBackedTree

@end