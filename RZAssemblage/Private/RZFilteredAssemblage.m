//
//  RZFilteredAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 4/14/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZFilteredAssemblage.h"
#import "RZAssemblage+Private.h"
#import "NSIndexSet+RZAssemblage.h"

@interface RZFilteredAssemblage() <RZAssemblageDelegate>
@property (strong, nonatomic) RZAssemblage *assemblage;
@end

@implementation RZFilteredAssemblage

- (instancetype)initWithAssemblage:(RZAssemblage *)assemblage filteredIndexPaths:(RZMutableIndexPathSet *)filteredIndexPaths
{
    self = [super init];
    if ( self ) {
        _assemblage = assemblage;
        _filteredIndexPaths = filteredIndexPaths;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p %@ filtered from %@", self.class, self, self.filteredIndexPaths, self.assemblage];
}

- (NSUInteger)exposedIndexFromIndex:(NSUInteger)index
{
    NSIndexSet *filtered = [self.filteredIndexPaths indexesAtIndexPath:nil];
    index -= [filtered countOfIndexesInRange:NSMakeRange(0, index)];
    return index;
}

- (NSUInteger)indexFromExposedIndex:(NSUInteger)index
{
    NSIndexSet *filtered = [self.filteredIndexPaths indexesAtIndexPath:nil];
    index += [filtered rz_countOfIndexesInRangesBeforeOrContainingIndex:index];
    return index;
}

#pragma mark - RZAssemblage

- (id)representedObject
{
    return self.assemblage.representedObject;
}

- (NSUInteger)countOfElements
{
    return [self.assemblage countOfElements] - self.filteredIndexPaths.count;
}

- (id)objectInElementsAtIndex:(NSUInteger)index
{
    NSUInteger exposedIndex = [self indexFromExposedIndex:index];
    return [self.assemblage objectInElementsAtIndex:exposedIndex];
}

- (NSUInteger)elementsIndexOfObject:(id)object
{
    NSUInteger index = [self.assemblage elementsIndexOfObject:object];
    NSUInteger exposedIndex = [self exposedIndexFromIndex:index];
    return exposedIndex;
}

- (id)nodeAtIndex:(NSUInteger)index;
{
    NSUInteger exposedIndex = [self indexFromExposedIndex:index];
    RZAssemblage *assemblage = [self.assemblage nodeAtIndex:exposedIndex];
    if ( assemblage ) {
        RZMutableIndexPathSet *childIndexPathSet = [self.filteredIndexPaths indexPathSetAtIndexPath:[NSIndexPath indexPathWithIndex:exposedIndex]];
        assemblage = [[RZFilteredAssemblage alloc] initWithAssemblage:assemblage filteredIndexPaths:childIndexPathSet];
    }
    return assemblage;
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    NSUInteger exposedIndex = [self indexFromExposedIndex:index];
    [[self.assemblage mutableChildren] removeObjectAtIndex:exposedIndex];
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    NSUInteger exposedIndex = [self indexFromExposedIndex:index];
    [[self.assemblage mutableChildren] insertObject:object atIndex:exposedIndex];
}

- (void)setDelegate:(id<RZAssemblageDelegate>)delegate
{
    RZRaize(NO, @"Do not configure delegate on internal class %@", self);
}

- (void)willBeginUpdatesForAssemblage:(RZAssemblage *)assemblage
{
    RZRaize(NO, @"Internal filter %@ should never recieve updates for assemblage %@", self, assemblage);
}

@end
