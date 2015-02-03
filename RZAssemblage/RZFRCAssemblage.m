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

#define RZAssertIndexPathLength(indexPath, offset) RZRaize(indexPath.length <= ((self.hasSections ? 2 : 1) + offset), @"Index Path %@ has length of %lu, expected index <= %d", indexPath, (unsigned long)indexPath.length, ((self.hasSections ? 2 : 1) + offset))
#define RZAssertContainerIndexPath(indexPath) RZAssertIndexPathLength(indexPath, -1)
#define RZAssertItemIndexPath(indexPath) RZAssertIndexPathLength(indexPath, 0)

@interface RZFRCAssemblage() <NSFetchedResultsControllerDelegate>

@property (assign, nonatomic, readonly) BOOL hasSections;

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

- (NSUInteger)numberOfChildrenAtIndexPath:(NSIndexPath *)indexPath
{
    RZAssertContainerIndexPath(indexPath);
    NSUInteger numberOfChildren = NSNotFound;
    if ( self.hasSections ) {
        if ( indexPath.length == 0 ) {
            numberOfChildren = self.fetchedResultsController.sections.count;
        }
        else {
            id<NSFetchedResultsSectionInfo> sectionInfo = [self objectAtIndexPath:indexPath];
            numberOfChildren = [sectionInfo numberOfObjects];
        }
    }
    else {
        return self.fetchedResultsController.fetchedObjects.count;
    }
    return numberOfChildren;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
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

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    RZLogTrace1(controller);
    [self.delegate willBeginUpdatesForAssemblage:self];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    RZLogTrace5(controller, anObject, indexPath, @(type), newIndexPath);
    // If this NSFRC does not have sections, strip the section index path, which will always be 0.
    indexPath = self.hasSections ? indexPath : [indexPath rz_indexPathByRemovingFirstIndex];
    newIndexPath = self.hasSections ? newIndexPath : [newIndexPath rz_indexPathByRemovingFirstIndex];

    switch ( type ) {
        case NSFetchedResultsChangeInsert: {
            [self.delegate assemblage:self didInsertObject:anObject atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.delegate assemblage:self didRemoveObject:anObject atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.delegate assemblage:self didMoveObject:anObject fromIndexPath:indexPath toIndexPath:newIndexPath];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            [self.delegate assemblage:self didUpdateObject:anObject atIndexPath:indexPath];
            break;
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    RZLogTrace4(controller, sectionInfo, @(sectionIndex), @(type));
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:sectionIndex];
    switch ( type ) {
        case NSFetchedResultsChangeInsert: {
            [self.delegate assemblage:self didInsertObject:sectionInfo atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.delegate assemblage:self didRemoveObject:sectionInfo atIndexPath:indexPath];
            break;
        }
        default: {
            [NSException raise:NSInternalInconsistencyException format:@"Got a non insert/delete section"];
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    RZLogTrace1(controller);
    [self.delegate didEndUpdatesForEnsemble:self];
}

@end
