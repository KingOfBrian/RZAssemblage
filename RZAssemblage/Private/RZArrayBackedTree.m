//
//  RZArrayTree.m
//  RZTree
//
//  Created by Brian King on 3/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZArrayBackedTree.h"
#import "RZTree+Private.h"

NSString *const RZTreeUpdateKey = @"RZTreeUpdateKey";
static void *const RZTreeUpdateContext = (void *)&RZTreeUpdateContext;

@implementation RZArrayBackedTree

+ (BOOL)shouldObserveContents
{
    return YES;
}

- (instancetype)initWithChildren:(NSArray *)array representingObject:(id)representingObject;
{
    self = [super init];
    if ( self ) {
        self.representedObject = representingObject;
        _childrenStorage = [array isKindOfClass:[NSMutableArray class]] ? array : [array mutableCopy];
        if ( self.class.shouldObserveContents ) {
            [[_childrenStorage copy] enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
                [self addMonitorsForObject:object];
            }];
        }
    }
    return self;
}

- (instancetype)initWithChildren:(NSArray *)array
{
    return [self initWithChildren:array representingObject:nil];
}

- (void)dealloc
{
    if ( self.class.shouldObserveContents ) {
        for ( id object in _childrenStorage ) {
            [self removeMonitorsForObject:object];
        }
        self.representedObject = nil;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p - %@>", self.class, self, self.childrenStorage];
}

- (void)setRepresentedObject:(id)representedObject
{
    if ( _representedObject ) {
        [self removeMonitorsForObject:_representedObject];
    }
    _representedObject = representedObject;
    if ( _representedObject ) {
        [self addMonitorsForObject:_representedObject];
    }
}

- (NSUInteger)countOfElements
{
    return self.childrenStorage.count;
}

- (nullable id)objectInElementsAtIndex:(NSUInteger)index
{
    id object = [self.childrenStorage objectAtIndex:index];
    return [object isKindOfClass:[RZTree class]] ? [object representedObject] : object;
}

- (id)nodeAtIndex:(NSUInteger)index
{
    id node = [self.childrenStorage objectAtIndex:index];
    return [node isKindOfClass:[RZTree class]] ? node : nil;
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Remove %@ at %zd", self, [self objectInElementsAtIndex:index],  index);
    [self openBatchUpdate];
    id object = [self.childrenStorage objectAtIndex:index];
    [self.childrenStorage removeObjectAtIndex:index];
    [self.changeSet removeObject:object atIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    RZAssemblageLog(@"%p:Insert %@ at %zd", self, object, index);
    NSParameterAssert(object);
    [self addMonitorsForObject:object];
    [self openBatchUpdate];
    [self.childrenStorage insertObject:object atIndex:index];
    [self.changeSet insertAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
    [self closeBatchUpdate];
}

- (NSUInteger)elementsIndexOfObject:(id)object
{
    return [self.childrenStorage indexOfObject:object];
}

- (void)addMonitorsForObject:(id)anObject
{
    [super addMonitorsForObject:anObject];
    if ( self.class.shouldObserveContents &&
        [[anObject class] keyPathsForValuesAffectingValueForKey:RZTreeUpdateKey].count ) {
        RZAssemblageLog(@"%@ adding observer %@", self, anObject);
        [anObject addObserver:self
                   forKeyPath:RZTreeUpdateKey
                      options:NSKeyValueObservingOptionNew
                      context:RZTreeUpdateContext];
    }
}

- (void)removeMonitorsForObject:(id)anObject;
{
    [super removeMonitorsForObject:anObject];
    if ( self.class.shouldObserveContents &&
        [[anObject class] keyPathsForValuesAffectingValueForKey:RZTreeUpdateKey].count ) {
        RZAssemblageLog(@"%@ removing observer %@", self, anObject);
        [anObject removeObserver:self
                      forKeyPath:RZTreeUpdateKey
                         context:RZTreeUpdateContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == RZTreeUpdateContext ) {
        [self openBatchUpdate];
        if ( object == self.representedObject ) {
            [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndexes:NULL length:0]];
        }
        else {
            NSUInteger index = [self elementsIndexOfObject:object];
            [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
        }
        [self closeBatchUpdate];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

@implementation RZStaticArrayTree

+ (BOOL)shouldObserveContents
{
    return NO;
}

@end

@implementation NSObject (RZTreeUpdateKey)

- (id)RZTreeUpdateKey { return  nil; }
- (void)setRZTreeUpdateKey:(id)RZTreeUpdateKey {}

@end
