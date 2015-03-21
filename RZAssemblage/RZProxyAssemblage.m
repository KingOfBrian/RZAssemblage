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

static char RZProxyKeyPathContext;

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
                context:&RZProxyKeyPathContext];

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
    [self.representedObject removeObserver:self forKeyPath:self.keypath context:&RZProxyKeyPathContext];
}

- (id)copyWithZone:(NSZone *)zone;
{
    NSMutableArray *children = [NSMutableArray array];
    NSUInteger childCount = [self countOfChildren];

    for ( NSUInteger i = 0; i < childCount; i++ ) {
        // Do not access the children through `nodeInChildrenAtIndex:` like default, as this
        // will trigger the tree expansion.
        id object = [self.childrenStorage objectAtIndex:i];
        if ( [object conformsToProtocol:@protocol(RZAssemblage)] ) {
            object = [object copy];
        }
        [children addObject:object];
    }

    return [[RZCopyAssemblage alloc] initWithArray:children
                                representingObject:[self representedObject]];
}

- (BOOL)isRepeatingKeyPath
{
    // If nextKeyPaths is nil, this is a repeating tree expansion.
    return self.nextKeyPaths == nil;
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index
{
    id object = [self objectInChildrenAtIndex:index];
    RZAssemblageLog(@"%p:Remove %@ at %zd", self, object,  index);
    [self removeMonitorsForObject:object];
    [self.childrenStorage removeObjectAtIndex:index];
}

- (void)insertObject:(NSObject *)object inChildrenAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Insert %@ at %zd", self, object, index);
    NSParameterAssert(object);
    [self addMonitorsForObject:object];
    [self.childrenStorage insertObject:object atIndex:index];
}

- (id)nodeInChildrenAtIndex:(NSUInteger)index
{
    id node = [super nodeInChildrenAtIndex:index];
    if ( self.isRepeatingKeyPath ) {
        if ( [node conformsToProtocol:@protocol(RZAssemblage)] == NO ) {
            [self removeMonitorsForObject:node];
            node = [[RZProxyAssemblage alloc] initWithObject:node childKey:self.keypath];
            [self addMonitorsForObject:node];
            [self.childrenStorage replaceObjectAtIndex:index withObject:node];
        }
    }
    else if ( self.nextKeyPaths.count > 0 ) {
        if ( [node conformsToProtocol:@protocol(RZAssemblage)] == NO ) {
            [self removeMonitorsForObject:node];
            node = [[RZProxyAssemblage alloc] initWithObject:node keypaths:self.nextKeyPaths];
            [self addMonitorsForObject:node];
            [self.childrenStorage replaceObjectAtIndex:index withObject:node];
        }
    }
    return node;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == &RZProxyKeyPathContext ) {
        NSKeyValueChange changeType = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
        [self openBatchUpdate];
        if ( changeType == NSKeyValueChangeInsertion ) {
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:idx]];
            }];
        }
        else if ( changeType == NSKeyValueChangeRemoval ) {
            [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [self.changeSet removeAtIndexPath:[NSIndexPath indexPathWithIndex:idx]];
            }];
        }
        else if ( changeType == NSKeyValueChangeReplacement ) {
            id newObject = change[NSKeyValueChangeNewKey];
            id oldObject = change[NSKeyValueChangeOldKey];
            BOOL isAssemblageSwap = ([newObject conformsToProtocol:@protocol(RZAssemblage)] &&
                                     [oldObject conformsToProtocol:@protocol(RZAssemblage)] == NO);
            if ( isAssemblageSwap == NO && indexes.count == 1 ) {
                [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:indexes.firstIndex]];
            }
            else {
                RZRaize(changeType != NSKeyValueChangeReplacement, @"Unexpected Replacement");
            }
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
