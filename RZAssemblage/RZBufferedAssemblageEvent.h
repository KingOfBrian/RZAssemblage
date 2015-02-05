//
//  RZBufferedAssemblageEvent.h
//  RZAssemblage
//
//  Created by Brian King on 2/3/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, RZBufferedAssemblageEventType) {
    RZBufferedAssemblageEventTypeNoEvent = 0,
    RZBufferedAssemblageEventTypeInsert,
    RZBufferedAssemblageEventTypeRemove,
    RZBufferedAssemblageEventTypeUpdate,
    RZBufferedAssemblageEventTypeMove
};

/**
 * Internal helper object for the RZBufferedAssemblage.  There should be no reason to use this externally.
 */
@interface RZBufferedAssemblageEvent : NSObject

@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (nonatomic) RZBufferedAssemblageEventType type;

+ (instancetype)insertEventForObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
+ (instancetype)updateEventForObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
+ (instancetype)removeEventForObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)maxIndexPathLength;

@end

@interface RZBufferedAssemblageMoveEvent : RZBufferedAssemblageEvent

@property (strong, nonatomic) NSIndexPath *toIndexPath;

+ (instancetype)eventForObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@end
