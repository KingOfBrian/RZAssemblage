//
//  RZFRCAssemblage.h
//  RZAssemblage
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAssemblage.h"

@import CoreData;

@interface RZFRCAssemblage : RZAssemblage

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;

- (BOOL)load:(out NSError **)error;

@property (strong, nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@end
