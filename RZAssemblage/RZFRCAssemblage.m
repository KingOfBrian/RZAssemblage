//
//  RZFRCAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZFRCAssemblage.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZAssemblage+Private.h"
#import "RZAssemblageDefines.h"
#import "RZAssemblageChangeSet.h"


#define RZAssertIndexPathLength(indexPath, offset) RZRaize(indexPath.length <= ((self.hasSections ? 2 : 1) + offset), @"Index Path %@ has length of %lu, expected index <= %d", indexPath, (unsigned long)indexPath.length, ((self.hasSections ? 2 : 1) + offset))
#define RZAssertContainerIndexPath(indexPath) RZAssertIndexPathLength(indexPath, -1)
#define RZAssertItemIndexPath(indexPath) RZAssertIndexPathLength(indexPath, 0)

@interface RZFRCAssemblage() <NSFetchedResultsControllerDelegate>

@property (assign, nonatomic, readonly) BOOL hasSections;
@property (strong, nonatomic) RZAssemblageChangeSet *changeSet;

@end

@implementation RZFRCAssemblage

@synthesize delegate = _delegate;

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;
{
    NSAssert(fetchedResultsController.delegate == nil, @"The NSFetchedResultsController delegate is already configured");
    if ( fetchedResultsController.sectionNameKeyPath ) {
        NSSortDescriptor *sortDescriptor = [fetchedResultsController.fetchRequest.sortDescriptors firstObject];
        RZRaize(sortDescriptor && [sortDescriptor.key isEqualToString:fetchedResultsController.sectionNameKeyPath],
                @"The first sort descriptor in the NSFetchRequest must match the sectionNameKeyPath or bad things happen.");
    }
    self = [super init];
    if ( self ) {
        _fetchedResultsController = fetchedResultsController;
    }
    return self;
}

- (BOOL)hasSections
{
    return self.fetchedResultsController.sectionNameKeyPath != nil;
}

- (BOOL)load:(out NSError **)error;
{
    self.fetchedResultsController.delegate = self;
    return [self.fetchedResultsController performFetch:error];
}

- (NSUInteger)childCountAtIndexPath:(NSIndexPath *)indexPath
{
    RZAssertContainerIndexPath(indexPath);
    NSUInteger childCount = NSNotFound;
    if ( self.hasSections ) {
        if ( indexPath.length == 0 ) {
            childCount = self.fetchedResultsController.sections.count;
        }
        else {
            id<NSFetchedResultsSectionInfo> sectionInfo = [self childAtIndexPath:indexPath];
            childCount = [sectionInfo numberOfObjects];
        }
    }
    else {
        return self.fetchedResultsController.fetchedObjects.count;
    }
    return childCount;
}

- (id)childAtIndexPath:(NSIndexPath *)indexPath
{
    RZAssertItemIndexPath(indexPath);
    id object = nil;
    if ( indexPath.length == 1 ) {
        NSUInteger index = [indexPath indexAtPosition:0];
        if ( self.hasSections ) {
            object = self.fetchedResultsController.sections[index];
        }
        else {
            object = self.fetchedResultsController.fetchedObjects[index];
        }
    }
    else {
        object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    return object;
}

- (NSMutableArray *)proxyArrayForIndexPath:(NSIndexPath *)indexPath;
{
    return nil;
}

- (id)representedObject
{
    return self;
}

// Fake our implementation of copy by returning an array backed assemblage.
- (id)copyWithZone:(NSZone *)zone
{
    return [self arrayAssemblageForCurrentState];
}

- (id<RZAssemblage>)arrayAssemblageForCurrentState
{
    // I don't want to support this for NSFRC, but we have to do this to keep the API correct.
    // Investigate documenting and returning an error proxy object.
    NSArray *contents = nil;
    if ( self.hasSections ) {
        NSMutableArray *sections = [NSMutableArray array];
        for ( NSUInteger i = 0; i < [self childCountAtIndexPath:nil]; i++ ) {
            NSArray *childContent = self.fetchedResultsController.sections[i];
            RZAssemblage *childAssemblage = [[RZAssemblage alloc] initWithArray:childContent];
            [sections addObject:childAssemblage];
        }
        contents = sections;
    }
    else {
        contents = [[self proxyArrayForIndexPath:nil] copy];
    }
    return [[RZAssemblage alloc] initWithArray:contents];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    NSAssert(self.changeSet == nil, @"Do not support concurrent NSFRC changes");
    RZFRCLog(@"%@", controller);
    self.changeSet = [[RZAssemblageChangeSet alloc] init];
    self.changeSet.startingAssemblage = [self arrayAssemblageForCurrentState];
    [self.delegate willBeginUpdatesForAssemblage:self];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    RZFRCLog(@"%p:type[%@] %@ -> %@ = %@", controller, @(type), [indexPath rz_shortDescription], [newIndexPath rz_shortDescription], anObject);
    // If this NSFRC does not have sections, strip the section index path, which will always be 0.
    indexPath = self.hasSections ? indexPath : [indexPath rz_indexPathByRemovingFirstIndex];
    newIndexPath = self.hasSections ? newIndexPath : [newIndexPath rz_indexPathByRemovingFirstIndex];

    switch ( type ) {
        case NSFetchedResultsChangeInsert: {
            [self.changeSet insertAtIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.changeSet removeAtIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.changeSet moveAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self.changeSet updateAtIndexPath:indexPath];
            break;
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    RZFRCLog(@"%p:type[%@] %@ = %@", controller, @(type), @(sectionIndex), sectionInfo);
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:sectionIndex];
    switch ( type ) {
        case NSFetchedResultsChangeInsert: {
            [self.changeSet insertAtIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.changeSet removeAtIndexPath:indexPath];
            break;
        }
        default: {
            [NSException raise:NSInternalInconsistencyException format:@"Got a non insert/delete section"];
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    RZFRCLog(@"%@", controller);
    [self.delegate assemblage:self didEndUpdatesWithChangeSet:self.changeSet];
    self.changeSet = nil;
}

@end
