//
//  RZPropertyAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 3/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZPropertyAssemblage.h"
#import "RZAssemblage+Private.h"

static void *const RZPropertyContext = (void *)&RZPropertyContext;

@interface RZPropertyAssemblage ()

@property (strong, nonatomic) id representedObject;
@property (strong, nonatomic) NSMutableArray *keypaths;

@end

@implementation RZPropertyAssemblage

- (instancetype)initWithObject:(id)object keypaths:(NSArray *)keypaths;
{
    self = [super init];
    if ( self ) {
        self.representedObject = object;
        self.keypaths = [keypaths mutableCopy];
        [self addObservers];
    }
    return self;
}

- (void)dealloc
{
    [self removeObservers];
}

- (void)addObservers
{
    for ( NSString *keypath in self.keypaths ) {
        [self.representedObject addObserver:self
                                 forKeyPath:keypath
                                    options:NSKeyValueObservingOptionNew
                                    context:RZPropertyContext];
    }
}

- (void)removeObservers
{
    for ( NSString *keypath in self.keypaths ) {
        [self.representedObject removeObserver:self
                                    forKeyPath:keypath
                                       context:RZPropertyContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == RZPropertyContext ) {
        NSUInteger index = [self.keypaths indexOfObject:keyPath];
        [self openBatchUpdate];
        [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
        [self closeBatchUpdate];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSUInteger)countOfElements
{
    return self.keypaths.count;
}

- (nullable id)objectInElementsAtIndex:(NSUInteger)index
{
    NSString *keypath = self.keypaths[index];
    return [self.representedObject valueForKeyPath:keypath];
}

- (NSUInteger)elementsIndexOfObject:(id)object
{
    __block NSUInteger index = NSNotFound;
    [self.keypaths enumerateObjectsUsingBlock:^(NSString *keypath, NSUInteger idx, BOOL *stop) {
        if ( [[self.representedObject valueForKeyPath:keypath] isEqual:object] ) {
            index = idx;
        }
    }];
    return index;
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    NSString *keypath = self.keypaths[index];
    [self openBatchUpdate];
    [self.representedObject removeObserver:self forKeyPath:keypath context:RZPropertyContext];
    [self.keypaths removeObjectAtIndex:index];
    [self.changeSet removeObject:keypath atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)insertObject:(NSString *)keypath inElementsAtIndex:(NSUInteger)index
{
    RZRaize([keypath isKindOfClass:[NSString class]], @"Can only insert valid keypaths into a property assemblage");
    [self openBatchUpdate];
    [self.representedObject addObserver:self
                             forKeyPath:keypath
                                options:NSKeyValueObservingOptionNew
                                context:RZPropertyContext];
    [self.keypaths insertObject:keypath atIndex:index];
    [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)replaceObjectInElementsAtIndex:(NSUInteger)index withObject:(id)object
{
    NSString *keypath = self.keypaths[index];
    [self.representedObject setValue:object forKeyPath:keypath];
}

@end
