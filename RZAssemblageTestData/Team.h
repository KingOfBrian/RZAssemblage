//
//  Team.h
//  RZAssemblage
//
//  Created by Brian King on 3/25/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Person;

@interface Team : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *members;

- (void)enemiesWith:(Team *)otherTeam;
- (void)alliesWith:(Team *)otherTeam;


@end
