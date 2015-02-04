//
//  RZBufferedAssemblageEvent.h
//  RZAssemblage
//
//  Created by Brian King on 2/3/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Internal helper object for the RZBufferedAssemblage.  There should be no reason to use this externally.
 */
@interface RZBufferedAssemblageEvent : NSObject

@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSIndexPath *indexPath;

+ (instancetype)eventForObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

- (void)updateIndexesForInsertAtIndexPath:(NSIndexPath *)indexPath;

- (void)updateIndexesForRemoveAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)maxIndexPathLength;

@end

@interface RZBufferedAssemblageMoveEvent : RZBufferedAssemblageEvent

@property (strong, nonatomic) NSIndexPath *toIndexPath;

+ (instancetype)eventForObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@end
