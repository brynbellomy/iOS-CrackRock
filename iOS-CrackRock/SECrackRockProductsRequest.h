//
//  SECrackRockProductsRequest.h
//  iOS-CrackRock
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 illumntr. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^ProductsRequestResponseBlock)(NSError *error, NSArray *validProducts, NSArray *invalidProductIDs);

@interface SECrackRockProductsRequest : NSObject <SKProductsRequestDelegate>

@property (nonatomic, copy, readonly) NSString *state;

- (id) initWithProductIDs:(NSSet *)productIDs
                    queue:(dispatch_queue_t)parentQueue
               completion:(ProductsRequestResponseBlock)blockCompletion;

//
// state machine actions
//
- (void) start;
- (void) cancel;

//
// state machine states
//
- (BOOL) isReady;
- (BOOL) isRunning;
- (BOOL) isComplete;
- (BOOL) isCancelled;

@end
