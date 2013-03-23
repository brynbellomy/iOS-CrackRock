//
//  SECrackRockProductsRequest.m
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 illumntr. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import <StateMachine-GCDThreadsafe/StateMachine.h>
#import <BrynKit/BrynKit.h>
#import <BrynKit/GCDThreadsafe.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <libextobjc/EXTScope.h>

#import "SECrackRockProductsRequest.h"
#import "SECrackRockProduct.h"
#import "SECrackRockProduct-Private.h"
#import "SECrackRockCommon-Private.h"

@interface SECrackRockProductsRequest () <SEThreadsafeStateMachine>
    @property (nonatomic, strong, readwrite) NSSet *productIDs;
    @property (nonatomic, strong, readwrite) SKProductsRequest  *productsRequest;
    @property (nonatomic, strong, readwrite) SKProductsResponse *productsResponse;
    @property (nonatomic, copy,   readwrite) SEProductsRequestResponseBlock blockCompletion;
    @property (nonatomic, copy,   readwrite) NSString *state;
    @property (nonatomic, strong, readwrite) NSError *error;
@end

@interface SECrackRockProductsRequest (StateMachine_Private)
    - (void) initializeStateMachine;

    - (void) start;
    - (void) cancel;
    - (void) complete;
    - (void) error;
@end



@implementation SECrackRockProductsRequest
    @gcd_threadsafe

STATE_MACHINE(^(LSStateMachine *sm) {
    sm.initialState = @"ready";

    //
    // states
    //
    [sm addState:@"ready"];
    [sm addState:@"running"];
    [sm addState:@"complete"];
    [sm addState:@"cancelled"];
    [sm addState:@"error"];


    //
    // transitions
    //
    [sm when: @"start" transitionFrom:@"ready" to:@"running"];
    [sm after:@"start" do:^(SECrackRockProductsRequest *self) {
        if (self.productIDs == nil || self.productIDs.count <= 0)
        {
            lllog(Warn, @"No paid products");
            [self doComplete:nil];
        }

        // if there are actual, non-free in-app purchases to retrieve from apple, then start retrieving them
        else
        {
            [self performStoreKitRequest];
        }
    }];



    [sm when: @"complete" transitionFrom:@"running" to:@"completed"];
    [sm after:@"complete" do:^(SECrackRockProductsRequest *self) {
        lllog(Info, @"%d requested products available", self.productsResponse.products.count);

        // call the completion block
        [self callCompletionCallback];
    }];



    [sm when: @"error" transitionFrom:@"ready" to:@"error"];
    [sm when: @"error" transitionFrom:@"running" to:@"error"];
    [sm when: @"error" transitionFrom:@"complete" to:@"error"];
    [sm when: @"error" transitionFrom:@"cancelled" to:@"error"];
    [sm after:@"error" do:^(SECrackRockProductsRequest *self) {
        [self callCompletionCallback];
    }];



    [sm when:  @"cancel" transitionFrom:@"running" to:@"cancelled"];
    [sm before:@"cancel" do:^(SECrackRockProductsRequest *self) {
        [self.productsRequest cancel];
    }];
    [sm after: @"cancel" do:^(SECrackRockProductsRequest *self) {
        [self callCompletionCallback];
    }];

});



+ (RACSignal *) rac_productsRequestForProductIDs:(NSSet *)_productIDs
                                       scheduler:(RACScheduler *)scheduler
{
    yssert_notNilAndIsClass(_productIDs, NSSet);
    yssert_notNilAndIsClass(scheduler, RACScheduler);

    __block NSSet *productIDs = [_productIDs copy];

	RACReplaySubject *subject = [RACReplaySubject subject];
	[subject setNameWithFormat:@"+rac_productsRequestForProductIDs: %@ scheduler: %@", productIDs, scheduler];

	[scheduler schedule:^{
        __block SECrackRockProductsRequest *request;
        request = [[SECrackRockProductsRequest alloc] initWithProductIDs:[productIDs copy]
                                                              completion:^(NSError *error, NSArray *validProducts, NSArray *invalidProductIDs) {

                                                                  // @@TODO: just have to hold on to the request somehow... this definitely oughta be refactored
                                                                  printf("\n\n[@@TODO: refactor me!!!] inside products request completion block / productIDs = %s\n\n", request.description.UTF8String);

                                                                  if (error != nil) {
                                                                      lllog(Error, @"Error in products request: %@", error.localizedDescription);
                                                                      [subject sendError:error];
                                                                      return;
                                                                  }

                                                                  RACTuple *tuple = RACTuplePack(validProducts, invalidProductIDs);
                                                                  [subject sendNext: tuple];
                                                                  [subject sendCompleted];
                                                              }];
        [request doStart];
	}];

	return subject;
}




#pragma mark- Lifecycle
#pragma mark-

- (id) initWithProductIDs:(NSSet *)productIDs
               completion:(SEProductsRequestResponseBlock)blockCompletion
{
    self = [super init];
    if (self)
    {
        [self initializeStateMachine];

        _productIDs      = [productIDs copy] ?: NSSet.set;
        _blockCompletion = [blockCompletion copy];
        _queueCritical   = dispatch_queue_create("com.signalenvelope.SECrackRock.ProductsRequest.queueCritical", 0);
    }
    return self;
}



- (void) dealloc
{
    if (_productsRequest.delegate == self) {
        _productsRequest.delegate = nil;
    }

    [_productsRequest cancel];
    _productsRequest = nil;
}



#pragma mark- StoreKit
#pragma mark-

/**!
 * #### performStoreKitRequest:
 *
 * @return {void}
 */

- (void) performStoreKitRequest
{
    @weakify(self);
    [self runCriticalMutableSection:^{
        @strongify(self);

        yssert_notNilAndIsClass(self.productIDs, NSSet);

        //
        // IAP is disabled
        //
        if (NO == [SKPaymentQueue canMakePayments])
        {
            lllog(Error, @"IAP Disabled");
            [self doError: [NSError errorWithDomain: @"com.signalenvelope.SECrackRock" code: 1
                                           userInfo: @{ @"description": @"In-app purchasing is disabled on this device." }]];
            return;
        }

        //
        // IAP is enabled on this device.  proceed with products request.
        //

        // cancel any existing, pending (possibly hung) request
        if (self.productsRequest != nil) {
            [self.productsRequest cancel];
            self.productsRequest = nil;
        }

        // initiate new product request for specified productIDs
        self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:self.productIDs];
        self.productsRequest.delegate = self;
        [self.productsRequest start];
    }];
}



/**
 * #### productsRequest:didReceiveResponse:
 *
 * Store Kit returns a response from an SKProductsRequest.
 *
 * @param {SKProductsRequest*} request
 * @param {SKProductsResponse*} response
 *
 * @return {void}
 */

- (void) productsRequest: (SKProductsRequest *)request
      didReceiveResponse: (SKProductsResponse *)response
{
    @weakify(self);
    [self runCriticalMutableSection:^{
        @strongify(self);

        yssert(self.productsRequest == request);
        [self doComplete:response];
    }];
}


#pragma mark- Misc.
#pragma mark-

/**
 * doStart
 *
 *
 */

- (void) doStart
{
    [self start];
}



/**
 * doError:
 *
 *
 */

- (void) doError: (NSError *)error
{
    @weakify(self);
    [self runCriticalMutableSection:^{
        @strongify(self);

        self.error = error;
        [self error];
    }];
}



/**
 * doCancel
 *
 *
 */

- (void) doCancel
{
    @weakify(self);
    [self runCriticalMutableSection:^{
        @strongify(self);

        self.error = [NSError errorWithDomain: @"com.signalenvelope.SECrackRock.ProductsRequest" code: 2
                                     userInfo: @{@"description": @"Request cancelled"}];
        [self cancel];
    }];
}



/**
 * doComplete:
 *
 *
 */

- (void) doComplete: (SKProductsResponse *)response
{
    @weakify(self);
    [self runCriticalMutableSection:^{
        @strongify(self);

        self.productsResponse = response;
        [self complete];
    }];
}



/**
 * callCompletionCallback
 *
 *
 */

- (void) callCompletionCallback
{
    if (self.blockCompletion != nil)
    {
        @weakify(self);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @strongify(self);
            self.blockCompletion(self.error, self.productsResponse.products, self.productsResponse.invalidProductIdentifiers);
        });
    }
}



@end




