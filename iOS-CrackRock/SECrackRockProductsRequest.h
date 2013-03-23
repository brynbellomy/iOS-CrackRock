//
//  SECrackRockProductsRequest.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 illumntr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <BrynKit/GCDThreadsafe.h>

typedef void(^SEProductsRequestResponseBlock)(NSError *error, NSArray *validProducts, NSArray *invalidProductIDs);

@interface SECrackRockProductsRequest : NSObject <GCDThreadsafe, SKProductsRequestDelegate>

@property (nonatomic, copy,   readonly) NSString *state;
@property (nonatomic, strong, readonly) NSError *error;

+ (RACSignal *) rac_productsRequestForProductIDs:(NSSet *)productIDs scheduler:(RACScheduler *)scheduler;

- (id) initWithProductIDs:(NSSet *)productIDs completion:(SEProductsRequestResponseBlock)blockCompletion;

//
// state machine actions
//
- (void) doStart;
- (void) doCancel;

//
// state machine states
//
- (BOOL) isReady;
- (BOOL) isRunning;
- (BOOL) isComplete;
- (BOOL) isCancelled;
- (BOOL) isError;

@end
