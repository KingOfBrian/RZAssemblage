//
//  Person.h
//  RZAssemblage
//
//  Created by Brian King on 3/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Person, Team;

@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSSet *enemies;
@property (nonatomic, retain) NSSet *friends;
@property (nonatomic, retain) NSSet *enemiesOf;
@property (nonatomic, retain) NSSet *friendsOf;
@property (nonatomic, retain) Team *team;

- (NSArray *)enemiesByFirstName;


@end

@interface Person (CoreDataGeneratedAccessors)

- (void)addEnemiesObject:(Person *)value;
- (void)removeEnemiesObject:(Person *)value;
- (void)addEnemies:(NSSet *)values;
- (void)removeEnemies:(NSSet *)values;

- (void)addFriendsObject:(Person *)value;
- (void)removeFriendsObject:(Person *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

- (void)addEnemiesOfObject:(Person *)value;
- (void)removeEnemiesOfObject:(Person *)value;
- (void)addEnemiesOf:(NSSet *)values;
- (void)removeEnemiesOf:(NSSet *)values;

- (void)addFriendsOfObject:(Person *)value;
- (void)removeFriendsOfObject:(Person *)value;
- (void)addFriendsOf:(NSSet *)values;
- (void)removeFriendsOf:(NSSet *)values;

@end
