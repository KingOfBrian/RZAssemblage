//
//  RZFRCAssemblage.h
//  RZTree
//
//  Created by Brian King on 1/29/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZTree.h"

@import CoreData;

@interface RZFRCAssemblage : RZTree

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;

@property (strong, nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@end
