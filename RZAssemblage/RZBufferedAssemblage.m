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
#import "NSIndexPath+RZAssemblage.h"

// Move buffering is more complex.  Lets get the basics working first.
#define RZNoMoveSupportYet RZRaize(NO, @"No support for moving")

@interface RZBufferedAssemblage()

@property (strong, nonatomic) id<RZAssemblage> assemblage;

@property (assign, nonatomic) BOOL bufferingIsActive;

@property (strong, nonatomic) NSMutableDictionary *eventsByIndexPath;

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

- (void)handleInsertEvent:(RZBufferedAssemblageEvent *)event
{
    NSIndexPath *indexPath = event.indexPath;
    RZBufferedAssemblageEvent *previousEvent = self.eventsByIndexPath[indexPath];

    switch ( previousEvent.type) {
        case RZBufferedAssemblageEventTypeNoEvent:
            self.eventsByIndexPath[indexPath] = event;
            break;
        case RZBufferedAssemblageEventTypeRemove:
            // If there was a remove and an insert, it looks just like an update.
            event.type = RZBufferedAssemblageEventTypeUpdate;
            self.eventsByIndexPath[indexPath] = event;
            break;
        case RZBufferedAssemblageEventTypeInsert:
            self.eventsByIndexPath[indexPath] = event;
            // Shift down the existing insert event
            previousEvent.indexPath = [previousEvent.indexPath rz_indexPathWithLastIndexShiftedBy:1];
            [self handleInsertEvent:previousEvent];
            break;
        case RZBufferedAssemblageEventTypeUpdate:
            self.eventsByIndexPath[indexPath] = event;
            // Shift down the existing event
            previousEvent.indexPath = [previousEvent.indexPath rz_indexPathWithLastIndexShiftedBy:1];
            [self handleUpdateEvent:previousEvent];
            break;
        case RZBufferedAssemblageEventTypeMove:
            RZNoMoveSupportYet;
            break;

        default:
            break;
    }
}

- (void)handleRemoveEvent:(RZBufferedAssemblageEvent *)event
{
    NSIndexPath *indexPath = event.indexPath;
    RZBufferedAssemblageEvent *previousEvent = self.eventsByIndexPath[indexPath];
    switch ( previousEvent.type ) {
        case RZBufferedAssemblageEventTypeNoEvent:
            self.eventsByIndexPath[indexPath] = event;
            break;
        case RZBufferedAssemblageEventTypeInsert:
            // If the previous event was an insert, discard the event.  An insert / remove has no side-effect
            [self.eventsByIndexPath removeObjectForKey:indexPath];
            break;
        case RZBufferedAssemblageEventTypeRemove:
            // If the previous event was a remove, increment the index (ie: Remove the item after it)
            event.indexPath = [indexPath rz_indexPathWithLastIndexShiftedBy:1];
            // Since this operation could chain effects, recurse with the new index path
            [self handleRemoveEvent:event];
            break;
        case RZBufferedAssemblageEventTypeUpdate:
            // If the previous event was a update, over-write it with the latest update
            self.eventsByIndexPath[indexPath] = event;
            break;
        case RZBufferedAssemblageEventTypeMove:
            RZNoMoveSupportYet;
            break;
        default:
            break;
    }
}

- (void)handleUpdateEvent:(RZBufferedAssemblageEvent *)event
{
    NSIndexPath *indexPath = event.indexPath;
    RZBufferedAssemblageEvent *previousEvent = self.eventsByIndexPath[indexPath];
    switch ( previousEvent.type ) {
        case RZBufferedAssemblageEventTypeNoEvent:
            self.eventsByIndexPath[indexPath] = event;
            break;
        case RZBufferedAssemblageEventTypeInsert:
            // If there was already an insert at this index, the update is not important.
            // ensure that the delegate notifies the latest value though.
            previousEvent.object = event.object;
            break;
        case RZBufferedAssemblageEventTypeRemove:
            // I'm not sure what to do here.   I don't believe this should ever happen naturally
            // off of the delegate, but a doctored index could land here.   Lets just log and no-op
            // now
            NSLog(@"Got an update for an index that was removed.  Not sure what to do:\n%@\n%@", event, previousEvent);
            break;
        case RZBufferedAssemblageEventTypeUpdate:
            // If there's already an update, update the object.
            previousEvent.object = event.object;
            break;
        case RZBufferedAssemblageEventTypeMove:
            RZNoMoveSupportYet;
            break;
        default:
            break;
    }
}

- (void)willBeginUpdatesForAssemblage:(id<RZAssemblage>)assemblage
{
    RZBufferLog(@"%@", assemblage);
    RZRaize(self.bufferingIsActive == NO, @"Buffered assemblage began updates while already buffering");
    self.bufferingIsActive = YES;
    self.eventsByIndexPath = [NSMutableDictionary dictionary];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZBufferLog(@"%p I[%@] = %@", assemblage, [indexPath rz_shortDescription], object);
    RZBufferedAssemblageEvent *insert = [RZBufferedAssemblageEvent insertEventForObject:object atIndexPath:indexPath];
    [self handleInsertEvent:insert];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didRemoveObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZBufferLog(@"%p R[%@] = %@", assemblage, [indexPath rz_shortDescription], object);
    RZBufferedAssemblageEvent *remove = [RZBufferedAssemblageEvent removeEventForObject:object atIndexPath:indexPath];
    [self handleRemoveEvent:remove];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    RZBufferLog(@"%p U[%@] = %@", assemblage, [indexPath rz_shortDescription], object);
    RZBufferedAssemblageEvent *update = [RZBufferedAssemblageEvent removeEventForObject:object atIndexPath:indexPath];
    [self handleUpdateEvent:update];
}

- (void)assemblage:(id<RZAssemblage>)assemblage didMoveObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    RZBufferLog(@"%p M[%@] -> [%@] = %@", assemblage, [fromIndexPath rz_shortDescription], [toIndexPath rz_shortDescription], object);
    RZNoMoveSupportYet;
}

- (void)didEndUpdatesForEnsemble:(id<RZAssemblage>)assemblage
{
    RZBufferLog(@"%@", assemblage);
    self.bufferingIsActive = NO;
    [self submitBufferedUpdates];
}

- (void)submitBufferedUpdates
{
    NSArray *allEvents = [self.eventsByIndexPath allValues];
    NSUInteger indexDepth = 0;
    // Do one pass to determine how deep the index paths we've received have gotten.
    // For UIKit views, this will probably always be 2.
    for ( RZBufferedAssemblageEvent *event in allEvents ) {
        indexDepth = MAX(indexDepth, event.maxIndexPathLength);
    }

    // Emit events starting shallow and getting deper.  This will emit section events and then row events for UIKit.
    // This will duplicate the order of NSFRC (https://github.com/Raizlabs/RZCollectionList/wiki/Batch-Notification-Order)
    [self.delegate willBeginUpdatesForAssemblage:self];
    for ( NSUInteger i = 1; i <= indexDepth; i++ ) {
        for ( RZBufferedAssemblageEvent *event in allEvents ) {
            if ( event.indexPath.length == i && event.type == RZBufferedAssemblageEventTypeInsert ) {
                [self.delegate assemblage:self didInsertObject:event.object atIndexPath:event.indexPath];
            }
        }
        for ( RZBufferedAssemblageEvent *event in allEvents ) {
            if ( event.indexPath.length == i && event.type == RZBufferedAssemblageEventTypeRemove ) {
                [self.delegate assemblage:self didRemoveObject:event.object atIndexPath:event.indexPath];
            }
        }
        for ( RZBufferedAssemblageEvent *event in allEvents ) {
            if ( event.indexPath.length == i && event.type == RZBufferedAssemblageEventTypeUpdate ) {
                [self.delegate assemblage:self didUpdateObject:event.object atIndexPath:event.indexPath];
            }
        }
        for ( RZBufferedAssemblageMoveEvent *event in allEvents ) {
            if ( event.indexPath.length == i && event.type == RZBufferedAssemblageEventTypeMove ) {
                [self.delegate assemblage:self didMoveObject:event.object fromIndexPath:event.indexPath toIndexPath:event.toIndexPath];
            }
        }
    }
    [self.delegate didEndUpdatesForEnsemble:self];
}

@end
