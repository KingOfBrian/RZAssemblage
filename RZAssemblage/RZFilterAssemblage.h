//
//  RZModifiedAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage.h"

@interface RZFilterAssemblage : RZAssemblage

@property (strong, nonatomic) NSPredicate *filter;

@end

@interface RZAssemblage (Filter)

- (RZFilterAssemblage *)filterAssemblage;

@end