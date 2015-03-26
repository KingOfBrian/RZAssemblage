//
//  RZPropertyAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 3/21/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZPropertyAssemblage.h"
#import "RZAssemblage+Private.h"

static char RZPropertyContext;

@interface RZPropertyAssemblage ()

@property (strong, nonatomic) id representedObject;
@property (strong, nonatomic) NSArray *keypaths;

@end

@implementation RZPropertyAssemblage

- (instancetype)initWithObject:(id)object keypaths:(NSArray *)keypaths;
{
    self = [super init];
    if ( self ) {
        self.representedObject = object;
        self.keypaths = keypaths;
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
                                    context:&RZPropertyContext];
    }
}

- (void)removeObservers
{
    for ( NSString *keypath in self.keypaths ) {
        [self.representedObject removeObserver:self
                                    forKeyPath:keypath
                                       context:&RZPropertyContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == &RZPropertyContext ) {
        NSUInteger index = [self.keypaths indexOfObject:keyPath];
        [self openBatchUpdate];
        [self.changeSet updateAtIndexPath:[NSIndexPath indexPathWithIndex:index]];
        [self closeBatchUpdate];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSUInteger)countOfChildren
{
    return self.keypaths.count;
}

- (id)nodeInChildrenAtIndex:(NSUInteger)index
{
    NSString *keypath = self.keypaths[index];
    return [self.representedObject valueForKeyPath:keypath];
}

// No Mutation support
- (void)removeObjectFromChildrenAtIndex:(NSUInteger)index {}
- (void)insertObject:(NSObject *)object inChildrenAtIndex:(NSUInteger)index {}
- (NSMutableArray *)mutableArrayForIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSUInteger)childrenIndexOfObject:(id)object
{
    __block NSUInteger index = NSNotFound;
    [self.keypaths enumerateObjectsUsingBlock:^(NSString *keypath, NSUInteger idx, BOOL *stop) {
        if ( [[self.representedObject valueForKeyPath:keypath] isEqual:object] ) {
            index = idx;
        }
    }];
    return index;
}

@end
