//
//  Person.m
//  RZAssemblage
//
//  Created by Brian King on 3/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "Person.h"
#import "Person.h"
#import "Team.h"


@implementation Person

@dynamic firstName;
@dynamic lastName;
@dynamic location;
@dynamic enemies;
@dynamic friends;
@dynamic enemiesOf;
@dynamic friendsOf;
@dynamic team;

- (NSArray *)enemiesByFirstName;
{
    return [self.enemies sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]]];
}

- (void)removeObjectFromEnemiesByFirstNameAtIndex:(NSUInteger)index
{
    Person *enemy = [self.enemiesByFirstName objectAtIndex:index];
    [self removeEnemiesObject:enemy];
}

- (void)insertObject:(Person *)object inEnemiesByFirstNameAtIndex:(NSUInteger)index
{
    // The index is ignored.  I'm not sure how the KVC system will deal with this if it
    // doesn't match the sort index.
    [self addEnemiesObject:object];
}


@end
