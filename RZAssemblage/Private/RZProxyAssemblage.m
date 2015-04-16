//
//  RZProxyAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 3/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZProxyAssemblage.h"
#import "RZAssemblageChangeSet.h"
#import "RZAssemblage+Private.h"
#import "RZIndexPathSet.h"
#import "RZAssemblageDefines.h"

static void *const RZProxyKeyPathContext = (void *)&RZProxyKeyPathContext;

@interface RZProxyAssemblage ()

@property (copy, nonatomic, readonly) NSString *keypath;
@property (copy, nonatomic, readonly) NSArray *nextKeyPaths;

@end

@implementation RZProxyAssemblage

- (instancetype)initWithObject:(id)object keypath:(NSString *)keypath
{
    return [self initWithObject:object keypaths:@[keypath]];
}

- (instancetype)initWithObject:(id)object keypaths:(NSArray *)keypaths
{
    NSArray *remaining = [keypaths subarrayWithRange:NSMakeRange(1, keypaths.count - 1)];
    return [self initWithObject:object observingKeyPath:[keypaths firstObject] nextKeyPaths:remaining];
}

- (instancetype)initWithObject:(id)object childKey:(NSString *)key
{
    return [self initWithObject:object observingKeyPath:key nextKeyPaths:nil];
}

- (instancetype)initWithObject:(id)object observingKeyPath:(NSString *)keypath nextKeyPaths:(NSArray *)keypaths
{
    NSParameterAssert(object);
    NSParameterAssert(keypath);
    // Add the observer before creating the proxy array so the backed array
    // will trigger the observers.
    [object addObserver:self
             forKeyPath:keypath
                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                context:RZProxyKeyPathContext];

    NSMutableArray *proxy = [object mutableArrayValueForKeyPath:keypath];
    self = [self initWithArray:proxy representingObject:object];
    if ( self ) {
        _keypath = keypath;
        _nextKeyPaths = keypaths;
    }
    return self;
}

- (void)dealloc
{
    [self disableObservation];
}

- (void)enableObservation
{
    [self.representedObject addObserver:self
                             forKeyPath:self.keypath
                                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                context:RZProxyKeyPathContext];
}

- (void)disableObservation
{
    [self.representedObject removeObserver:self forKeyPath:self.keypath context:RZProxyKeyPathContext];
}

- (BOOL)isRepeatingKeyPath
{
    // If nextKeyPaths is nil, this is a repeating tree expansion.
    return self.nextKeyPaths == nil;
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    id object = [self objectInElementsAtIndex:index];
    RZAssemblageLog(@"%p:Remove %@ at %zd", self, object,  index);
    [self removeMonitorsForObject:object];
    [self.childrenStorage removeObjectAtIndex:index];
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Insert %@ at %zd", self, object, index);
    NSParameterAssert(object);
    [self addMonitorsForObject:object];
    [self.childrenStorage insertObject:object atIndex:index];
}

- (id)nodeAtIndex:(NSUInteger)index
{
    id node = [super nodeAtIndex:index];
    if ( node == nil && self.isRepeatingKeyPath ) {
        id object = [self objectInElementsAtIndex:index];
        [self removeMonitorsForObject:object];
        node = [[RZProxyAssemblage alloc] initWithObject:object childKey:self.keypath];
        [self addMonitorsForObject:node];
        [self disableObservation];
        [self.childrenStorage replaceObjectAtIndex:index withObject:node];
        [self enableObservation];
    }
    else if ( node == nil && self.nextKeyPaths.count > 0 ) {
        id object = [self objectInElementsAtIndex:index];
        [self removeMonitorsForObject:object];
        node = [[RZProxyAssemblage alloc] initWithObject:object keypaths:self.nextKeyPaths];
        [self addMonitorsForObject:node];
        [self disableObservation];
        [self.childrenStorage replaceObjectAtIndex:index withObject:node];
        [self enableObservation];
    }
    return node;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == RZProxyKeyPathContext ) {
        NSKeyValueChange changeType = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
        [self openBatchUpdate];
        if ( changeType == NSKeyValueChangeInsertion ) {
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:idx]];
            }];
        }
        else if ( changeType == NSKeyValueChangeRemoval ) {
            NSArray *oldValues = change[NSKeyValueChangeOldKey];
            NSUInteger i = 0;
            NSUInteger index = [indexes firstIndex];
            for ( ; i < indexes.count; i++ ) {
                id object = oldValues[i];
                [self.changeSet removeObject:object atIndexPath:[NSIndexPath indexPathWithIndex:index]];
                index = [indexes indexGreaterThanIndex:index];
            }
        }
        else if ( changeType == NSKeyValueChangeReplacement ) {
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:idx]];
            }];
        } else {
            RZRaize(changeType != NSKeyValueChangeSetting, @"Have to implement setting");
        }
        [self closeBatchUpdate];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
