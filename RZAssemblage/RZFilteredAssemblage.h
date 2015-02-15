//
//  RZModifiedAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/31/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage.h"

@interface RZFilteredAssemblage : RZAssemblage

- (instancetype)initWithArray:(NSArray *)array __attribute__((unavailable));

- (instancetype)initWithAssemblage:(id<RZAssemblage>)assemblage;

@property (strong, nonatomic) NSPredicate *filter;

@end
