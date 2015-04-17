//
//  NSIndexSet+RZAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 4/16/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (RZAssemblage)

- (NSUInteger)rz_countOfIndexesInRangesBeforeOrContainingIndex:(NSUInteger)index;

@end
