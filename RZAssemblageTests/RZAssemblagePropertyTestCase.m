//
//  RZAssemblagePropertyTestCase.m
//  RZAssemblage
//
//  Created by Brian King on 2/19/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Fox/Fox.h>

#import "RZAssemblage.h"
#import "RZAssemblage+Mutation.h"
#import "RZJoinAssemblage.h"
#import "RZFilteredAssemblage.h"
#import "RZAssemblageChangeSet.h"
#import "RZIndexPathSet.h"
#import "NSIndexPath+RZAssemblage.h"

#define EVENT(type, i, cs) ({\
RZAssemblageStateMachineEvent *e = [[RZAssemblageStateMachineEvent alloc] init];\
e.mutationType = type;\
e.index = i;\
e.changeSet = cs;\
e;\
})

@interface RZAssemblageStateMachineEvent : NSObject

@property (assign) RZAssemblageMutationType mutationType;
@property (assign) NSUInteger index;
@property (strong) RZAssemblageChangeSet *changeSet;

@end

@implementation RZAssemblageStateMachineEvent
@end


@interface RZAssemblageBatchState : NSObject <NSCopying>

@property () BOOL open;
@property () BOOL hasBeenOpened;
@property () NSUInteger count;

@end

@implementation RZAssemblageBatchState

- (id)copyWithZone:(NSZone *)zone
{
    RZAssemblageBatchState *s = [[RZAssemblageBatchState alloc] init];
    s.count = _count;
    s.open = _open;
    s.hasBeenOpened = _hasBeenOpened;
    return s;

}

- (RZAssemblageBatchState *)openState
{
    RZAssemblageBatchState *s = [self copy];
    s.open = YES;
    s.hasBeenOpened = YES;
    return s;
}

- (RZAssemblageBatchState *)closeState
{
    RZAssemblageBatchState *s = [self copy];
    s.open = NO;
    return s;
}

- (RZAssemblageBatchState *)incrementState
{
    RZAssemblageBatchState *s = [self copy];
    s.count = self.count + 1;
    return s;
}

- (RZAssemblageBatchState *)decrementState
{
    RZAssemblageBatchState *s = [self copy];
    s.count = self.count - 1;
    return s;
}

@end




@interface RZAssemblagePropertyTestCase : XCTestCase <RZAssemblageDelegate>

@property (strong, nonatomic) RZAssemblageChangeSet *lastChangeSet;
@property (assign, nonatomic) NSUInteger lastIndex;
@property (strong, nonatomic) FOXFiniteStateMachine *stateMachine;

@property (strong, nonatomic) FOXTransition *openTransition;
@property (strong, nonatomic) FOXTransition *closeTransition;


@end

@implementation RZAssemblagePropertyTestCase

- (void)setUp
{
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];

    // Batched Properties -- Unique Objects
}

- (void)assemblage:(id<RZAssemblage>)assemblage didEndUpdatesWithChangeSet:(RZAssemblageChangeSet *)changeSet
{
    self.lastChangeSet = changeSet;
}

/**
 * Non Batched Properties
 *  - Every Insert on an assemblage @ index generates an insert event @ index
 *  - Every Removal on an assemblage @ index generates a removal @ index
 *  - IndexPath of every event reflects the assemblage tree container
 */
- (void)testNonBatched
{
    typeof(self) welf = (id)self;
    self.stateMachine = [[FOXFiniteStateMachine alloc] initWithInitialModelState:@0];

    FOXTransition *addTransition = [[FOXTransition alloc] initWithAction:^id(RZAssemblage *assemblage, id generatedValue) {
        [assemblage addObject:generatedValue];

        return EVENT(RZAssemblageMutationTypeInsert, assemblage.numberOfChildren - 1, welf.lastChangeSet);
    } nextModelState:^id(NSNumber *count, id generatedValue) {
        return @([count integerValue] + 1);
    }];

    addTransition.postcondition = ^BOOL(NSNumber *modelState, NSNumber *previousModelState,
                                        RZAssemblage *assemblage, id generatedValue, RZAssemblageStateMachineEvent *e) {
        NSIndexPath *indexPath = e.changeSet.insertedIndexPaths.lastObject;
        BOOL countsOK = (e.changeSet.insertedIndexPaths.count == 1 &&
                         e.changeSet.updatedIndexPaths.count == 0 &&
                         e.changeSet.removedIndexPaths.count == 0);
        BOOL indexOK = [indexPath rz_lastIndex] == e.index;
        BOOL typeOK  =  e.mutationType == RZAssemblageMutationTypeInsert;
        return countsOK && indexOK && typeOK;
    };
    addTransition.generator = FOXInteger();

    FOXTransition *removeRandomTransition = [[FOXTransition alloc] initWithAction:^id(RZAssemblage *assemblage, id generatedValue) {
        NSUInteger index = arc4random() % [assemblage numberOfChildren];
        [assemblage removeObjectAtIndex:index];
        return EVENT(RZAssemblageMutationTypeRemove, index, welf.lastChangeSet);
    } nextModelState:^id(NSNumber *count, id generatedValue) {
        return @([count integerValue] - 1);
    }];

    removeRandomTransition.postcondition = ^BOOL(NSNumber *modelState, NSNumber *previousModelState,
                                                 RZAssemblage *assemblage, id generatedValue, RZAssemblageStateMachineEvent *e) {
        NSIndexPath *indexPath = e.changeSet.removedIndexPaths.lastObject;
        BOOL countsOK = (e.changeSet.insertedIndexPaths.count == 0 &&
                         e.changeSet.updatedIndexPaths.count  == 0 &&
                         e.changeSet.removedIndexPaths.count  == 1);
        BOOL indexOK = [indexPath rz_lastIndex] == e.index;
        BOOL typeOK  =  e.mutationType == RZAssemblageMutationTypeRemove;
        return countsOK && indexOK && typeOK;
    };

    removeRandomTransition.precondition = ^BOOL(NSNumber *modelState) {
        return [modelState unsignedIntegerValue] > 1;
    };

    [self.stateMachine addTransition:addTransition];
    [self.stateMachine addTransition:removeRandomTransition];

    id<FOXGenerator> executedCommands = FOXExecuteCommands(self.stateMachine, ^id{
        RZAssemblage *assemblage = [[RZAssemblage alloc] initWithArray:@[]];
        assemblage.delegate = welf;
        return assemblage;
    });
    // verify that all the executed commands properly conformed to the state machine.
    FOXAssert(FOXForAll(executedCommands, ^BOOL(NSArray *commands) {
        return FOXExecutedSuccessfully(commands);
    }));

}

/**
 * Batched Properties -- Unique Objects, track removed objects
 *  - Insertion's generate an insert event, or are recorded in the removal log
 *  - All objects removed from the assemblage were in the assemblage when the batch began
 *  - All objects in the assemblage at the end of the batch do not have a remove event
 *  - Every object without a insert or remove is @ (startIndex - (number of removes in front) + (number of inserts in front)
 *  - (Extra Credit) All objects in the asssemblage at the end of the batch are in the tableview(!)
 */
- (void)testBatching
{
    typeof(self) welf = (id)self;
    self.stateMachine = [[FOXFiniteStateMachine alloc] initWithInitialModelState:[[RZAssemblageBatchState alloc] init]];

    // Define the openBatchUpdate transition when the state is not and has not been opened.
    self.openTransition = [[FOXTransition alloc] initWithAction:^id(RZAssemblage *assemblage, id generatedValue) {
        [assemblage openBatchUpdate];
        return nil;
    } nextModelState:^id(RZAssemblageBatchState *modelState, id generatedValue) {
        return [modelState openState];
    }];
    self.openTransition.precondition = ^BOOL(RZAssemblageBatchState *modelState) {
        return modelState.open == NO && modelState.hasBeenOpened == NO;
    };
    [self.stateMachine addTransition:self.openTransition];


    // Define the closeBatchUpdate transition once the state has been opened.
    self.closeTransition = [[FOXTransition alloc] initWithAction:^id(RZAssemblage *assemblage, id generatedValue) {
        [assemblage closeBatchUpdate];
        return nil;
    } nextModelState:^id(RZAssemblageBatchState *modelState, id generatedValue) {
        return [modelState closeState];
    }];
    self.closeTransition.precondition = ^BOOL(RZAssemblageBatchState *modelState) {
        return modelState.open && modelState.count > 3;
    };
    [self.stateMachine addTransition:self.closeTransition];

    // Define an add transition that can occur once the state has opened.
    FOXTransition *addTransition = [[FOXTransition alloc] initWithAction:^id(RZAssemblage *assemblage, id generatedValue) {
        NSUInteger count = [assemblage numberOfChildren];
        NSUInteger index = count == 0 ? 0 : arc4random() % count;
        [assemblage insertObject:generatedValue atIndex:index];
        return EVENT(RZAssemblageMutationTypeInsert, index, welf.lastChangeSet);
    } nextModelState:^id(RZAssemblageBatchState *modelState, id generatedValue) {
        return [modelState incrementState];
    }];
    addTransition.precondition = ^BOOL(RZAssemblageBatchState *modelState) {
        return modelState.open;
    };
    addTransition.generator = FOXInteger();
    [self.stateMachine addTransition:addTransition];

    FOXTransition *removeTransition = [[FOXTransition alloc] initWithAction:^id(RZAssemblage *assemblage, id generatedValue) {
        NSUInteger index = arc4random() % [assemblage numberOfChildren];
        [assemblage removeObjectAtIndex:index];
        return EVENT(RZAssemblageMutationTypeRemove, index, welf.lastChangeSet);
    } nextModelState:^id(RZAssemblageBatchState *modelState, id generatedValue) {
        return [modelState decrementState];
    }];

    removeTransition.precondition = ^BOOL(RZAssemblageBatchState *modelState) {
        return modelState.open && modelState.count > 0;
    };
    [self.stateMachine addTransition:removeTransition];

    id<FOXGenerator> executedCommands = FOXExecuteCommands(self.stateMachine, ^id{
        RZAssemblage *assemblage = [[RZAssemblage alloc] initWithArray:@[]];
        assemblage.delegate = welf;
        return assemblage;
    });
    // verify that all the executed commands properly conformed to the state machine.
    FOXAssert(FOXForAll(executedCommands, ^BOOL(NSArray *commands) {
        return FOXExecutedSuccessfully(commands);
    }));
}

@end
