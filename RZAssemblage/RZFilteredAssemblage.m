//
//  RZFilteredAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 4/14/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZFilteredAssemblage.h"
#import "RZAssemblage+Private.h"

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

- (NSUInteger)indexFromRealIndex:(NSUInteger)index
{
    NSIndexSet *filtered = [self.filteredIndexPaths indexesAtIndexPath:nil];
    index -= [filtered countOfIndexesInRange:NSMakeRange(0, index)];
    return index;
}

- (NSUInteger)realIndexFromIndex:(NSUInteger)idx
{
    __block NSUInteger index = idx;
    NSIndexSet *filtered = [self.filteredIndexPaths indexesAtIndexPath:nil];
    [filtered enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        if ( index >=  range.location ) {
            index += range.length;
        }
    }];

    return index;
}

#pragma mark - RZAssemblage

- (NSUInteger)countOfElements
{
    return [self.assemblage countOfElements] - self.filteredIndexPaths.count;
}

- (id)objectInElementsAtIndex:(NSUInteger)index
{
    index = [self realIndexFromIndex:index];
    return [self.assemblage objectInElementsAtIndex:index];
}

- (NSUInteger)elementsIndexOfObject:(id)object
{
    NSUInteger index = [self.assemblage elementsIndexOfObject:object];
    index = [self indexFromRealIndex:index];
    return index;
}

- (id)nodeAtIndex:(NSUInteger)index;
{
    index = [self realIndexFromIndex:index];
    return [self.assemblage nodeAtIndex:index];
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index
{
    index = [self realIndexFromIndex:index];
    [[self.assemblage mutableChildren] removeObjectAtIndex:index];
}

- (void)insertObject:(NSObject *)object inElementsAtIndex:(NSUInteger)index
{
    index = [self realIndexFromIndex:index];
    [[self.assemblage mutableChildren] insertObject:object atIndex:index];
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
