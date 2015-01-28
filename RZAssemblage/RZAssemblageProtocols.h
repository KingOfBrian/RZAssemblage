//
//  RZAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/27/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

// This protocol is the API used by data sources
@protocol RZAssemblageAccess <NSObject>

@end

// This protocol is used by assemblage's to implement nesting
@protocol RZAssemblageNesting <RZAssemblageAccess>


@end

// This protocol is used by assemblage's to notify changes
