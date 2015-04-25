//
//  RZAssemblageTestData.m
//  RZTree
//
//  Created by Brian King on 4/15/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageTestData.h"

@implementation RZAssemblageTestData

+ (RZAssemblageTestData *)shared
{
    static RZAssemblageTestData *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[RZAssemblageTestData alloc] init];
    });
    return shared;
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.raizlabs.RZAssemblageDemo" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)storeURL
{
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"RZAssemblageDemo.sqlite"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }

    NSURL *modelURL = [[NSBundle bundleForClass:self.class] URLForResource:@"RZAssemblageDemo" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }

    // Create the coordinator and store

    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [self storeURL];
    NSError *error = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        [self encounteredFatalError:error];
    }

    return _persistentStoreCoordinator;
}

- (void)encounteredFatalError:(NSError *)error
{
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
}

- (void)reset
{
    NSError *error = nil;
    if ( [[NSFileManager defaultManager] fileExistsAtPath:self.storeURL.path] ) {
        BOOL ok = [[NSFileManager defaultManager] removeItemAtURL:self.storeURL error:&error];

        if ( !ok ) {
            [self encounteredFatalError:error];
        }
    }
    _persistentStoreCoordinator = nil;
    _managedObjectContext = nil;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for tRZAssemblageDemo.xcdatamodeldhe application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#if TARGET_OS_IPHONE

- (NSFetchedResultsController *)frcForPersonsByTeam
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"team.name" ascending:NO],
                                [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[self managedObjectContext] sectionNameKeyPath:@"team.name" cacheName:nil];
    return fetchedResultsController;
}

- (NSFetchedResultsController *)frcForFriendsOfPerson:(Person *)person
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]];
    request.predicate = [NSPredicate predicateWithFormat:@"self in %@", person.friends];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:[person managedObjectContext] sectionNameKeyPath:nil cacheName:nil];
    return fetchedResultsController;
}

#endif

#pragma mark - Core Data Saving support

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

+ (NSDictionary *)iosTeam
{
    return @{
             @"name" : @"iOS Developers",
             @"team" : @[
                     @"Zev Eisenberg",
                     @"Michael Gorbach",
                     @"Brian King",
                     @"Derek Ostrander",
                     @"Eric Slosser",
                     @"Rob Visentin",
                     @"Matt Buckley",
                     @"Michael Skiba",
                     @"Alex Rouse",
                     @"John Watson",
                     @"Adam Howitt",
                     @"John Stricker"
                     ]
             };
}

+ (NSDictionary *)androidTeam
{
    return @{
             @"name" : @"Android Developers",
             @"team" : @[
                     @"Dylan James",
                     @"Andrew Grosner",
                     @"Magdiel Lorenzo",
                     ]
             };
}

+ (NSDictionary *)bdTeam
{
    return @{
             @"name" : @"Business Development",
             @"team" : @[
                     @"Gary Fortier",
                     @"Ben Johnson",
                     ]
             };
}

+ (NSDictionary *)pmTeam
{
    return @{
             @"name" : @"Product Management",
             @"team" : @[
                     @"Jenn Pleus",
                     @"Nick Costa",
                     @"Josh Wilson"
                     ]
             };
}

- (void)createFakeData
{
    NSEntityDescription *teamDescription = [self.managedObjectModel entitiesByName][@"Team"];
    Team *ios = [[Team alloc] initWithEntity:teamDescription insertIntoManagedObjectContext:self.managedObjectContext];
    Team *android = [[Team alloc] initWithEntity:teamDescription insertIntoManagedObjectContext:self.managedObjectContext];
    Team *bd = [[Team alloc] initWithEntity:teamDescription insertIntoManagedObjectContext:self.managedObjectContext];
    Team *pm = [[Team alloc] initWithEntity:teamDescription insertIntoManagedObjectContext:self.managedObjectContext];

    [self populateTeam:ios withData:[self.class iosTeam]];
    [self populateTeam:android withData:[self.class androidTeam]];
    [self populateTeam:bd withData:[self.class bdTeam]];
    [self populateTeam:pm withData:[self.class pmTeam]];

    // iOS and android teams are enemies
    [ios enemiesWith:android];
    [android enemiesWith:ios];

    [ios alliesWith:ios];
    [android alliesWith:android];
    [bd enemiesWith:bd];
    [pm enemiesWith:pm];

    for ( Team *t in @[ios, android, pm] ) {
        [t alliesWith:bd];
    }

    // Hate may be strong, but PM's are a pain
    [ios enemiesWith:pm];
    [android enemiesWith:pm];

    [bd alliesWith:pm];
}

- (void)populateTeam:(Team *)team withData:(NSDictionary *)data
{
    NSEntityDescription *personDescription = [self.managedObjectModel entitiesByName][@"Person"];

    team.name = data[@"name"];
    for ( NSString *name in data[@"team"] ) {
        NSArray *nameComponents = [name componentsSeparatedByString:@" "];
        Person *p = [[Person alloc] initWithEntity:personDescription insertIntoManagedObjectContext:self.managedObjectContext];
        p.firstName = nameComponents[0];
        p.lastName = nameComponents[1];
        p.team = team;
    }
}

@end
