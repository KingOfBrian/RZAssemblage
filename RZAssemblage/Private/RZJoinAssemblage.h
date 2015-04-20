//
//  RZJoinAssemblage.h
//  RZTree
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZTree.h"

/**
 *  A Join Assemblage represents multiple assemblages as one flat index space.
 */
@interface RZJoinAssemblage : RZTree

- (instancetype)initWithAssemblages:(NSArray *)assemblages;

@property (strong, nonatomic, readonly) NSArray *assemblages;

@end
