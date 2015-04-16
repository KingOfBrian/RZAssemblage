//
//  NSIndexPath+RZAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexPath(RZAssemblage)

- (NSIndexPath *)rz_indexPathByRemovingFirstIndex;

- (NSIndexPath *)rz_indexPathByPrependingIndex:(NSUInteger)index;

- (NSIndexPath *)rz_indexPathByReplacingIndexAtPosition:(NSUInteger)position withIndex:(NSUInteger)index;

- (NSIndexPath *)rz_indexPathWithLastIndexShiftedBy:(NSInteger)shift;

- (NSUInteger)rz_lastIndex;

- (NSString *)rz_shortDescription;

- (NSIndexPath *)rz_sectionIndexPath;

@end
