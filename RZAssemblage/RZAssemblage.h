//
//  RZBaseAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RZAssemblageDelegate;

@interface RZAssemblage : NSObject

- (id)initWithArray:(NSArray *)array;

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

@property (weak, nonatomic) id<RZAssemblageDelegate> delegate;

- (id)init __attribute__((unavailable));

@end

@protocol RZAssemblageDelegate <NSObject>

- (void)willBeginUpdatesForAssemblage:(RZAssemblage *)assemblage;
- (void)assemblage:(RZAssemblage *)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)assemblage:(RZAssemblage *)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)assemblage:(RZAssemblage *)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)assemblage:(RZAssemblage *)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)didEndUpdatesForEnsemble:(RZAssemblage *)assemblage;

@end
