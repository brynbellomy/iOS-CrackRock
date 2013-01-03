//
//  SECrackRock.m
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/16/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <ObjC-StatelyNotificationRobot/SEStatelyNotificationRobot.h>
#import <BrynKit/BrynKit.h>
#import <Underscore.m/Underscore.h>
#import "SECrackRock.h"
#import "SECrackRockProduct.h"


@interface SECrackRock ()
    @property (nonatomic, assign, readwrite) bool isCurrentlyRestoringMultiplePurchases;
    @property (nonatomic, assign, readwrite) bool restoreWasInitiatedByUser;
    @property (nonatomic, strong, readwrite) SKProductsRequest *productsRequest;
    @property (nonatomic, strong, readwrite) NSMutableSet *activeTransactions;
@end



@implementation SECrackRock


/**!
 * ## Class methods
 */
#pragma mark- Class methods
#pragma mark-



/**!
 * #### sharedInstance
 * 
 * @return {SECrackRock*}
 */

+ (SECrackRock *) sharedInstance {
  static SECrackRock *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[SECrackRock alloc] init];
  });
  
  return instance;
}



/**!
 * ## Instance methods
 */
#pragma mark- Lifecycle
#pragma mark-


/**!
 * #### startMonitoringTransactions
 * 
 * @return {bool}
 */

- (bool) startMonitoringTransactions {
  
    // set up our two observed states
    [SEStatelyNotificationRobot.sharedRobot changeStateOf: ObservableState_Transaction
                                                       to: SECrackRockTransactionStateAsleep];
  
    [SEStatelyNotificationRobot.sharedRobot changeStateOf: ObservableState_ProductsRequest
                                                       to: SECrackRockProductsRequestStateUnfinished];
  
    // if IAP is disabled on this device, return immediately
    if (NO == [SKPaymentQueue canMakePayments]) {
        BrynFnLog(@"IAP Disabled");
        return NO;
    }
    
    // add an observer to monitor the transaction status
    [[SKPaymentQueue defaultQueue] addTransactionObserver: self];
    
    
    // get definitions for our free and paid products from the dataSource
    self.freeProducts = [self.dataSource freeProducts];
    self.paidProducts = [self.dataSource paidProducts];
    
    
    // create a list of product IDs sorted into: 1) free, 2) purchased, and
    // finally, 3) not-yet-purchased products
    self.sortedProductIDs = [self createSortedProductIDList];
    
    // create a dictionary of products keyed by productID
    self.productsByID = [self createProductDictionary];
    
    
    // *** request IAP product info and availability *** //
    
    
    // if there are no paid products, just fire the "finished gathering paid product info" handler and bail
    if (self.paidProducts == nil || self.paidProducts.count <= 0) {
        BrynFnLog(@"No paid products"); // @@REMOVE
        [self didFinishPreparingProductInfo:YES];
        return YES;
    }
    
    
    // if there are actual, non-free in-app purchases to retrieve from apple, then start retrieving them
    NSMutableSet *productsForRequest = [NSMutableSet setWithCapacity:self.paidProducts.count];
    for (SECrackRockProduct *product in self.paidProducts) {
        [productsForRequest addObject: product.productID];
    }
    
    [self storeTransactionWillBegin:SECrackRockStoreTransactionTypeProductsRequest];
    
    // if there's an immediate failure (e.g. if IAP is turned off on the user's
    // device), call the "didFinish" method immediately but flag the error
    if (NO == [self requestProducts:productsForRequest]) {
        BrynFnLog(@"IAP failure"); // @@REMOVE
        [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeProductsRequest];
        [self didFinishPreparingProductInfo:NO];
        return NO;
    }
    
    return YES;
}



/**!
 * #### stopMonitoringTransactions
 * 
 * @return {void}
 */

- (void) stopMonitoringTransactions {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver: self];
}




/**!
 * #### init
 * 
 * @return {id}
 */

- (id) init {
    self = [super init];
    if (self) {
        _isCurrentlyRestoringMultiplePurchases = NO;
        _restoreWasInitiatedByUser = NO;
        _activeTransactions = [NSMutableSet set];
    }
    return self;
}


/**!
 * #### dealloc
 * 
 * @return {void}
 */

- (void) dealloc {
  
  // Unset the SKProductsRequest's delegate property (if it points to self) before
  // we dealloc (otherwise we risk an EXC_BAD_ACCESS)
  if (self.productsRequest != nil) {
    if (self.productsRequest.delegate == self)
      self.productsRequest.delegate = nil;
    
    [self.productsRequest cancel];
    self.productsRequest = nil;
  }
  
  // Unset self as an observer of the default payment queue (same issue as above
  // with unsetting delegates).
  [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
  
}



#pragma mark- Helpers for determining which items have been purchased
#pragma mark-

/**!
 * #### purchasedItems
 *
 * Property getter that lazy-loads the list of purchased items from
 * NSUserDefaults.
 * 
 * @return {NSMutableArray*}
 */

- (NSMutableArray *) purchasedItems {
    if (_purchasedItems == nil) {
        _purchasedItems = [[NSUserDefaults standardUserDefaults] objectForKey: SECrackRockUserDefaultsKey_purchasedItems];
        
        // if the purchased items array has never been written to disk, create an empty array and save it
        if (_purchasedItems == nil || [_purchasedItems isKindOfClass:[NSMutableArray class]] == NO) {
            _purchasedItems = [NSMutableArray array];
            [[NSUserDefaults standardUserDefaults] setObject:_purchasedItems forKey:SECrackRockUserDefaultsKey_purchasedItems];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    return _purchasedItems;
}



/**!
 * #### hasProductBeenPurchased:
 *
 * Determine if a product has been purchased or not (based on the
 * possibly-incorrect record of purchased items stored locally on the user's
 * phone using NSUserDefaults).
 * 
 * @param {NSString*} productID
 * @return {bool}
 */

+ (bool) hasProductBeenPurchased: (NSString *)productID {
    NSAssert(productID != nil, @"product ID argument is nil.");
  
    return [[self sharedInstance].purchasedItems containsObject: productID];
}



/**!
 * #### hasProductBeenPurchased:
 *
 * Determine if a product has been purchased or not (based on the
 * possibly-incorrect record of purchased items stored locally on the user's
 * phone using NSUserDefaults).
 * 
 * @param {NSString*} productID
 * @return {bool}
 */

- (bool) hasProductBeenPurchased: (NSString *)productID {
    NSAssert(productID != nil, @"product ID argument is nil.");
  
    return [self.purchasedItems containsObject: productID];
}



/**!
 * #### setProduct:hasBeenPurchased:
 *
 * Set whether or not a given product has been purchased (written into the
 * locally-cached record of purchased items in NSUserDefaults).
 * 
 * @param {NSString*} productID
 * @param {bool} hasBeenPurchased
 * @return {void}
 */

- (void) setProduct:(NSString *)productID hasBeenPurchased:(bool)hasBeenPurchased {
    NSAssert(productID != nil, @"productID argument is nil.");
    NSAssert(self.productsByID[ productID ] != nil, @"No known product for the given productID.");
    
    if (hasBeenPurchased == YES)
        [self.purchasedItems addObject: productID];
    else
        [self.purchasedItems removeObject: productID];
    
    // make a note that the product has been purchased in the NSUserDefaults database
    {
        NSString *userDefaultsKey = (self.userDefaultsKey != nil
                                        ? self.userDefaultsKey
                                        : [NSString stringWithFormat:@"%@-%@", SECrackRockUserDefaultsKey_purchasedItems, NSBundle.mainBundle.bundleIdentifier]);
        
        BrynFnLog(@"userDefaultsKey = %@", userDefaultsKey);
        [[NSUserDefaults standardUserDefaults] setObject: self.purchasedItems forKey: userDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
    // also update the product in the productsByID dictionary for consistency's sake
    {
        SECrackRockProduct *product = self.productsByID[ productID ];
        product.purchaseStatus = (hasBeenPurchased ? SECrackRockPurchaseStatusNonfreePurchased
                                                   : SECrackRockPurchaseStatusNonfreeUnpurchased);
    }
}




#pragma mark- Transaction state toggle
#pragma mark-

/**!
 * #### storeTransactionWillBegin:
 * 
 * @param {SECrackRockStoreTransactionType} type
 * @return {void}
 */

- (void) storeTransactionWillBegin:(SECrackRockStoreTransactionType)type {
    BrynFnLog(@"type = %@", (type == 2 ? @"purchase" : (type == 4 ? @"restore" : @"products request")));
    NSAssert(NO == [self.activeTransactions containsObject:@(type)], @"A transaction of the given type is already underway. (type = %d)", type);
    
    bool wasEmpty = (self.activeTransactions.count <= 0);
    
    [self.activeTransactions addObject:@(type)];
    
    if (wasEmpty) {
        [SEStatelyNotificationRobot.sharedRobot changeStateOf: ObservableState_Transaction
                                                           to: SECrackRockTransactionStateInProgress
                                                    stateInfo: @{ SECrackRockUserInfoKey_CrackRock:       self,
                                                                  SECrackRockUserInfoKey_TransactionType: @(type) }];
    }
}



/**!
 * #### storeTransactionDidEnd:
 * 
 * @param {SECrackRockStoreTransactionType} type
 * @return {void}
 */

- (void) storeTransactionDidEnd:(SECrackRockStoreTransactionType)type {
    BrynFnLog(@"type = %@", (type == 2 ? @"purchase" : (type == 4 ? @"restore" : @"products request")));
    
    if ([self.activeTransactions containsObject:@(type)])
        [self.activeTransactions removeObject:@(type)];
    
    if (self.activeTransactions.count <= 0) {
        [SEStatelyNotificationRobot.sharedRobot changeStateOf: ObservableState_Transaction
                                                           to: SECrackRockTransactionStateAsleep
                                                    stateInfo: @{ SECrackRockUserInfoKey_CrackRock:       self,
                                                                  SECrackRockUserInfoKey_TransactionType: @(type) }];
    }
}



#pragma mark- Purchase/restore/request outcomes
#pragma mark-

/**!
 * #### requestedProductValidated:productID:name:price:description:
 *
 * Request for product information to app store servers has returned. If the
 * product was found and is available for purchase, it's handed to this method.
 * 
 * @param {SKProduct*} skProduct
 * @param {NSString*} productID
 * @param {NSString*} productName
 * @param {NSString*} productPrice
 * @param {NSString*} productDescription
 * @return {void}
 */

- (void) requestedProductValidated: (SKProduct *)skProduct
                         productID: (NSString *)productID
                              name: (NSString *)productName
                             price: (NSString *)productPrice
                       description: (NSString *)productDescription {
    
    NSAssert(skProduct != nil, @"skProduct argument is nil.");
    NSAssert(productID != nil, @"productID argument is nil.");
    
    BrynFnLog(@"product ID: %@", productID);
    
    // find the product in our local product list and update it with whatever apple sent
    SECrackRockProduct *updatedProduct = self.productsByID[ productID ];
    NSAssert(updatedProduct != nil, @"updatedProduct is nil.");
    
//    if (updatedProduct == nil) {
//        // the productID returned by the app store servers couldn't
//        // be found in the productList (this would be bizarre)
//        NSLog(@"(SECrackRock) requestedProductValidated: Product not in productList");
//        [self requestedProductNotValid:productID];
//        return;
//    }
    
    if (productPrice != nil)       updatedProduct.price = productPrice;
    if (productName != nil)        updatedProduct.readableName = productName;
    if (productDescription != nil) updatedProduct.productDescription = productDescription;
    
    updatedProduct.skProduct = skProduct;
    updatedProduct.isAvailableInStore = YES;
    updatedProduct.purchaseStatus = ([self hasProductBeenPurchased:productID]
                                     ? SECrackRockPurchaseStatusNonfreePurchased
                                     : SECrackRockPurchaseStatusNonfreeUnpurchased);
}



/**!
 * #### requestedProductNotValid:
 * 
 * @param {NSString*} productID
 * @return {void}
 */

- (void) requestedProductNotValid:(NSString *)productID {
    NSAssert(productID != nil, @"productID argument is nil.");
    
    BrynFnLog(@"Product '%@' unavailable", productID);
    
    // the request failed and the product is unavailable
    
    SECrackRockProduct *product = self.productsByID[ productID ];
    NSAssert(product != nil, @"product is nil.");
    
    product.isAvailableInStore = NO;
    product.purchaseStatus = SECrackRockPurchaseStatusError;
}



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
                    receipt: (NSData *)transactionReceipt {
    
    NSAssert(productID != nil, @"productID argument is nil.");
    NSAssert(transactionReceipt != nil, @"transactionReceipt argument is nil.");
    
    BrynFnLog(@"product ID: %@", productID);
    
    // save a record that this has been purchased locally to the phone (ends up in NSUserDefaults)
    [self setProduct:productID hasBeenPurchased:YES];
    [NSNotificationCenter.defaultCenter postNotificationName: SECrackRockNotification_SuccessfulPurchase
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                           SECrackRockUserInfoKey_ProductID : productID,
                             SECrackRockUserInfoKey_Receipt : transactionReceipt }];
    
    [self storeTransactionDidEnd:SECrackRockStoreTransactionTypePurchase];
}



/**!
 * #### successfulRestore:receipt:
 *
 * Restore request was successful, so unlock the purchased content for your
 * customer and notify them that the transaction was successful.
 * 
 * @param {NSString*} productID
 * @param {NSData*} transactionReceipt
 * @return {void}
 */

- (void) successfulRestore: (NSString *)productID
                   receipt: (NSData *)transactionReceipt {
  
  NSAssert(productID != nil, @"productID argument is nil.");
  NSAssert(transactionReceipt != nil, @"transactionReceipt argument is nil.");
  
  BrynFnLog(@"product ID: %@", productID);
  
  // save a record that this has been purchased locally to the phone (ends up in NSUserDefaults)
  [self setProduct:productID hasBeenPurchased:YES];
  [NSNotificationCenter.defaultCenter postNotificationName: SECrackRockNotification_SuccessfulRestore
                                                    object: self
                                                  userInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                               SECrackRockUserInfoKey_ProductID : productID,
                                                               SECrackRockUserInfoKey_Receipt : transactionReceipt }];

  
  // if it's a single item restore initiated by the user, end the transaction state
  if    (self.restoreWasInitiatedByUser == YES
      && self.isCurrentlyRestoringMultiplePurchases == NO) {
    BrynFnLog(@"self.restoreWasInitiatedByUser == YES  and  isCurrentlyRestoringMultiplePurchases == NO");
    
    self.restoreWasInitiatedByUser = NO;
    [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeRestore];
  }
}



/**!
 * #### successfulMultipleRestoreComplete
 *
 * All restore requests in the transaction queue have succeeded.
 * 
 * @return {void}
 */

- (void) successfulMultipleRestoreComplete {
  BrynFnLog(@"entering method");
  
  // unset flags describing the user-initiated multiple restore state
  if (self.restoreWasInitiatedByUser) {
    [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeRestore];
  }
  self.isCurrentlyRestoringMultiplePurchases = NO;
  self.restoreWasInitiatedByUser = NO;
  
  [NSNotificationCenter.defaultCenter postNotificationName: SECrackRockNotification_MultipleRestoreComplete
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self }];
}



/**!
 * #### cancelledPurchase:
 *
 * Purchase request was cancelled.
 * 
 * @param {NSString*} errorMessage
 * @return {void}
 */

- (void) cancelledPurchase: (NSString *)errorMessage {
  BrynFnLog(@"error message: %@", errorMessage);
  
  [self storeTransactionDidEnd:SECrackRockStoreTransactionTypePurchase];
  [NSNotificationCenter.defaultCenter postNotificationName: SECrackRockNotification_CancelledPurchase
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                                 SECrackRockUserInfoKey_Message : errorMessage }];
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
  
  BrynFnLog(@"error message: %@", errorMessage);
  
  [self storeTransactionDidEnd:SECrackRockStoreTransactionTypePurchase];
  
  [NSNotificationCenter.defaultCenter postNotificationName: SECrackRockNotification_FailedPurchase
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                                 SECrackRockUserInfoKey_ErrorCode : @(errorCode),
                                                                 SECrackRockUserInfoKey_Message : errorMessage }];
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
  BrynFnLog(@"incomplete restore");
  
  [self storeTransactionDidEnd: SECrackRockStoreTransactionTypeRestore];
  
  [NSNotificationCenter.defaultCenter postNotificationName: SECrackRockNotification_IncompleteRestore
                                                    object: self
                                                  userInfo: @{ SECrackRockUserInfoKey_CrackRock: self }];
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
    
    BrynFnLog(@"error message: %@", errorMessage);
    
    [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeRestore];
    
    [NSNotificationCenter.defaultCenter postNotificationName: SECrackRockNotification_FailedRestore
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock: self,
                            SECrackRockUserInfoKey_ErrorCode: @(errorCode),
                              SECrackRockUserInfoKey_Message:   errorMessage }];
}



#pragma mark- Product data
#pragma mark-

/**!
 * #### createSortedProductIDList
 *
 * Creates an array of all visible products (free and purchaseable) in the order
 * that they ought to appear in the springboard view.
 * 
 * @return {NSMutableArray*}
 */

- (NSMutableArray *) createSortedProductIDList {
  
    NSMutableArray *productList = [NSMutableArray arrayWithCapacity:(self.freeProducts.count + self.paidProducts.count)];
    
    // Populate the arrays that the SEBlingLord view draws on for its contents:
    
    // ... first add all of the free/default products to the list
    [productList addObjectsFromArray: _array(self.freeProducts).pluck(@"productID").unwrap];
//    for (SECrackRockProduct *product in self.freeProducts) {
//        [productList addObject: product.productID];
//    }
    
    USArrayWrapper *_paidProductList = _array(self.paidProducts);
    // ... then add all of the purchased products to the list
    [productList addObjectsFromArray:
        _paidProductList
            .filter(^BOOL (SECrackRockProduct *product) { return [self hasProductBeenPurchased: product.productID]; })
            .pluck(@"productID")
            .unwrap];
//    for (SECrackRockProduct *product in self.paidProducts) {
//        if ([self hasProductBeenPurchased: product.productID] == YES)
//            [productList addObject: product.productID];
//    }
    
    // ... finally add all of the unpurchased products to the list
    [productList addObjectsFromArray:
        _paidProductList
            .filter(^BOOL (SECrackRockProduct *product) { return NO == [self hasProductBeenPurchased: product.productID]; })
            .pluck(@"productID")
            .unwrap];
//    for (SECrackRockProduct *product in self.paidProducts) {
//        if ([self hasProductBeenPurchased: product.productID] == NO)
//            [productList addObject: product.productID];
//    }
    
    return productList;
}


/**!
 * #### createProductDictionary
 *
 * Creates a dictionary of all products (free and purchaseable) keyed by product ID.
 * 
 * @return {NSMutableDictionary*}
 */

- (NSMutableDictionary *) createProductDictionary {
    
    NSMutableDictionary *productDict = [NSMutableDictionary dictionaryWithCapacity:(self.freeProducts.count + self.paidProducts.count)];
    
    // ... first add all of the free/default products
    for (SECrackRockProduct *product in self.freeProducts) {
        product.purchaseStatus = SECrackRockPurchaseStatusFree;
        productDict[ product.productID ] = product;
    }
    
    // ... then add all of the paid products
    for (SECrackRockProduct *product in self.paidProducts) {
        product.purchaseStatus = SECrackRockPurchaseStatusUnknown;
        product.isAvailableInStore = NO; // set to NO until we get confirmation of YES from apple
        productDict[ product.productID ] = product;
    }
    
    return productDict;
}



#pragma mark- Purchasing/restoring convenience methods
#pragma mark-

/**!
 * #### didFinishPreparingProductInfo:
 * 
 * @param {bool} success
 * 
 * @return {void}
 */

- (void) didFinishPreparingProductInfo:(bool)success {
    BrynFnLog(@"success: %@", @(success));
    
    [SEStatelyNotificationRobot.sharedRobot changeStateOf: ObservableState_ProductsRequest
                                                       to: SECrackRockProductsRequestStateFinished
                                                stateInfo: @{ SECrackRockUserInfoKey_CrackRock: self,
                                                              SECrackRockUserInfoKey_Success:   @(success) }];
}





#pragma mark- Public methods for purchasing/restoring
#pragma mark-

/**!
 * #### tryToPurchaseProduct:
 *
 * Attempt to purchase a product with a given product ID.
 * 
 * @param {NSString*} productID
 * @return {bool}
 */

- (bool) tryToPurchaseProduct:(NSString *)productID {
    BrynFnLog(@"product ID: %@", productID);
    
    NSAssert(productID != nil, @"productID argument is nil.");
    
    // First, ensure that the SKProduct that was retrieved by the requestProduct
    // method in the viewWillAppear event is valid before trying to purchase it
    
    SECrackRockProduct *product = self.productsByID[ productID ];
    
    if (product == nil || product.isAvailableInStore == NO || product.skProduct == nil) {
        BrynFnLog(COLOR_ERROR(@"product '%@' not found"), productID);
        return NO;
    }
    
    // IAP is enabled on this device.  proceed with purchase.
    if (SKPaymentQueue.canMakePayments) {
        [self storeTransactionWillBegin:SECrackRockStoreTransactionTypePurchase];
        
        // create a payment request using the SKProduct we got back from our SKProductsRequest
        SKPayment *paymentRequest = [SKPayment paymentWithProduct:product.skProduct];
        
        // request a purchase of the product
        [SKPaymentQueue.defaultQueue addPayment:paymentRequest];
        
        return YES;
    }
    else {
        BrynFnLog(COLOR_ERROR(@"IAP disabled"));
        return NO;
    }
}



/**!
 * #### tryToRestorePurchase:
 *
 * Attempt to restore a customer's previous non-consumable or subscription
 * In-App Purchase with a given product ID.  Required if a user reinstalled app
 * on same device or another device.
 * 
 * @param {NSString*} productID
 * 
 * @return {bool}
 */

- (bool) tryToRestorePurchase: (NSString *)productID {

    NSAssert(productID != nil, @"productID argument is nil.");
    BrynFnLog(@"product ID: %@", productID);
  
//  [self storeTransactionWillBegin:SECrackRockStoreTransactionTypeRestore];
//  
//  //@@TODO: do we need to verify that the productID is valid as we do above in -tryToPurchaseProduct: ?
//  
//  // call restore method
//  //@@TODO: need to figure out the correct way of making this request specific to a single product ID
//  bool success = [[EBPurchase sharedInstance] restorePurchase];
//  
//  // if things didn't work out, pop out of the "in transaction" state as soon as possible
//  if (success == NO)
//    [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeRestore];
//  
//  return success;
  
  return NO;
}



/**!
 * #### tryToRestoreAllPurchases
 *
 * Attempt to restore all purchases made with the current apple ID.
 * 
 * @return {bool}
 */

- (bool) tryToRestoreAllPurchases {
    BrynFnLog(@"entering method");
    
    // IAP is enabled on this device.  proceed with restore.
    if ([SKPaymentQueue canMakePayments]) {
        
        [self storeTransactionWillBegin:SECrackRockStoreTransactionTypeRestore];
        self.isCurrentlyRestoringMultiplePurchases = YES;
        self.restoreWasInitiatedByUser = YES;
        
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        
        return YES;
    }
    
    // IAP is disabled
    else
        return NO;
}



#pragma mark- Requesting info
#pragma mark-

/**!
 * #### requestProduct:
 * 
 * @param {NSString*} productID
 * 
 * @return {bool}
 */

- (bool) requestProduct:(NSString *)productID {
    BrynFnLog(@"product ID: %@", productID);
    NSAssert(productID != nil, @"productID argument is nil.");
  
    return [self requestProducts:[NSSet setWithObject:productID]];
}



/**!
 * #### requestProducts:
 * 
 * @param {NSSet*} productIDs
 * 
 * @return {bool}
 */

- (bool) requestProducts:(NSSet *)productIDs {
    BrynFnLog(@"product IDs: %@", productIDs);
    
    NSAssert(productIDs != nil, @"productIDs argument is nil.");
    NSAssert(productIDs.count > 0, @"productIDs argument is empty.");
    
    
    // IAP is enabled on this device.  proceed with products request.
    if ([SKPaymentQueue canMakePayments]) {
        
        // cancel any existing, pending (possibly hung) request
        if (self.productsRequest != nil) {
            [self.productsRequest cancel];
            self.productsRequest = nil;
        }
        
        // initiate new product request for specified productIDs
        self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIDs];
        self.productsRequest.delegate = self;
        [self.productsRequest start];
        
        return YES;
    }
    
    // IAP is disabled
    else {
        BrynFnLog(COLOR_ERROR(@"IAP Disabled"));
        return NO;
    }
}



#pragma mark -
#pragma mark SKProductsRequestDelegate Methods

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
  
    BrynFnLog(@"%d requested products available", response.products.count);
    
    NSAssert(request != nil, @"request argument is nil.");
    NSAssert(response != nil, @"response argument is nil.");
    
    
    // release our reference to the SKProductsRequest
    self.productsRequest = nil;
    
    // update our cached products with the received product info
    for (SKProduct *product in response.products) {
        NSAssert(self.productsByID[ product.productIdentifier ] != nil, @"SKProductsRequest was returned a productID that was not requested.");
        
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.locale = product.priceLocale;
        NSString *currencyString = [formatter stringFromNumber:product.price];
        
        
        [self requestedProductValidated: product
                              productID: product.productIdentifier
                                   name: product.localizedTitle
                                  price: currencyString
                            description: product.localizedDescription];
    }
    
    // if any of the requested product IDs were not valid, mark them as such
    BrynFnLog(@"%d invalid product IDs", response.invalidProductIdentifiers.count);
    for (NSString *invalidProductID in response.invalidProductIdentifiers) {
        [self requestedProductNotValid:invalidProductID];
    }
    
    // signal that we have processed all of the information from the SKProductsRequest
    [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeProductsRequest];
    [self didFinishPreparingProductInfo:YES];
}



#pragma mark -
#pragma mark SKPaymentTransactionObserver Methods

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

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    BrynFnLog(@"%@", transactions);
    
    NSAssert(queue != nil, @"queue argument is nil.");
    NSAssert(transactions != nil, @"transactions argument is nil.");
  
    
    NSMutableArray *restores = [NSMutableArray array];
    
    for (SKPaymentTransaction *transaction in transactions) {
        
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing: {
                BrynFnLog(@"transaction state = Purchasing");
                // Item is still in the process of being purchased
            } break;
                
            case SKPaymentTransactionStatePurchased: {
                BrynFnLog(@"transaction state = Purchased");
                // Item was successfully purchased!
                
                // Return transaction data. App should provide user with purchased product.
                [self successfulPurchase: transaction.payment.productIdentifier
                                 receipt: transaction.transactionReceipt];
                
                // After customer has successfully received purchased content,
                // remove the finished transaction from the payment queue.
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            } break;
                
            case SKPaymentTransactionStateRestored: {
                BrynFnLog(@"transaction state = Restored");
                // Verified that user has already paid for this item.
                // Ideal for restoring item across all devices of this customer.
                
                [restores addObject:transaction];
            } break;
                
            case SKPaymentTransactionStateFailed: {
                // Purchase was either cancelled by user or an error occurred.
                
                if (transaction.error.code == SKErrorPaymentCancelled) {
                    BrynFnLog(@"transaction state = Cancelled");
                    
                    [self cancelledPurchase:transaction.error.localizedDescription];
                }
                else {
                    BrynFnLog(@"transaction state = Failed");
                    
                    [self failedPurchase:transaction.error.code message:transaction.error.localizedDescription];
                }
                
                // Finished transactions should be removed from the payment queue.
                [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
            } break;
                
                
            default: {
                // automatically throw an assertion failure exception if the transactionState is not a defined value
                NSAssert(NO, @"transactionState is an unknown value.");
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

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
    BrynFnLog(@"transactions: %@", transactions);
    
    NSAssert(queue != nil, @"queue argument is nil.");
    NSAssert(transactions != nil, @"transactions argument is nil.");
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
    NSAssert(queue != nil, @"queue argument is nil.");
    
    BrynFnLog(@"queue: %@", queue);
    
    if (queue.transactions.count == 0) {
        BrynFnLog(@"restore queue.transactions count == 0");
        
        // Queue does not include any transactions, so either user has not yet made a purchase
        // or the user's prior purchase is unavailable, so notify app (and user) accordingly.
        
        [self incompleteRestore];
    }
    else {
        // Queue does contain one or more transactions, so return transaction data.
        // App should provide user with purchased product.
        
        BrynFnLog(@"restore queue.transactions available");
        
        for (SKPaymentTransaction *transaction in queue.transactions) {
            BrynFnLog(@"restore queue.transactions - transaction data found");
        }
        
        BrynFnLog(@"multiple restore was successful");
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

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    BrynFnLog(@"error: %@", error);
    
    NSAssert(queue != nil, @"queue argument is nil.");
    NSAssert(error != nil, @"error argument is nil.");
    
    // Restore was cancelled or an error occurred, so notify user.
    [self failedRestore:error.code message:error.localizedDescription];
}





@end






