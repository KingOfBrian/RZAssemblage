//
//  RZFilteredAssemblage.h
//  RZTree
//
//  Created by Brian King on 4/14/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTree.h"
#import "RZIndexPathSet.h"
/**
 * Private subclass for filtering an arbitrary assemblage. This does not maintain the filteredIndexPaths, it just
 * filters the injected assemblage
 */
@interface RZFilteredAssemblage : RZTree

- (instancetype)initWithAssemblage:(RZTree *)node filteredIndexPaths:(RZMutableIndexPathSet *)filteredIndexPaths;

@property (strong, nonatomic, readonly) RZMutableIndexPathSet *filteredIndexPaths;

@end
