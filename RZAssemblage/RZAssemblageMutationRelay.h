//
//  RZAssemblageMutationRelay.h
//  RZAssemblage
//
//  Created by Brian King on 2/15/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * This protocol allows mutation methods on RZAssemblage to traverse assemblages
 * that do not support mutation.
 */
@protocol RZAssemblageMutationRelay <RZAssemblage>

- (void)lookupIndexPath:(NSIndexPath *)indexPath forRemoval:(BOOL)forRemoval
             assemblage:(out id<RZAssemblage> *)assemblage newIndexPath:(out NSIndexPath **)newIndexPath;

@end
