//
//  RZAssemblageDefines.h
//  RZAssemblage
//
//  Created by Brian King on 2/1/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RZLog(format, ...) NSLog(format, ##__VA_ARGS__)
#define RZLogTrace1(arg1) RZLog(@"%@ - %@", NSStringFromSelector(_cmd), arg1)
#define RZLogTrace2(arg1, arg2) RZLog(@"%@ - %@ %@", NSStringFromSelector(_cmd), arg1, arg2)
#define RZLogTrace3(arg1, arg2, arg3) RZLog(@"%@ - %@ %@ %@", NSStringFromSelector(_cmd), arg1, arg2, arg3)
#define RZLogTrace4(arg1, arg2, arg3, arg4) RZLog(@"%@ - %@ %@ %@ %@", NSStringFromSelector(_cmd), arg1, arg2, arg3, arg4);
#define RZLogTrace5(arg1, arg2, arg3, arg4, arg5) RZLog(@"%@ - %@ %@ %@ %@ %@", NSStringFromSelector(_cmd), arg1, arg2, arg3, arg4, arg5);

#define RZConformTraversal(assemblage) RZRaize([assemblage conformsToProtocol:@protocol(RZAssemblageMutationTraversal)], @"Index Path attempted to traverse %@, which does not conform to RZAssemblageMutationTraversal", assemblage);
#define RZConformMutationSupport(assemblage) RZRaize([assemblage conformsToProtocol:@protocol(RZMutableAssemblageSupport)], @"Index Path landed on %@, which does not support mutation.", self);

#define RZIndexPathWithLength(indexPath) RZRaize(indexPath.length > 0, @"Index Path is empty")


