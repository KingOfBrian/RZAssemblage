//
//  RZBufferedAssemblageEvent.m
//  RZAssemblage
//
//  Created by Brian King on 2/3/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZBufferedAssemblageEvent.h"
#import "NSIndexPath+RZAssemblage.h"

NSString * NSStringForRZAssemblageEventType(RZBufferedAssemblageEventType type) {
    NSString *result = nil;
    switch (type) {
        case RZBufferedAssemblageEventTypeNoEvent:
            result = @"None";
            break;
        case RZBufferedAssemblageEventTypeInsert:
            result = @"Insert";
            break;
        case RZBufferedAssemblageEventTypeRemove:
            result = @"Remove";
            break;
        case RZBufferedAssemblageEventTypeUpdate:
            result = @"Update";
            break;
        case RZBufferedAssemblageEventTypeMove:
            result = @"Move";
            break;

        default:
            break;
    }
    return result;
}

@implementation RZBufferedAssemblageEvent

+ (instancetype)insertEventForObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
{
    RZBufferedAssemblageEvent *event = [[self alloc] init];
    event.object = object;
    event.indexPath = indexPath;
    event.type = RZBufferedAssemblageEventTypeInsert;
    return event;
}

+ (instancetype)updateEventForObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
{
    RZBufferedAssemblageEvent *event = [[self alloc] init];
    event.object = object;
    event.indexPath = indexPath;
    event.type = RZBufferedAssemblageEventTypeUpdate;
    return event;
}

+ (instancetype)removeEventForObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
{
    RZBufferedAssemblageEvent *event = [[self alloc] init];
    event.object = object;
    event.indexPath = indexPath;
    event.type = RZBufferedAssemblageEventTypeRemove;
    return event;
}

- (NSUInteger)maxIndexPathLength
{
    return self.indexPath.length;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p %@ indexPath=%@, object=%@>", self.class, self, NSStringForRZAssemblageEventType(self.type), self.indexPath, self.object];
}

@end

@implementation RZBufferedAssemblageMoveEvent

+ (instancetype)eventForObject:(id)object fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    RZBufferedAssemblageMoveEvent *event = [[RZBufferedAssemblageMoveEvent alloc] init];
    event.type = RZBufferedAssemblageEventTypeMove;
    event.object = object;
    event.indexPath = fromIndexPath;
    event.toIndexPath = toIndexPath;
    return event;
}

- (NSUInteger)maxIndexPathLength
{
    return MAX([super maxIndexPathLength], self.toIndexPath.length);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p %@ fromIndexPath=%@, toIndexPath=%@, object=%@>", self.class, self, @"Move", self.indexPath, self.toIndexPath, self.object];
}

@end
