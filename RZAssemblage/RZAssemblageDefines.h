//
//  RZAssemblageDefines.h
//  RZAssemblage
//
//  Created by Brian King on 2/1/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

// Must do a clean build after changing any of these.
#ifdef DEBUG
#define RZLog(fmt, ... ) CFShow((__bridge CFStringRef)[NSString stringWithFormat:@"%@:%d:[%p %@] - %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__,  self, NSStringFromSelector(_cmd), [NSString stringWithFormat:(fmt), ##__VA_ARGS__]])
#else
#define RZLog(fmt, ... )
#endif

#define RZAssemblageLog(fmt, ... ) RZLog(fmt, ##__VA_ARGS__)
#define RZFilterLog(fmt, ... ) RZLog(fmt, ##__VA_ARGS__)
#define RZBufferLog(fmt, ... ) RZLog(fmt, ##__VA_ARGS__)
#define RZDataSourceLog(fmt, ... ) RZLog(fmt, ##__VA_ARGS__)
#define RZFRCLog(fmt, ... ) //RZLog(fmt, ##__VA_ARGS__)

#define RZSubclassMustImplement(returnValue)     [NSException raise:NSInternalInconsistencyException format:@"%@ Must Subclass %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd)];return returnValue

#define RZRaize(expression, fmt, ...) if ( expression == NO ) { [NSException raise:NSInternalInconsistencyException format:fmt, ##__VA_ARGS__]; }
#define RZIndexPathWithLength(indexPath) RZRaize(indexPath.length > 0, @"Index Path is empty")



