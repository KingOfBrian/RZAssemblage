//
//  RZAssemblageDelegateEvent.m
//  RZAssemblage
//
//  Created by Brian King on 2/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageDelegateEvent.h"
#import "NSIndexPath+RZAssemblage.h"

@implementation RZAssemblageDelegateEvent

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@, %p, %@ T=%zd O=%@ I=%@ %@>",
            [super description], self.assemblage,
            NSStringFromSelector(self.delegateSelector),
            self.type,
            self.object,
            [self.indexPath rz_shortDescription],
            self.toIndexPath ? [self.toIndexPath rz_shortDescription] : @""];
}

@end
