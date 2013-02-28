//
//  SECrackRockProductsRequest.m
//  iOS-CrackRock
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 illumntr. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import <StateMachine/StateMachine.h>
#import <BrynKit/BrynKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "SECrackRockProductsRequest.h"
#import "SECrackRockProduct.h"
#import "SECrackRockProduct-Private.h"
#import "SECrackRockCommon.h"

@interface SECrackRockProductsRequest ()
    @property (nonatomic, assign, readwrite) dispatch_queue_t queue;
    @property (nonatomic, assign, readwrite) dispatch_queue_t parentQueue;

    @property (nonatomic, strong, readwrite) NSSet *productIDs;

    @property (nonatomic, strong, readwrite) SKProductsRequest  *productsRequest;
    @property (nonatomic, strong, readwrite) SKProductsResponse *productsResponse;

    @property (nonatomic, copy,   readwrite) ProductsRequestResponseBlock blockCompletion;
@end

@interface SECrackRockProductsRequest (StateMachine_Private)
- (void) initializeStateMachine;
- (void) complete;
@end

@implementation SECrackRockProductsRequest




STATE_MACHINE(^(LSStateMachine *sm) {
    sm.initialState = @"ready";

    //
    // states
    //
    [sm addState:@"ready"];
    [sm addState:@"running"];
    [sm addState:@"complete"];
    [sm addState:@"cancelled"];


    //
    // transitions
    //
    [sm when: @"start" transitionFrom:@"ready" to:@"running"];

    [sm after:@"start" do:^(SECrackRockProductsRequest *self) {
        if (self.productIDs == nil || self.productIDs.count <= 0) {
            lllog(Warn, @"No paid products");
        }

        // if there are actual, non-free in-app purchases to retrieve from apple, then start retrieving them
        else {
            [self performStoreKitRequest];
        }
    }];



    [sm when:  @"complete" transitionFrom:@"running" to:@"completed"];

    [sm before:@"complete" do:^(SECrackRockProductsRequest *self) {
        lllog(Info, @"%d requested products available", self.productsResponse.products.count);

        yssert(self.productsRequest  != nil, @"request argument is nil.");
        yssert(self.productsResponse != nil, @"response argument is nil.");

        // release our reference to the SKProductsRequest
        self.productsRequest = nil;

        // call the completion block
        if (self.blockCompletion != nil) {
            self.blockCompletion(nil, self.productsResponse.products, self.productsResponse.invalidProductIdentifiers);
        }
    }];



    [sm when:  @"cancel" transitionFrom:@"running" to:@"cancelled"];

    [sm before:@"cancel" do:^(SECrackRockProductsRequest *self) {
        [self.productsRequest cancel];
    }];

});



#pragma mark- Lifecycle
#pragma mark-

- (id) initWithProductIDs:(NSSet *)productIDs
                    queue:(dispatch_queue_t)parentQueue
               completion:(ProductsRequestResponseBlock)blockCompletion
{
    self = [super init];

    if (self) {
        [self initializeStateMachine];

        _parentQueue = parentQueue;

        _queue = dispatch_queue_create("com.signalenvelope.SECrackRockProductsRequest", 0);
        dispatch_set_target_queue(_queue, _parentQueue);

        _productIDs = productIDs;
        _blockCompletion = blockCompletion;
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

- (void) performStoreKitRequest {
    lllog(Verbose, @"productIDs: %@", self.productIDs);

    yssert(self.productIDs != nil, @"self.productIDs is nil.");
    yssert(self.productIDs.count > 0, @"self.productIDs is empty.");


    // IAP is enabled on this device.  proceed with products request.
    if ([SKPaymentQueue canMakePayments]) {

        // cancel any existing, pending (possibly hung) request
        if (self.productsRequest != nil) {
            [self.productsRequest cancel];
            self.productsRequest = nil;
        }

        // initiate new product request for specified productIDs
        self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:self.productIDs];
        self.productsRequest.delegate = self;
        [self.productsRequest start];
    }

    // IAP is disabled
    else {
        lllog(Error, @"IAP Disabled");

        if (self.blockCompletion != nil) {
            NSError *error = [NSError errorWithDomain: @"com.signalenvelope.SECrackRock" code: 1
                                             userInfo: @{ @"description": @"In-app purchasing is disabled on this device." }];

            self.blockCompletion(error, nil, nil);
        }
    }
}



/**!
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
      didReceiveResponse: (SKProductsResponse *)response {

    self.productsRequest = request;
    self.productsResponse = response;

    [self complete];
}



@end




