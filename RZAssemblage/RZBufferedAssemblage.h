//
//  RZBufferedAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 2/3/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageProtocols.h"

/**
 * This assemblage will buffer all events it receives until end update occurs,
 * and then it will inform the delegate of all of the events, with all indexes
 * cleaned up.
 *
 * This assemblage should only be used by data sources to buffer the delegate events
 * it receives.   It does not support mutation or mutation traversal.
 */
@interface RZBufferedAssemblage : NSObject <RZAssemblage, RZAssemblageDelegate>

- (instancetype)initWithAssemblage:(id<RZAssemblage>)assemblage;

@end
