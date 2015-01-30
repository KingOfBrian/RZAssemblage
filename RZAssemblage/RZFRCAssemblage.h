//
//  RZFRCAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblageProtocols.h"

@import CoreData;

@interface RZFRCAssemblage : NSObject<RZAssemblage>

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;

- (BOOL)load:(out NSError **)error;

@property (strong, nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@end
