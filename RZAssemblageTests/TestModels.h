//
//  TestModels.h
//  RZAssemblage
//
//  Created by Brian King on 3/20/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Artist : NSObject

+ (Artist *)pinkFloyd;

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSArray *songs;
@property (strong, nonatomic) NSArray *albumns;

@end

@interface Albumn : NSObject

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSArray *songs;

@end

@interface Song : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *duration;
@property (strong, nonatomic) NSArray *writers;

@end