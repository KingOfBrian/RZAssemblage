//
//  RZAssemblageTestData.h
//  RZAssemblageTestData
//
//  Created by Brian King on 4/15/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "Team.h"
#import "Person.h"

//! Project version number for RZAssemblageTestData.
FOUNDATION_EXPORT double RZAssemblageTestDataVersionNumber;

//! Project version string for RZAssemblageTestData.
FOUNDATION_EXPORT const unsigned char RZAssemblageTestDataVersionString[];


@interface RZAssemblageTestData : NSObject

+ (RZAssemblageTestData *)shared;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSManagedObjectContext *)managedObjectContext;
- (void)saveContext;
- (void)reset;
- (NSURL *)applicationDocumentsDirectory;
- (void)createFakeData;

#if TARGET_OS_IPHONE

- (NSFetchedResultsController *)frcForPersonsByTeam;
- (NSFetchedResultsController *)frcForFriendsOfPerson:(Person *)person;

#endif

@end
