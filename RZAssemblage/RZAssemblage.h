//
//  RZBaseAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RZAssemblageProtocols.h"

@interface RZAssemblage : NSObject <RZAssemblageAccess>

- (id)initWithArray:(NSArray *)array;

@property (weak, nonatomic) id<RZAssemblageDelegate> delegate;

@end
