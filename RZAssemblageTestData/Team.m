//
//  Team.m
//  RZTree
//
//  Created by Brian King on 3/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "Team.h"
#import "Person.h"


@implementation Team

@dynamic name;
@dynamic members;

- (void)alliesWith:(Team *)otherTeam
{
    for ( Person *p in self.members ) {
        [p addFriends:otherTeam.members];
    }
}

- (void)enemiesWith:(Team *)otherTeam
{
    for ( Person *p in self.members ) {
        [p addEnemies:otherTeam.members];
    }
}

@end
