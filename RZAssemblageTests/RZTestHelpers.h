//
//  RZTestHelpers.h
//  RZAssemblage
//
//  Created by Brian King on 4/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZIndexPathSet.h"
#import "TestModels.h"

@interface NSIndexPath (RZTestHelpers)

+ (NSIndexPath *)indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section;

@end

@interface RZMutableIndexPathSet(Test)

- (BOOL)containsIndex:(NSUInteger)index;

@end
