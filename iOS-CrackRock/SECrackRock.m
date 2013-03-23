//
//  SECrackRock.m
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/16/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <StateMachine-GCDThreadsafe/StateMachine.h>
#import <BrynKit/BrynKit.h>
#import <BrynKit/RACSubject+SERACHelpers.h>
#import <libextobjc/EXTScope.h>
#import <Underscore.m/Underscore.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/NSNotificationCenter+RACSupport.h>

#import "SECrackRock.h"
#import "SECrackRockProduct.h"
#import "SECrackRockProduct-Private.h"
#import "SECrackRockProductsRequest.h"

Key(SECrackRockState_Uninitialized, @"uninitialized");
Key(SECrackRockState_Ready, @"ready");
Key(SECrackRockState_Purchasing, @"purchasing");
Key(SECrackRockState_Restoring, @"restoring");
Key(SECrackRockState_Requesting, @"requesting");
Key(SECrackRockState_Error, @"error");

Key(SECrackRockEvent_Purchase, @"purchase");
Key(SECrackRockEvent_Restore, @"restore");
Key(SECrackRockEvent_Error, @"error");
Key(SECrackRockEvent_TransactionComplete, @"transactionComplete");
Key(SECrackRockEvent_RequestProducts, @"requestProducts");


#define _ Underscore


@interface SECrackRock ()
    @property (nonatomic, assign, readwrite) BOOL isCurrentlyRestoringMultiplePurchases;
    @property (nonatomic, assign, readwrite) BOOL restoreWasInitiatedByUser;

    @property (nonatomic, strong, readwrite) SECrackRockProductsRequest *productsRequest;
    @property (nonatomic, strong, readwrite) NSSet *freeProducts;
    @property (nonatomic, strong, readwrite) NSSet *paidProducts;
    @property (nonatomic, strong, readwrite) NSSet *purchasedProducts;
    @property (nonatomic, strong, readwrite) NSSet *products;

    @property (nonatomic, assign, readwrite) dispatch_queue_t queueCritical;

    @property (nonatomic, copy,   readwrite) SECrackRockTransactionResponseBlock blockTransactionCompletion;

    @property (nonatomic, copy, readwrite) NSString *state;
@end

@interface SECrackRock (SKPaymentTransactionObserver) <SKPaymentTransactionObserver>
@end



@interface SECrackRock (StateMachine_Private)
    - (void) initializeStateMachine;
    - (void) requestProducts;
    - (void) transactionComplete;
    - (void) purchase;
    - (void) restore;
    - (void) error;
    - (void) transactionComplete;
    - (void) requestProducts;
@end



@implementation SECrackRock

static int logLevel = LOG_LEVEL_VERBOSE;
+ (int)  ddLogLevel               { return logLevel;  }
+ (void) ddSetLogLevel:(int)level { logLevel = level; }

#pragma mark- StateMachine
#pragma mark-

STATE_MACHINE(^(LSStateMachine *sm) {
    sm.initialState = SECrackRockState_Uninitialized;

    //
    // states
    //
    [sm addState:SECrackRockState_Uninitialized];
    [sm addState:SECrackRockState_Ready];
    [sm addState:SECrackRockState_Purchasing];
    [sm addState:SECrackRockState_Restoring];
    [sm addState:SECrackRockState_Requesting];
    [sm addState:SECrackRockState_Error];

    //
    // transitions
    //

    // request valid IAPs
    [sm when:SECrackRockEvent_RequestProducts     transitionFrom:SECrackRockState_Uninitialized to:SECrackRockState_Requesting];
    [sm when:SECrackRockEvent_RequestProducts     transitionFrom:SECrackRockState_Ready         to:SECrackRockState_Requesting];
    [sm when:SECrackRockEvent_TransactionComplete transitionFrom:SECrackRockState_Requesting    to:SECrackRockState_Ready];

    [sm after:SECrackRockEvent_RequestProducts do:^(SECrackRock *self) {
        @weakify(self);

        // pluck the product IDs
        NSLog(@"self.paidProducts = %@", self.paidProducts);
        NSArray *productIDs = [self.paidProducts
            .rac_sequence.signal
             map:^id(SECrackRockProduct *product) { return product.productID; }]
            .toArray;

        NSSet *productIDsSet = [NSSet setWithArray: productIDs];
        NSLog(@"productIDs = %@", productIDs);
        NSLog(@"[NSSet setWithArray:productIDs] = %@", productIDsSet);

        RACSignal *rac_productsRequest = [SECrackRockProductsRequest rac_productsRequestForProductIDs: productIDsSet
                                                                                            scheduler:[RACScheduler scheduler]];

        [rac_productsRequest subscribeNext:^(RACTuple *response) {
            RACTupleUnpack(NSSet *validProducts, NSSet *invalidProductIDs) = response;
            @strongify(self);
            lllog(Info, @"%d valid product IDs, %d invalid product IDs", validProducts.count, invalidProductIDs.count);

            // update our cached products with the received product info
            for (SKProduct *product in validProducts) {
                [self requestedProductValidated: product];
            }

            // if any of the requested product IDs were not valid, mark them as such
            for (NSString *invalidProductID in invalidProductIDs) {
                [self requestedProductNotValid:invalidProductID];
            }

        } error:^(NSError *error) {
            @strongify(self);
            lllog(Error, @"error = %@", error);
            [self error];
        }];
    }];

    // purchase
    [sm when:SECrackRockEvent_Purchase            transitionFrom:SECrackRockState_Ready to:SECrackRockState_Purchasing];
    [sm when:SECrackRockEvent_TransactionComplete transitionFrom:SECrackRockState_Purchasing to:SECrackRockState_Ready];

    // restore
    [sm when:SECrackRockEvent_Restore             transitionFrom:SECrackRockState_Ready to:SECrackRockState_Restoring];
    [sm when:SECrackRockEvent_TransactionComplete transitionFrom:SECrackRockState_Restoring to:SECrackRockState_Ready];

    // error
    [sm when:SECrackRockEvent_Error transitionFrom:SECrackRockState_Uninitialized to:SECrackRockState_Error];
    [sm when:SECrackRockEvent_Error transitionFrom:SECrackRockState_Ready         to:SECrackRockState_Error];
    [sm when:SECrackRockEvent_Error transitionFrom:SECrackRockState_Purchasing    to:SECrackRockState_Error];
    [sm when:SECrackRockEvent_Error transitionFrom:SECrackRockState_Restoring     to:SECrackRockState_Error];
    [sm when:SECrackRockEvent_Error transitionFrom:SECrackRockState_Requesting    to:SECrackRockState_Error];
    [sm when:SECrackRockEvent_Error transitionFrom:SECrackRockState_Error         to:SECrackRockState_Error];

    [sm before:SECrackRockState_Error do:^(SECrackRock *self) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver: (id<SKPaymentTransactionObserver>)self];
    }];


    //
    // debug logging
    //
    for (id event in sm.events) {
        [sm before:[event name] do:^(SECrackRock *self) {
            lllog(Info, @"STATE TRANSITION: %@", [event name]);
        }];
    }
});



/**!
 * ## Instance methods
 */
#pragma mark- Lifecycle
#pragma mark-


/**!
 * #### initWithFreeProducts:paidProductIDs:
 *
 * @return {id}
 */

- (instancetype) initWithFreeProducts:(NSSet *)freeProducts
                         paidProducts:(NSSet *)paidProducts
{

    self = [super init];
    if (self)
    {
        [self initializeStateMachine];

        _isCurrentlyRestoringMultiplePurchases = NO;
        _restoreWasInitiatedByUser = NO;
        _freeProducts = (freeProducts != nil) ? [freeProducts copy] : [NSSet set];
        _paidProducts = (paidProducts != nil) ? [paidProducts copy] : [NSSet set];

        yssert(_freeProducts != nil, @"_freeProducts is nil.");
        yssert(_paidProducts != nil, @"_paidProducts is nil.");

        RAC(self.products) = [RACSignal combineLatest: @[ [[RACAbleWithStart(self.freeProducts) distinctUntilChanged] notNil],
                                                          [[RACAbleWithStart(self.paidProducts) distinctUntilChanged] notNil], ]
                                               reduce:^NSSet *(NSSet *freeProducts, NSSet *paidProducts){
                                                   return [freeProducts setByAddingObjectsFromSet:paidProducts];
                                               }];
        yssert(self.products != nil, @"self.products is nil.");

        RAC(self.productsByID) = [[RACAbleWithStart(self.products) distinctUntilChanged]
                                      map:^id(NSSet *products) {

                                          NSMutableDictionary *productsByID = [NSMutableDictionary dictionaryWithCapacity:products.count];
                                          for (SECrackRockProduct *product in products) {
                                              productsByID[ product.productID ] = product;
                                          }

                                          return productsByID;
                                      }];
        yssert(self.productsByID != nil, @"self.productsByID is nil.");


        RAC(self.purchasedProducts) = [RACSignal combineLatest:@[ [[[NSNotificationCenter defaultCenter] rac_addObserverForName:SECrackRockNotification_CollectionWasUpdated object:self] startWith:RACDefaultUnit],
                                                               [[RACAbleWithStart(self.productsByID) distinctUntilChanged] notNil], ]
                                                     reduce:^(id notification, NSDictionary *productsByID) {

                                                         lllog(Error, @"purchasedProducts did change (inner) = %@", productsByID);

                                                         NSMutableArray *arr = @[].mutableCopy;
                                                         for (id key in productsByID) {
                                                             SECrackRockProduct *product = productsByID[ key ];
                                                             if (product.hasBeenPurchased) {
                                                                 [arr addObject:product];
                                                             }
                                                         }
                                                         return [NSSet setWithArray:arr];
                                                     }];

        [RACAbleWithStart(self.purchasedProducts) subscribeNext:^(id x) {
            lllog(Error, @"purchasedProducts did change (outer) = %@", x);
        }];

        yssert(self.purchasedProducts != nil, @"self.purchasedProducts is nil.");

        RAC(self.freeAndPurchasedProducts) = [RACSignal combineLatest: @[ [[RACAbleWithStart(self.purchasedProducts) distinctUntilChanged] notNil],
                                                                       [[RACAbleWithStart(self.freeProducts)   distinctUntilChanged] notNil], ]
                                                            reduce:^id (NSSet *purchasedItems, NSSet *freeProducts) {
                                                                yssert_notNilAndIsClass(purchasedItems, NSSet);
                                                                yssert_notNilAndIsClass(freeProducts,   NSSet);

                                                                return [purchasedItems setByAddingObjectsFromSet:freeProducts];
                                                            }];
        yssert(self.freeAndPurchasedProducts != nil, @"self.freeAndPurchasedProducts is nil.");

        // add an observer to monitor the transaction status
        [[SKPaymentQueue defaultQueue] addTransactionObserver: (id<SKPaymentTransactionObserver>)self];

        [self requestProducts];
    }
    return self;
}



/**!
 * #### dealloc
 *
 * @return {void}
 */

- (void) dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver: self];
}



#pragma mark- Public interface
#pragma mark-

#pragma mark Purchase/restore

/**!
 * #### purchase:completion:
 *
 * Attempt to purchase this product.
 *
 * @param {NSString*} productID
 * @return {void}
 */

- (void) purchase: (NSString *)productID
       completion: (SECrackRockTransactionResponseBlock)blockCompletion
{
    yssert(productID != nil);

    SECrackRockProduct *product = self.productsByID[ productID ];
    yssert(product != nil);

    if (product.hasBeenPurchased) {
        if (blockCompletion != nil) {
            blockCompletion(nil);
        }
        return;
    }

    // IAP is not enabled, so bail
    if (NO == [SKPaymentQueue canMakePayments])
    {
        lllog(Error, @"IAP disabled");
        if (blockCompletion != nil) {
            NSError *error = [NSError errorWithDomain: @"com.signalenvelope.SECrackRock.IAPDisabled" code:2
                                             userInfo: @{ @"description": [NSString stringWithFormat:@"In-app purchasing is disabled on this device."] }];
            blockCompletion(error);
        }
        return;
    }

    self.blockTransactionCompletion = blockCompletion;

    // create a payment request using the SKProduct we got back from our SKProductsRequest
    SKPayment *paymentRequest = [SKPayment paymentWithProduct: product.skProduct];

    // request a purchase of the product
    [SKPaymentQueue.defaultQueue addPayment:paymentRequest];
}



/**!
 * #### restoreAllPurchases:
 *
 * Attempt to restore all purchases made with the current apple ID.
 *
 * @param {SECrackRockTransactionResponseBlock} blockTransactionCompletion
 * @return {void}
 */

- (void) restoreAllPurchases:(SECrackRockTransactionResponseBlock)blockTransactionCompletion
{
    // IAP is disabled, so bail
    if (NO == SKPaymentQueue.canMakePayments) {
        if (blockTransactionCompletion != nil) {
            NSError *error = [NSError errorWithDomain: @"com.signalenvelope.SECrackRock.IAPDisabled" code:2
                                             userInfo: @{ @"description": [NSString stringWithFormat:@"In-app purchasing is disabled on this device."] }];

            blockTransactionCompletion(error);
        }
        return;
    }

    self.blockTransactionCompletion            = blockTransactionCompletion;
    self.isCurrentlyRestoringMultiplePurchases = YES;
    self.restoreWasInitiatedByUser             = YES;

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}





//#pragma mark KVO
//
///**
// * keyPathsForValuesAffectingProducts
// */
//
//+ (NSSet *) keyPathsForValuesAffectingProducts
//{
//    return [NSSet setWithArray: @[@"freeProducts", @"paidProducts"]];
//}
//
//
//
///**
// * keyPathsForValuesAffectingProductsByID
// */
//
//+ (NSSet *) keyPathsForValuesAffectingProductsByID
//{
//    return [NSSet setWithArray: @[@"products", @"freeProducts", @"paidProducts"]];
//}
//
//
//
///**
// * keyPathsForValuesAffectingPurchasedItems
// */
//
//+ (NSSet *) keyPathsForValuesAffectingPurchasedItems
//{
//    return [NSSet setWithArray: @[@"products", @"freeProducts", @"paidProducts"]];
//}



/**
 * rac_products
 */

//- (RACSignal *) rac_products
//{
//    return [RACSignal combineLatest: @[
//             RACAbleWithStart(self.freeProducts),
//             RACAbleWithStart(self.paidProducts),
//         ] reduce:^NSSet *(NSSet *freeProducts, NSSet *paidProducts){
//             return [freeProducts setByAddingObjectsFromSet:paidProducts];
//         }];
//}



#pragma mark- Private interface
#pragma mark-

#pragma mark SECrackRockProductsRequest outcomes

/**!
 * #### requestedProductNotValid:
 *
 * The SECrackRockProductsRequest failed and the product is unavailable.
 *
 * @param {NSString*} productID
 * @return {void}
 */

- (void) requestedProductNotValid:(NSString *)productID
{
    yssert(productID != nil, @"productID argument is nil.");
    lllog(Warn, @"Product '%@' unavailable", productID);

    [self willChangeValueForKey:@keypath(self.paidProducts)];

    SECrackRockProduct *product = self.productsByID[ productID ];
    yssert(product != nil, @"product is nil.");

    product.isAvailableInStore = NO;

    [self didChangeValueForKey:@keypath(self.paidProducts)];
    [[NSNotificationCenter defaultCenter] postNotificationName:SECrackRockNotification_CollectionWasUpdated object:self];
}



/**!
 * #### requestedProductValidated:
 *
 * Request for product information to app store servers has returned. If the
 * product was found and is available for purchase, it's handed to this method.
 *
 * @param {SKProduct*} skProduct
 * @return {void}
 */

- (void) requestedProductValidated: (SKProduct *)skProduct
{
    yssert(skProduct != nil, @"skProduct argument is nil.");
    lllog(Info, @"product validated: %@", skProduct);

    [self willChangeValueForKey:@keypath(self.paidProducts)];

    // localize the returned price string
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle        = NSNumberFormatterCurrencyStyle;
    formatter.locale             = skProduct.priceLocale;
    NSString *localizedPrice     = [formatter stringFromNumber:skProduct.price];

    // find the product in our local product list and update it with whatever apple sent
    SECrackRockProduct *productToUpdate = self.productsByID[ skProduct.productIdentifier ];
    yssert(productToUpdate != nil, @"productToUpdate is nil.");

    productToUpdate.productID          = skProduct.productIdentifier;
    productToUpdate.readableName       = skProduct.localizedTitle;
    productToUpdate.productDescription = skProduct.localizedDescription;
    productToUpdate.price              = localizedPrice;
    productToUpdate.skProduct          = skProduct;
    productToUpdate.isAvailableInStore = YES;
//    productToUpdate.productStatus      = [self.purchasedProducts containsObject:productToUpdate.productID]
//                                              ? SECrackRockProductStatusNonfreePurchased
//                                              : SECrackRockProductStatusNonfreeUnpurchased;
    [self didChangeValueForKey:@keypath(self.paidProducts)];
    [[NSNotificationCenter defaultCenter] postNotificationName:SECrackRockNotification_CollectionWasUpdated object:self];
}









#pragma mark Purchase/restore transaction outcomes

/**!
 * #### successfulPurchase:receipt:
 *
 * Purchase request was successful, so unlock the new content for your new
 * customer and notify them that the transaction was successful.
 *
 * @param {NSString*} productID
 * @param {NSData*} transactionReceipt
 * @return {void}
 */

- (void) successfulPurchase: (NSString *)productID
                    receipt: (NSData *)transactionReceipt
{
    yssert(productID != nil, @"productID argument is nil.");
    yssert(transactionReceipt != nil, @"transactionReceipt argument is nil.");

    lllog(Verbose, @"product ID: %@", productID);

//    @weakify(self);
//    [RACScheduler mainThreadScheduler] schedule:^{
//        @strongify(self);


    [self willChangeValueForKey:@keypath(self.purchasedProducts)];
    [self willChangeValueForKey:@keypath(self.productsByID)];

    // save a record that this has been purchased locally to the phone (ends up in NSUserDefaults)
    SECrackRockProduct *product = self.productsByID[ productID ];
    yssert(product != nil);
    product.hasBeenPurchased = YES;

    [self didChangeValueForKey:@keypath(self.productsByID)];

    if (self.blockTransactionCompletion != nil) {
        self.blockTransactionCompletion(nil);
        self.blockTransactionCompletion = nil;
    }

    [self transactionComplete];
    [[NSNotificationCenter defaultCenter] postNotificationName:SECrackRockNotification_CollectionWasUpdated object:self];
}



/**!
 * #### cancelledPurchase:
 *
 * Purchase request was cancelled.
 *
 * @param {NSString*} errorMessage
 * @return {void}
 */

- (void) cancelledPurchase: (NSString *)errorMessage
{
    lllog(Warn, @"error message: %@", errorMessage);

    if (self.blockTransactionCompletion != nil) {
        NSError *error = [NSError errorWithDomain: @"com.signalenvelope.SECrackRock.CancelledTransaction" code:3
                                         userInfo: @{ @"message": errorMessage }];

        self.blockTransactionCompletion(error);
        self.blockTransactionCompletion = nil;
    }

    [self transactionComplete];
    [[NSNotificationCenter defaultCenter] postNotificationName:SECrackRockNotification_CollectionWasUpdated object:self];
}



/**!
 * #### failedPurchase:message:
 *
 * Purchase request failed.
 *
 * @param {NSInteger} errorCode
 * @param {NSString*} errorMessage
 * @return {void}
 */

- (void) failedPurchase: (NSInteger)errorCode
                message: (NSString *)errorMessage {

    lllog(Error, @"error message: %@", errorMessage);

    if (self.blockTransactionCompletion != nil) {
        NSError *error = [NSError errorWithDomain: @"com.signalenvelope.SECrackRock.CancelledTransaction" code:3
                                         userInfo: @{ @"message": errorMessage }];

        self.blockTransactionCompletion(error);
        self.blockTransactionCompletion = nil;
    }

    [self transactionComplete];
    [[NSNotificationCenter defaultCenter] postNotificationName:SECrackRockNotification_CollectionWasUpdated object:self];
}


/**!
 * #### successfulRestore:receipt:
 *
 * Restore request was successful, so unlock the purchased content for your
 * customer and notify them.
 *
 * @param {NSString*} productID
 * @param {NSData*} transactionReceipt
 * @return {void}
 */

- (void) successfulRestore: (NSString *)productID
                   receipt: (NSData *)transactionReceipt {

    yssert(productID != nil, @"productID argument is nil.");
    yssert(transactionReceipt != nil, @"transactionReceipt argument is nil.");
    lllog(Verbose, @"product ID: %@", productID);

    [self willChangeValueForKey:@keypath(self.paidProducts)];

    SECrackRockProduct *product = self.productsByID[ productID ];
    yssert(product != nil);
    product.hasBeenPurchased = YES;

    [self didChangeValueForKey:@keypath(self.paidProducts)];

    if (self.isCurrentlyRestoringMultiplePurchases == NO) {
        if (self.blockTransactionCompletion != nil) {
            self.blockTransactionCompletion(nil);
            self.blockTransactionCompletion = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:SECrackRockNotification_CollectionWasUpdated object:self];
        }

        [self transactionComplete];
    }

    //    // save a record that this has been purchased locally to the phone (ends up in NSUserDefaults)
    //    [self setProductHasBeenPurchased: productID];
    //    [NSNotificationCenter.defaultCenter postNotificationName: SECrackRockNotification_SuccessfulRestore
    //                                                      object: self
    //                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock: self,
    //                                                                 SECrackRockUserInfoKey_ProductID: productID,
    //                                                                 SECrackRockUserInfoKey_Receipt:   transactionReceipt }];

    //    // if it's a single item restore initiated by the user, end the transaction state
    //    if (self.restoreWasInitiatedByUser == YES && self.isCurrentlyRestoringMultiplePurchases == NO) {
    //
    //        BrynFnLog(@"self.restoreWasInitiatedByUser == YES  and  isCurrentlyRestoringMultiplePurchases == NO");
    //
    //        self.restoreWasInitiatedByUser = NO;
    //    }
}


/**!
 * #### successfulMultipleRestoreComplete
 *
 * All restore requests in the transaction queue have succeeded.
 *
 * @return {void}
 */

- (void) successfulMultipleRestoreComplete {
    lllog(Verbose, @"entering method");

    //    // unset flags describing the user-initiated multiple restore state
    //    if (self.restoreWasInitiatedByUser) {
    //        [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeRestore];
    //    }

    self.isCurrentlyRestoringMultiplePurchases = NO;
    self.restoreWasInitiatedByUser = NO;

    if (self.blockTransactionCompletion != nil) {
        self.blockTransactionCompletion(nil);
        self.blockTransactionCompletion = nil;
    }

    [self transactionComplete];
    [[NSNotificationCenter defaultCenter] postNotificationName:SECrackRockNotification_CollectionWasUpdated object:self];
}





/**!
 * #### incompleteRestore
 *
 * Restore queue did not include any transactions, so either the user has not yet made a purchase
 * or the user's prior purchase is unavailable, so notify user to make a purchase within the app.
 * If the user previously purchased the item, they will NOT be re-charged again, but it should
 * restore their purchase.
 *
 * @return {void}
 */

- (void) incompleteRestore {
    lllog(Info, @"incomplete restore");

    if (self.blockTransactionCompletion != nil) {
        NSError *error = [NSError errorWithDomain: @"com.signalenvelope.SECrackRock.IncompleteRestore" code:3
                                         userInfo: @{ @"message": @"Restore queue was empty.  Try purchasing again." }];

        self.blockTransactionCompletion(error);
        self.blockTransactionCompletion = nil;
    }

    [self transactionComplete];
    [[NSNotificationCenter defaultCenter] postNotificationName:SECrackRockNotification_CollectionWasUpdated object:self];
}



/**!
 * #### failedRestore:message:
 *
 * Restore request failed or was cancelled, so notify the user.
 *
 * @param {NSInteger} errorCode
 * @param {NSString*} errorMessage
 * @return {void}
 */

- (void) failedRestore: (NSInteger) errorCode
               message: (NSString *) errorMessage {

    lllog(Error, @"error message: %@", errorMessage);

    if (self.blockTransactionCompletion != nil) {
        NSError *error = [NSError errorWithDomain: @"com.signalenvelope.SECrackRock.FailedRestore" code:3
                                         userInfo: @{ @"message": errorMessage }];

        self.blockTransactionCompletion(error);
        self.blockTransactionCompletion = nil;
    }

    [self transactionComplete];
    [[NSNotificationCenter defaultCenter] postNotificationName:SECrackRockNotification_CollectionWasUpdated object:self];
}







@end

#pragma mark SKPaymentTransactionObserver Methods

@implementation SECrackRock (SKPaymentTransactionObserver)

/**!
 * #### paymentQueue:updatedTransactions:
 *
 * The transaction status of the SKPaymentQueue is sent here.
 *
 * @param {SKPaymentQueue*} queue
 * @param {NSArray*} transactions
 *
 * @return {void}
 */

- (void)    paymentQueue: (SKPaymentQueue *)queue
     updatedTransactions: (NSArray *)transactions
{
    lllog(Verbose, @"%@", transactions);

    yssert(queue != nil, @"queue argument is nil.");
    yssert(transactions != nil, @"transactions argument is nil.");

    NSMutableArray *restores = NSMutableArray.array;

    for (SKPaymentTransaction *transaction in transactions) {

        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing: {
                lllog(Info, @"transaction state = Purchasing");
                // Item is still in the process of being purchased
            } break;

            case SKPaymentTransactionStatePurchased: {
                lllog(Info, @"transaction state = Purchased");
                // Item was successfully purchased!

                // Return transaction data. App should provide user with purchased product.
                [self successfulPurchase: transaction.payment.productIdentifier
                                 receipt: transaction.transactionReceipt];

                // After customer has successfully received purchased content,
                // remove the finished transaction from the payment queue.
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            } break;

            case SKPaymentTransactionStateRestored: {
                lllog(Info, @"transaction state = Restored");
                // Verified that user has already paid for this item.

                [restores addObject:transaction];
            } break;

            case SKPaymentTransactionStateFailed: {
                // Purchase was either cancelled by user or an error occurred.

                if (transaction.error.code == SKErrorPaymentCancelled) {
                    lllog(Info, @"transaction state = Cancelled");

                    [self cancelledPurchase: transaction.error.localizedDescription];
                }
                else {
                    lllog(Info, @"transaction state = Failed");

                    [self failedPurchase: transaction.error.code
                                 message: transaction.error.localizedDescription];
                }

                // Finished transactions should be removed from the payment queue.
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            } break;


            default: {
                // automatically throw an assertion failure exception if the transactionState is not a defined value
                yssert(NO, @"transactionState is an unknown value.");
            } break;
        }
    }


    // process restores separately so that we can accurately set the "restoring
    // multiple purchases" flag if necessary

    if (restores.count > 1)
        self.isCurrentlyRestoringMultiplePurchases = YES;

    for (SKPaymentTransaction *transaction in restores) {
        // Return transaction data. App should provide user with purchased product.
        [self successfulRestore: transaction.payment.productIdentifier
                        receipt: transaction.transactionReceipt];

        // After customer has restored purchased content on this device,
        // remove the finished transaction from the payment queue.
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }

    self.isCurrentlyRestoringMultiplePurchases = NO;
}



/**!
 * #### paymentQueue:removedTransactions:
 *
 * Called when one or more transactions have been removed from the queue.
 *
 * @param {SKPaymentQueue*} queue
 * @param {NSArray*} transactions
 * @return {void}
 */

- (void)   paymentQueue: (SKPaymentQueue *)queue
    removedTransactions: (NSArray *)transactions
{
    lllog(Verbose, @"transactions: %@", transactions);

    yssert(queue != nil, @"queue argument is nil.");
    yssert(transactions != nil, @"transactions argument is nil.");
}



/**!
 * #### paymentQueueRestoreCompletedTransactionsFinished:
 *
 * Called when SKPaymentQueue has finished sending restored transactions.
 *
 * @param {SKPaymentQueue*} queue
 * @return {void}
 */

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    yssert(queue != nil, @"queue argument is nil.");

    lllog(Verbose, @"queue: %@", queue);

    if (queue.transactions.count == 0) {
        lllog(Warn, @"restore queue.transactions count == 0");

        // Queue does not include any transactions, so either user has not yet made a purchase
        // or the user's prior purchase is unavailable, so notify app (and user) accordingly.

        [self incompleteRestore];
    }
    else {
        // Queue does contain one or more transactions, so return transaction data.
        // App should provide user with purchased product.

        lllog(Verbose, @"restore queue.transactions available");

        for (SKPaymentTransaction *transaction in queue.transactions) {
            lllog(Verbose, @"restore queue.transactions - transaction data found");
        }

        lllog(Info, @"multiple restore was successful");
        [self successfulMultipleRestoreComplete];
    }
}



/**!
 * #### paymentQueue:restoreCompletedTransactionsFailedWithError:
 *
 * Called if an error occurred while restoring transactions.
 *
 * @param {SKPaymentQueue*} queue
 * @param {NSError*} error
 *
 * @return {void}
 */

- (void)						   paymentQueue: (SKPaymentQueue *)queue
    restoreCompletedTransactionsFailedWithError: (NSError *)error
{
    lllog(Error, @"error: %@", error);

    yssert(queue != nil, @"queue argument is nil.");
    yssert(error != nil, @"error argument is nil.");

    // Restore was cancelled or an error occurred, so notify user.
    [self failedRestore: error.code
                message: error.localizedDescription];
}





@end







