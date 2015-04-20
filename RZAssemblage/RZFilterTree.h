//
//  RZModifiedTree.h
//  RZTree
//
//  Created by Brian King on 1/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTree.h"

@interface RZFilterTree : RZTree

- (nonnull instancetype)initWithAssemblage:(nonnull RZTree *)node;

@property (strong, nonatomic, nullable) NSPredicate *filter;

@end
