//
//  RZAssemblageDelegateEvent.h
//  RZAssemblage
//
//  Created by Brian King on 2/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZAssemblage.h"
#import "RZAssemblageChangeSet.h"

@interface RZAssemblageDelegateEvent : NSObject

@property (strong, nonatomic) id<RZAssemblage> assemblage;
@property (assign, nonatomic) SEL delegateSelector;
@property (assign, nonatomic) RZAssemblageMutationType type;
@property (strong, nonatomic) id object;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) NSIndexPath *toIndexPath;

@end
