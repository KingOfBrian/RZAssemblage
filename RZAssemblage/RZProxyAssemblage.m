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

- (BOOL)isRepeatingKeyPath
{
    // If nextKeyPaths is nil, this is a repeating tree expansion.
    return self.nextKeyPaths == nil;
}

- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Remove %@ at %zd", self, [self objectInChildrenAtIndex:index],  index);
    [self.childrenStorage removeObjectAtIndex:index];
}

- (void)insertObject:(NSObject *)object inChildrenAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Insert %@ at %zd", self, object, index);
    NSParameterAssert(object);
    object = [self monitoredVersionOfObject:object];
    [self.childrenStorage insertObject:object atIndex:index];
}

- (id)nodeInChildrenAtIndex:(NSUInteger)index
{
    id node = nil;
    if ( self.isRepeatingKeyPath ) {
        id object = [self objectInChildrenAtIndex:index];
        node = [[RZProxyAssemblage alloc] initWithObject:object childKey:self.keypath];
    }
    else if ( self.nextKeyPaths.count > 0 ) {
        id object = [self objectInChildrenAtIndex:index];
        node = [[RZProxyAssemblage alloc] initWithObject:object keypaths:self.nextKeyPaths];
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
        else {
            RZRaize(changeType != NSKeyValueChangeReplacement, @"Have to implement replacement");
        }
        [self closeBatchUpdate];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
