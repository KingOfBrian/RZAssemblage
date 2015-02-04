//
//  RZBufferedAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 2/3/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBufferedAssemblage.h"
#import "RZAssemblageDefines.h"
#import "RZBufferedAssemblageEvent.h"

@interface RZBufferedAssemblage()

@property (strong, nonatomic) id<RZAssemblage> assemblage;

@property (assign, nonatomic) BOOL bufferingIsActive;

@property (strong, nonatomic) NSMutableArray *insertEvents;
@property (strong, nonatomic) NSMutableArray *removeEvents;
@property (strong, nonatomic) NSMutableArray *updateEvents;
@property (strong, nonatomic) NSMutableArray *moveEvents;

@end

@implementation RZBufferedAssemblage

@synthesize delegate = _delegate;

- (instancetype)initWithAssemblage:(id<RZAssemblage>)assemblage
{
    self = [super init];
    if ( self ) {
        _assemblage = assemblage;
        assemblage.delegate = self;
    }
    return self;
}

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath
{
    RZRaize(self.bufferingIsActive == NO, @"Buffered assemblage should not be queried while buffering events");
    return [self.assemblage numberOfChildrenAtIndexPath:indexPath];
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    RZRaize(self.bufferingIsActive == NO, @"Buffered assemblage should not be queried while buffering events");
    return [self.assemblage objectAtIndexPath:indexPath];
}

- (NSArray *)allEvents
{
    NSMutableArray *allEvents = [NSMutableArray array];
    [allEvents addObjectsFromArray:self.insertEvents];
    [allEvents addObjectsFromArray:self.removeEvents];
    [allEvents addObjectsFromArray:self.updateEvents];
    [allEvents addObjectsFromArray:self.moveEvents];
    return [allEvents copy];
}

- (void)updateEventIndexesForInsertAtIndexPath:(NSIndexPath *)indexPath
{
    for ( RZBufferedAssemblageEvent *event in self.allEvents ) {
        [event updateIndexesForInsertAtIndexPath:indexPath];
    }
}

- (void)updateEventIndexesForRemoveAtIndexPath:(NSIndexPath *)indexPath
{
    for ( RZBufferedAssemblageEvent *event in self.allEvents ) {
        [event updateIndexesForRemoveAtIndexPath:indexPath];
    }
}

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblage>)assemblage
{
    RZLogTrace1(assemblage);
    RZRaize(self.bufferingIsActive == NO, @"Buffered assemblage began updates while already buffering");
    self.bufferingIsActive = YES;
    self.insertEvents = [NSMutableArray array];
    self.removeEvents = [NSMutableArray array];
    self.updateEvents = [NSMutableArray array];
    self.moveEvents   = [NSMutableArray array];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZLogTrace3(assemblage, object, indexPath);
    [self updateEventIndexesForInsertAtIndexPath:indexPath];
    [self.insertEvents addObject:[RZBufferedAssemblageEvent eventForObject:object atIndexPath:indexPath]];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZLogTrace3(assemblage, object, indexPath);
    // I still don't think that section removals will be managed correctly.  It should remove any events
    // for index paths that are contained by this indexPath I believe.
    [self updateEventIndexesForRemoveAtIndexPath:indexPath];
    [self.removeEvents addObject:[RZBufferedAssemblageEvent eventForObject:object atIndexPath:indexPath]];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZLogTrace3(assemblage, object, indexPath);
    [self.updateEvents addObject:[RZBufferedAssemblageEvent eventForObject:object atIndexPath:indexPath]];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    RZLogTrace4(assemblage, object, fromIndexPath, toIndexPath);
    [self updateEventIndexesForRemoveAtIndexPath:fromIndexPath];
    [self updateEventIndexesForInsertAtIndexPath:toIndexPath];
    [self.moveEvents addObject:[RZBufferedAssemblageMoveEvent eventForObject:object fromIndexPath:fromIndexPath toIndexPath:toIndexPath]];
}

- (void)didEndUpdatesForEnsemble:(id<RZAssemblage>)assemblage
{
    RZLogTrace1(assemblage);
    self.bufferingIsActive = NO;
    [self submitBufferedUpdates];
    self.insertEvents = nil;
    self.removeEvents = nil;
    self.updateEvents = nil;
    self.moveEvents   = nil;
}

- (void)submitBufferedUpdates
{
    NSUInteger indexDepth = 0;
    // Do one pass to determine how deep the index paths we've received have gotten.
    // For UIKit views, this will probably always be 2.
    for ( RZBufferedAssemblageEvent *event in self.allEvents ) {
        indexDepth = MAX(indexDepth, event.maxIndexPathLength);
    }

    // Emit events starting shallow and getting deper
    // This will duplicate the order of NSFRC (https://github.com/Raizlabs/RZCollectionList/wiki/Batch-Notification-Order)
    [self.delegate willBeginUpdatesForAssemblage:self];
    for ( NSUInteger i = 1; i <= indexDepth; i++ ) {
        for ( RZBufferedAssemblageEvent *event in self.insertEvents ) {
            if ( event.indexPath.length == i ) {
                [self.delegate assemblage:self didInsertObject:event.object atIndexPath:event.indexPath];
            }
        }
        for ( RZBufferedAssemblageEvent *event in self.removeEvents ) {
            if ( event.indexPath.length == i ) {
                [self.delegate assemblage:self didRemoveObject:event.object atIndexPath:event.indexPath];
            }
        }
        for ( RZBufferedAssemblageEvent *event in self.updateEvents ) {
            if ( event.indexPath.length == i ) {
                [self.delegate assemblage:self didUpdateObject:event.object atIndexPath:event.indexPath];
            }
        }
        for ( RZBufferedAssemblageMoveEvent *event in self.moveEvents ) {
            if ( event.indexPath.length == i ) {
                [self.delegate assemblage:self didMoveObject:event.object fromIndexPath:event.indexPath toIndexPath:event.toIndexPath];
            }
        }
    }
    [self.delegate didEndUpdatesForEnsemble:self];
}

@end
