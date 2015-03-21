//
//  TestModels.m
//  RZAssemblage
//
//  Created by Brian King on 3/20/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "TestModels.h"

static BOOL changeNotifications = YES;

@implementation Artist

+ (void)setChangeNotifications:(BOOL)notify
{
    changeNotifications = notify;
}

+ (Artist *)pinkFloyd
{
    Artist *pinkFloyd = [[Artist alloc] init];
    pinkFloyd.name = @"Pink Floyd";

    Albumn *darkSideOfTheMoon = [[Albumn alloc] init];
    darkSideOfTheMoon.name = @"Dark Side Of The Moon";

    Song *speak = [[Song alloc] init];
    speak.name = @"Speak to Me";
    speak.writers = @[@"Mason"];
    speak.duration = @"1:13";
    
    Song *breathe = [[Song alloc] init];
    breathe.name = @"Breathe";
    breathe.writers = @[@"Waters", @"Gilmour"];
    breathe.duration = @"2:46";

    Song *otr = [[Song alloc] init];
    otr.name = @"On the Run";
    otr.writers = @[@"Gilmour", @"Waters"];
    otr.duration = @"3:35";

    Song *time = [[Song alloc] init];
    time.name = @"Time";
    time.writers = @[@"Mason", @"Waters", @"Gilmour", @"Wright"];
    time.duration = @"7:04";

    Song *gigInTheSky = [[Song alloc] init];
    gigInTheSky.name = @"The Great Gig in the Sky";
    gigInTheSky.writers = @[@"Wright", @"Clare", @"Torry"];
    gigInTheSky.duration = @"4:48";

    darkSideOfTheMoon.songs = @[speak, breathe, otr, time, gigInTheSky];

    Albumn *wishYouWereHere = [[Albumn alloc] init];

    Song *shine15 = [[Song alloc] init];
    shine15.name = @"Shine On You Crazy Diamond (Parts I-V)";
    shine15.writers = @[@"Wright", @"Waters", @"Gilmour"];
    shine15.duration = @"13:38";

    Song *welcome = [[Song alloc] init];
    welcome.name = @"Welcome to the Machine";
    welcome.writers = @[@"Waters", @"Gilmour"];
    welcome.duration = @"7:30";

    Song *have = [[Song alloc] init];
    have.name = @"Have a Cigar";
    have.writers = @[@"Waters", @"Roy Harper"];
    have.duration = @"5:24";

    Song *wish = [[Song alloc] init];
    wish.name = @"Wish You Were Here";
    wish.writers = @[@"Waters", @"Gilmour"];
    wish.duration = @"5:40";

    wishYouWereHere.name = @"Wish You Were Here";
    wishYouWereHere.songs = @[shine15, welcome, have, wish];

    pinkFloyd.albumns = @[darkSideOfTheMoon, wishYouWereHere];
    pinkFloyd.songs = [darkSideOfTheMoon.songs arrayByAddingObjectsFromArray:wishYouWereHere.songs];
    return pinkFloyd;
}

+ (NSSet *)keyPathsForValuesAffectingRZAssemblageUpdateKey
{
    return changeNotifications ? [NSSet setWithObjects:@"name", nil] : nil;
}

@end

@implementation Albumn

+ (NSSet *)keyPathsForValuesAffectingRZAssemblageUpdateKey
{
    return changeNotifications ? [NSSet setWithObjects:@"name", nil] : nil;
}

@end

@implementation Song

+ (NSSet *)keyPathsForValuesAffectingRZAssemblageUpdateKey
{
    return changeNotifications ? [NSSet setWithObjects:@"name", @"duration", nil] : nil;
}

@end
