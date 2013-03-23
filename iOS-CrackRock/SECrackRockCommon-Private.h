//
//  SECrackRockCommon-Private.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/23/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <BrynKit/BrynKitCocoaLumberjack.h>
#import "SECrackRockCommon.h"


Key(SECrackRockUserDefaultsKey_purchasedItems);

#define SECrackRock_LOG_CONTEXT 1119

#if !defined(lllog)
#   define lllog(severity, __FORMAT__, ...) metamacro_concat(SECrackRockLog,severity)((__FORMAT__), ## __VA_ARGS__)
#endif

#define SECrackRockLogError(__FORMAT__, ...)     SYNC_LOG_OBJC_MAYBE([SECrackRock ddLogLevel], LOG_FLAG_ERROR,   SECrackRock_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define SECrackRockLogSuccess(__FORMAT__, ...)   SYNC_LOG_OBJC_MAYBE([SECrackRock ddLogLevel], LOG_FLAG_SUCCESS, SECrackRock_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define SECrackRockLogWarn(__FORMAT__, ...)      SYNC_LOG_OBJC_MAYBE([SECrackRock ddLogLevel], LOG_FLAG_WARN,    SECrackRock_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define SECrackRockLogInfo(__FORMAT__, ...)      SYNC_LOG_OBJC_MAYBE([SECrackRock ddLogLevel], LOG_FLAG_INFO,    SECrackRock_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define SECrackRockLogVerbose(__FORMAT__, ...)   SYNC_LOG_OBJC_MAYBE([SECrackRock ddLogLevel], LOG_FLAG_VERBOSE, SECrackRock_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)




