//
//  RZJoinTree.h
//  RZTree
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZTree.h"

/**
 *  A Join Tree represents multiple node's children as one flat index space.
 */
@interface RZJoinedTree : RZTree

- (instancetype)initWithNodes:(NSArray *)nodes;

@property (strong, nonatomic, readonly) NSArray *nodes;

@end
