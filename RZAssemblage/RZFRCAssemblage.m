//
//  RZFRCAssemblage.m
//  RZAssemblage
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZFRCAssemblage.h"
#import "NSIndexPath+RZAssemblage.h"
#import "RZArrayAssemblage.h"
#import "RZAssemblageDefines.h"
#import "RZAssemblageChangeSet+Private.h"


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

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    id object = nil;
    if ( self.hasSections && indexPath.length == 2 ) {
        object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    else {
        object = [super objectAtIndexPath:indexPath];
    }
    return object;
}

- (NSMutableArray *)mutableChildren;
{
    return nil;
}

- (NSUInteger)countOfElements
{
    NSUInteger countOfElements = NSNotFound;
    if ( self.hasSections ) {
        countOfElements = self.fetchedResultsController.sections.count;
    }
    else {
        countOfElements = self.fetchedResultsController.fetchedObjects.count;
    }
    return countOfElements;
}

- (id)objectInElementsAtIndex:(NSUInteger)index
{
    id object = nil;
    if ( self.hasSections ) {
        object = self.fetchedResultsController.sections[index];
    }
    else {
        object = self.fetchedResultsController.fetchedObjects[index];
    }
    return object;
}

- (NSUInteger)elementsIndexOfObject:(id)object
{
    NSUInteger index = NSNotFound;
    if ( self.hasSections ) {
        index = [self.fetchedResultsController.sections indexOfObject:object];
    }
    else {
        index = [self.fetchedResultsController.fetchedObjects indexOfObject:object];
    }
    return index;
}

// This should not be needed, only used to determine the origin of a change event
- (NSUInteger)indexOfAssemblage:(RZAssemblage *)assemblage
{
    RZRaize(NO, @"%@ should not be needed", NSStringFromSelector(_cmd));
    return NSNotFound;
}

- (RZAssemblage *)nodeAtIndex:(NSUInteger)index
{
    RZAssemblage *node = nil;
    if ( self.hasSections ) {
        id<NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[index];
        node = [[RZStaticArrayAssemblage alloc] initWithArray:sectionInfo.objects representingObject:sectionInfo];
    }
    return node;
}

- (id)representedObject
{
    return self.fetchedResultsController;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    NSAssert(self.changeSet == nil, @"Do not support concurrent NSFRC changes");
    RZFRCLog(@"%@", controller);
    [self openBatchUpdate];
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
            [self.changeSet removeObject:anObject atIndexPath:indexPath];
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
            [self.changeSet removeObject:sectionInfo atIndexPath:indexPath];
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
    [self closeBatchUpdate];
}

@end
