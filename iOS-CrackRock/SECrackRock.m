//
//  SECrackRock.m
//  SECrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/16/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "SECrackRock.h"
#import "SECrackRockProduct.h"
#import <iOS-StatefulNotifications/SEStatelyNotificationRobot.h>
#import "Bryn.h"


@interface SECrackRock ()
#if DEBUG
{
  bool _storeTransactionIsUnderway;
  bool _isMonitoringTransactions;
}
#endif

  @property (nonatomic, assign, readwrite) bool isCurrentlyRestoringMultiplePurchases;
  @property (nonatomic, assign, readwrite) bool restoreWasInitiatedByUser;
  @property (nonatomic, strong, readwrite) SKProductsRequest *productsRequest;
@end



@implementation SECrackRock

@synthesize dataSource = _dataSource;
@synthesize sortedProductIDs = _sortedProductIDs;
@synthesize productsByID = _productsByID;
@synthesize purchasedItems = _purchasedItems;
@synthesize freeProducts = _freeProducts;
@synthesize paidProducts = _paidProducts;
@synthesize isCurrentlyRestoringMultiplePurchases = _isCurrentlyRestoringMultiplePurchases;
@synthesize restoreWasInitiatedByUser = _restoreWasInitiatedByUser;
@synthesize productsRequest = _productsRequest;




#pragma mark- Class methods
#pragma mark-

+ (SECrackRock *) sharedInstance {
  static SECrackRock *instance = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[SECrackRock alloc] init];
  });
  
  return instance;
}



#pragma mark- Lifecycle
#pragma mark-

- (bool) startMonitoringTransactions {
#if DEBUG
  NSAssert(_isMonitoringTransactions == NO, @"Transactions are already being monitored, or SECrackRock is in an inconsistent state.");
  _isMonitoringTransactions = YES;
#endif
  NSLog(@"(SECrackRock) startMonitoringTransactions");
  
  // set up our two observed states
  [[SEStatelyNotificationRobot sharedRobot] changeStateOf: SECrackRockState_TransactionState
                                                       to: SECrackRockTransactionStateAsleep];
  
  [[SEStatelyNotificationRobot sharedRobot] changeStateOf: SECrackRockState_ProductsRequestState
                                                       to: SECrackRockProductsRequestStateUnfinished];
  
  // if IAP is disabled on this device, return immediately
  if (NO == [SKPaymentQueue canMakePayments]) {
    NSLog(@"(SECrackRock) startMonitoringTransactions: IAP Disabled");
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
    NSLog(@"No paid products"); // @@REMOVE
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
    NSLog(@"IAP failure"); // @@REMOVE
    [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeProductsRequest];
    [self didFinishPreparingProductInfo:NO];
    return NO;
  }
  
  return YES;
}



- (void) stopMonitoringTransactions {
#if DEBUG
  NSAssert(_isMonitoringTransactions == YES, @"Transactions are not being monitored, or SECrackRock is in an inconsistent state.");
  _isMonitoringTransactions = NO;
#endif
  
  [[SKPaymentQueue defaultQueue] removeTransactionObserver: self];
}




- (id) init {
  self = [super init];
  if (self) {
    self.isCurrentlyRestoringMultiplePurchases = NO;
    self.restoreWasInitiatedByUser = NO;
    
#if DEBUG
    _storeTransactionIsUnderway = NO;
    _isMonitoringTransactions = NO;
#endif
  }
  return self;
}


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

/**
 * Property getter that lazy-loads the list of purchased items from
 * NSUserDefaults.
 */

- (NSMutableArray *) purchasedItems {
  if (_purchasedItems == nil) {
    _purchasedItems = [[NSUserDefaults standardUserDefaults] objectForKey: SECrackRockUserDefaultsKey_purchasedItems];
    
    // if the purchased items array has never been written to disk, create an empty array and save it
    if (_purchasedItems == nil || [_purchasedItems isKindOfClass:[NSMutableArray class]] == NO) {
      NSLog(@"WRITING NEW BLANK PURCHASEDITEMS ARRAY TO USER DEFAULTS");
      _purchasedItems = [NSMutableArray array];
      [[NSUserDefaults standardUserDefaults] setObject:_purchasedItems forKey:SECrackRockUserDefaultsKey_purchasedItems];
      [[NSUserDefaults standardUserDefaults] synchronize];
    }
  }
  return _purchasedItems;
}



/**
 * Determine if a product has been purchased or not (based on the
 * possibly-incorrect record of purchased items stored locally on the user's
 * phone using NSUserDefaults).
 */

- (bool) hasProductBeenPurchased: (NSString *)productID {
  NSAssert(productID != nil, @"productID argument is nil.");
  
  return [self.purchasedItems containsObject: productID];
}



/**
 * Set whether or not a given product has been purchased (written into the
 * locally-cached record of purchased items in NSUserDefaults).
 */

- (void) setProduct:(NSString *)productID hasBeenPurchased:(BOOL)hasBeenPurchased {
  NSAssert(productID != nil, @"productID argument is nil.");
  NSAssert(self.productsByID[ productID ] != nil, @"No known product for the given productID.");
  
  if (hasBeenPurchased == YES)
    [self.purchasedItems addObject: productID];
  else
    [self.purchasedItems removeObject: productID];
  
  [[NSUserDefaults standardUserDefaults] setObject: self.purchasedItems forKey: SECrackRockUserDefaultsKey_purchasedItems];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  
  // also update the product in the productsByID dictionary for consistency's sake
  
  SECrackRockProduct *product = self.productsByID[ productID ];
  product.purchaseStatus = (hasBeenPurchased ? SECrackRockPurchaseStatusNonfreePurchased
                                             : SECrackRockPurchaseStatusNonfreeUnpurchased);
}




#pragma mark- Transaction state toggle
#pragma mark-

/**
 *
 */

- (void) storeTransactionWillBegin:(SECrackRockStoreTransactionType)type {
  NSLog(@"Store transaction will begin. (%@)", (type == 2 ? @"purchase" : (type == 4 ? @"restore" : @"products request")));
#if DEBUG
  NSAssert(_storeTransactionIsUnderway == NO, @"A store transaction is already underway, or SECrackRock is in an inconsistent state.");
  _storeTransactionIsUnderway = YES;
#endif
  
//  id objects[2], keys[2];
//  keys[0] = SECrackRockUserInfoKey_CrackRock;       objects[0] = self;
//  keys[1] = SECrackRockUserInfoKey_TransactionType; objects[1] = [NSNumber numberWithUnsignedInteger:type];
  
  [[SEStatelyNotificationRobot sharedRobot] changeStateOf: SECrackRockState_TransactionState
                                                       to: SECrackRockTransactionStateInProgress
                                                stateInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                              SECrackRockUserInfoKey_TransactionType : b(type) }];
}



/**
 *
 */

- (void) storeTransactionDidEnd:(SECrackRockStoreTransactionType)type {
  NSLog(@"Store transaction did end. (%@)", (type == 2 ? @"purchase" : (type == 4 ? @"restore" : @"products request")));
#if DEBUG
  NSAssert(_storeTransactionIsUnderway == YES, @"No store transaction is currently active, or SECrackRock is in an inconsistent state.");
  _storeTransactionIsUnderway = NO;
#endif

  
//  id objects[2], keys[2];
//  keys[0] = SECrackRockUserInfoKey_CrackRock;       objects[0] = self;
//  keys[1] = SECrackRockUserInfoKey_TransactionType; objects[1] = [NSNumber numberWithUnsignedInteger:type];
  
  [[SEStatelyNotificationRobot sharedRobot] changeStateOf: SECrackRockState_TransactionState
                                                       to: SECrackRockTransactionStateAsleep
                                                stateInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                              SECrackRockUserInfoKey_TransactionType : b(type) }];
}



#pragma mark- Purchase/restore/request outcomes
#pragma mark-

/**
 * Request for product information to app store servers has returned. If the
 * product was found and is available for purchase, it's handed to this method.
 */

- (void) requestedProductValidated: (SKProduct *)skProduct
                         productID: (NSString *)productID
                              name: (NSString *)productName
                             price: (NSString *)productPrice
                       description: (NSString *)productDescription {
  
  NSAssert(skProduct != nil, @"skProduct argument is nil.");
  NSAssert(productID != nil, @"productID argument is nil.");
  
  NSLog(@"(SECrackRock) requestedProductValidated: %@", productID);
  
  // find the product in our local product list and update it with whatever apple sent
  SECrackRockProduct *updatedProduct = self.productsByID[ productID ];
  NSAssert(updatedProduct != nil, @"updatedProduct is nil.");
  
//  if (updatedProduct == nil) {
//    // the productID returned by the app store servers couldn't
//    // be found in the productList (this would be bizarre)
//    NSLog(@"(SECrackRock) requestedProductValidated: Product not in productList");
//    [self requestedProductNotValid:productID];
//    return;
//  }
  
  if (productPrice != nil)       updatedProduct.price = productPrice;
  if (productName != nil)        updatedProduct.readableName = productName;
  if (productDescription != nil) updatedProduct.productDescription = productDescription;
  updatedProduct.skProduct = skProduct;
  updatedProduct.isAvailableInStore = YES;
  updatedProduct.purchaseStatus = ([self hasProductBeenPurchased:productID]
                                   ? SECrackRockPurchaseStatusNonfreePurchased
                                   : SECrackRockPurchaseStatusNonfreeUnpurchased);
}



/**
 *
 */

- (void) requestedProductNotValid:(NSString *)productID {
  NSAssert(productID != nil, @"productID argument is nil.");
  
  NSLog(@"(SECrackRock) requestedProductNotValid: Product '%@' unavailable", productID);
  
  // the request failed and the product is unavailable
  
  SECrackRockProduct *product = self.productsByID[ productID ];
  NSAssert(product != nil, @"product is nil.");
  
  product.isAvailableInStore = NO;
  product.purchaseStatus = SECrackRockPurchaseStatusError;
}



/**
 * Purchase request was successful, so unlock the new content for your new
 * customer and notify them that the transaction was successful.
 */

- (void) successfulPurchase: (NSString *)productID
                    receipt: (NSData *)transactionReceipt {
  
  NSAssert(productID != nil, @"productID argument is nil.");
  NSAssert(transactionReceipt != nil, @"transactionReceipt argument is nil.");
  
  NSLog(@"(SECrackRock) successfulPurchase (productID: %@)", productID);
  
  // save a record that this has been purchased locally to the phone (ends up in NSUserDefaults)
  [self setProduct:productID hasBeenPurchased:YES];
  
//  id objects[3], keys[3];
//  keys[0] = SECrackRockUserInfoKey_CrackRock; objects[0] = self;
//  keys[1] = SECrackRockUserInfoKey_ProductID; objects[1] = productID;
//  keys[2] = SECrackRockUserInfoKey_Receipt;   objects[2] = transactionReceipt;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: SECrackRockNotification_SuccessfulPurchase
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                                 SECrackRockUserInfoKey_ProductID : productID,
                                                                 SECrackRockUserInfoKey_Receipt : transactionReceipt }];
  
  [self storeTransactionDidEnd:SECrackRockStoreTransactionTypePurchase];
}


/**
 * Restore request was successful, so unlock the purchased content for your
 * customer and notify them that the transaction was successful.
 */

- (void) successfulRestore: (NSString *)productID
                   receipt: (NSData *)transactionReceipt {
  
  NSAssert(productID != nil, @"productID argument is nil.");
  NSAssert(transactionReceipt != nil, @"transactionReceipt argument is nil.");
  
  NSLog(@"(SECrackRock) successfulRestore (productID: %@)", productID);
  
  // save a record that this has been purchased locally to the phone (ends up in NSUserDefaults)
  [self setProduct:productID hasBeenPurchased:YES];
  
//  id objects[3], keys[3];
//  keys[0] = SECrackRockUserInfoKey_CrackRock; objects[0] = self;
//  keys[1] = SECrackRockUserInfoKey_ProductID; objects[1] = productID;
//  keys[2] = SECrackRockUserInfoKey_Receipt;   objects[2] = transactionReceipt;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: SECrackRockNotification_SuccessfulRestore
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                                 SECrackRockUserInfoKey_ProductID : productID,
                                                                 SECrackRockUserInfoKey_Receipt : transactionReceipt }];

  
  // if it's a single item restore initiated by the user, end the transaction state
  if (   self.restoreWasInitiatedByUser == YES
      && self.isCurrentlyRestoringMultiplePurchases == NO) {
    NSLog(@"self.restoreWasInitiatedByUser == YES  and  isCurrentlyRestoringMultiplePurchases == NO");
    
    self.restoreWasInitiatedByUser = NO;
    [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeRestore];
  }
}



/**
 * All restore requests in the transaction queue have succeeded.
 */

- (void) successfulMultipleRestoreComplete {
  NSLog(@"(SECrackRock) successfulMultipleRestoreComplete");
  
  // unset flags describing the user-initiated multiple restore state
  if (self.restoreWasInitiatedByUser) {
    [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeRestore];
  }
  self.isCurrentlyRestoringMultiplePurchases = NO;
  self.restoreWasInitiatedByUser = NO;
  
  
//  id objects[1], keys[1];
//  keys[0] = SECrackRockUserInfoKey_CrackRock; objects[0] = self;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: SECrackRockNotification_MultipleRestoreComplete
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self }];
}



/**
 * Purchase request was cancelled.
 */

- (void) cancelledPurchase: (NSString *)errorMessage {
  NSLog(@"(SECrackRock) cancelledPurchase");
  
  [self storeTransactionDidEnd:SECrackRockStoreTransactionTypePurchase];
  
  id objects[2], keys[2];
  keys[0] = SECrackRockUserInfoKey_CrackRock; objects[0] = self;
  keys[1] = SECrackRockUserInfoKey_Message;   objects[1] = errorMessage;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: SECrackRockNotification_CancelledPurchase
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                                 SECrackRockUserInfoKey_Message : errorMessage }];
}



/**
 * Purchase request failed.
 */

- (void) failedPurchase: (NSInteger)errorCode
                message: (NSString *)errorMessage {
  
  NSLog(@"(SECrackRock) failedPurchase");
  
  [self storeTransactionDidEnd:SECrackRockStoreTransactionTypePurchase];
  
//  id objects[3], keys[3];
//  keys[0] = SECrackRockUserInfoKey_CrackRock; objects[0] = self;
//  keys[1] = SECrackRockUserInfoKey_ErrorCode; objects[1] = [NSNumber numberWithInteger:errorCode];
//  keys[2] = SECrackRockUserInfoKey_Message;   objects[2] = errorMessage;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: SECrackRockNotification_FailedPurchase
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                                 SECrackRockUserInfoKey_ErrorCode : b(errorCode),
                                                                 SECrackRockUserInfoKey_Message : errorMessage }];
}



/**
 * Restore queue did not include any transactions, so either the user has not yet made a purchase
 * or the user's prior purchase is unavailable, so notify user to make a purchase within the app.
 * If the user previously purchased the item, they will NOT be re-charged again, but it should 
 * restore their purchase. 
 */

- (void) incompleteRestore {
  
  NSLog(@"(SECrackRock) incompleteRestore");
  
  [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeRestore];
  
//  id objects[1], keys[1];
//  keys[0] = SECrackRockUserInfoKey_CrackRock; objects[0] = self;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: SECrackRockNotification_IncompleteRestore
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self }];
}



/**
 * Restore request failed or was cancelled, so notify the user.
 */

- (void) failedRestore: (NSInteger) errorCode
               message: (NSString *) errorMessage {
  
  NSLog(@"(SECrackRock) failedRestore");
  
  [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeRestore];
  
//  id objects[3], keys[3];
//  keys[0] = SECrackRockUserInfoKey_CrackRock; objects[0] = self;
//  keys[1] = SECrackRockUserInfoKey_ErrorCode; objects[1] = [NSNumber numberWithInteger:errorCode];
//  keys[2] = SECrackRockUserInfoKey_Message;   objects[2] = errorMessage;
  
  [[NSNotificationCenter defaultCenter] postNotificationName: SECrackRockNotification_FailedRestore
                                                      object: self
                                                    userInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                                 SECrackRockUserInfoKey_ErrorCode : b(errorCode),
                                                                 SECrackRockUserInfoKey_Message : errorMessage }];
}







#pragma mark- Product data
#pragma mark-

/**
 * Creates an array of all visible products (free and purchaseable) in the order
 * that they ought to appear in the springboard view.
 */

- (NSMutableArray *) createSortedProductIDList {
  
  NSMutableArray *productList = [NSMutableArray arrayWithCapacity:(self.freeProducts.count + self.paidProducts.count)];
  
  // Populate the arrays that the SEBlingLord view draws on for its contents:
  
  // ... first add all of the free/default products to the list
  for (SECrackRockProduct *product in self.freeProducts) {
    [productList addObject: product.productID];
  }
  
  // ... then add all of the purchased products to the list
  for (SECrackRockProduct *product in self.paidProducts) {
    if ([self hasProductBeenPurchased: product.productID] == YES)
      [productList addObject: product.productID];
  }
  
  // ... finally add all of the unpurchased products to the list
  for (SECrackRockProduct *product in self.paidProducts) {
    if ([self hasProductBeenPurchased: product.productID] == NO)
      [productList addObject: product.productID];
  }
  
  return productList;
}


/**
 * Creates a dictionary of all products (free and purchaseable) keyed by product ID.
 */

- (NSMutableDictionary *) createProductDictionary {
  
  NSMutableDictionary *productDict = [NSMutableDictionary dictionaryWithCapacity:(self.freeProducts.count + self.paidProducts.count)];
  
  // ... first add all of the free/default products
  for (SECrackRockProduct *product in self.freeProducts) {
//    SECrackRockProduct *productCopy = [product copy];
    product.purchaseStatus = SECrackRockPurchaseStatusFree;
    productDict[ product.productID ] = product;
//    [productDict setObject:product forKey:product.productID];
  }
  
  // ... then add all of the paid products
  for (SECrackRockProduct *product in self.paidProducts) {
//    SECrackRockProduct *productCopy = [product copy];
    product.purchaseStatus = SECrackRockPurchaseStatusUnknown;
    product.isAvailableInStore = NO; // set to NO until we get confirmation of YES from apple
    productDict[ product.productID ] = product;
//    [productDict setObject:product forKey:product.productID];
  }
  
  return productDict;
}



#pragma mark- Purchasing/restoring convenience methods
#pragma mark-




/**
 *
 */

- (void) didFinishPreparingProductInfo:(BOOL)success {
  NSLog(@"didFinishPreparingProductInfo (success: %@)", (success ? @"YES" : @"NO"));
  
//  id objects[2], keys[2];
//  keys[0] = SECrackRockUserInfoKey_CrackRock; objects[0] = self;
//  keys[1] = SECrackRockUserInfoKey_Success;   objects[1] = [NSNumber numberWithBool:success];
  
//  NSNumber *nSuccess = (success ? @YES : @NO);
  [[SEStatelyNotificationRobot sharedRobot] changeStateOf: SECrackRockState_ProductsRequestState
                                                       to: SECrackRockProductsRequestStateFinished
                                                stateInfo: @{ SECrackRockUserInfoKey_CrackRock : self,
                                                              SECrackRockUserInfoKey_Success : (success ? @YES : @NO) }];
}





#pragma mark- Public methods for purchasing/restoring
#pragma mark-

/**
 * Attempt to purchase a product with a given product ID.
 */

- (bool) tryToPurchaseProduct:(NSString *)productID {
  NSLog(@"(SECrackRock) tryToPurchaseProduct: %@", productID);
  
  NSAssert(productID != nil, @"productID argument is nil.");
  
  // First, ensure that the SKProduct that was retrieved by the requestProduct
  // method in the viewWillAppear event is valid before trying to purchase it
  
  SECrackRockProduct *product = self.productsByID[ productID ];
  
  if (product == nil || product.isAvailableInStore == NO || product.skProduct == nil) {
    NSLog(@"(SECrackRock) tryToPurchaseProduct: product '%@' not found", productID);
    return NO;
  }
  
  // IAP is enabled on this device.  proceed with purchase.
  if ([SKPaymentQueue canMakePayments]) {
    [self storeTransactionWillBegin:SECrackRockStoreTransactionTypePurchase];
    
    // create a payment request using the SKProduct we got back from our SKProductsRequest
    SKPayment *paymentRequest = [SKPayment paymentWithProduct:product.skProduct];
    
    // request a purchase of the product
    [[SKPaymentQueue defaultQueue] addPayment:paymentRequest];
    
    return YES;
  }
  else {
    NSLog(@"(SECrackRock) tryToPurchaseProduct: IAP disabled");
    return NO;
  }
}



/**
 * Attempt to restore a customer's previous non-consumable or subscription
 * In-App Purchase with a given product ID.  Required if a user reinstalled app
 * on same device or another device.
 */

- (bool) tryToRestorePurchase: (NSString *)productID {
  
  NSAssert(productID != nil, @"productID argument is nil.");
  
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
  
  NSLog(@">>>>>>>>>>>>>> tryToRestorePurchase <<<<<<<<<<<<<<");
  return NO;
}



/**
 * Attempt to restore all purchases made with the current apple ID.
 */

- (bool) tryToRestoreAllPurchases {
  NSLog(@"(SECrackRock) tryToRestoreAllPurchases");
  
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



#pragma mark- ??? (needs section name)
#pragma mark-

- (bool) requestProduct:(NSString *)productID {
  NSAssert(productID != nil, @"productID argument is nil.");
  NSLog(@"(SECrackRock) requestProduct: %@", productID);
  
  return [self requestProducts:[NSSet setWithObject:productID]];
}


- (bool) requestProducts:(NSSet *)productIDs {
  NSAssert(productIDs != nil, @"productIDs argument is nil.");
  NSAssert(productIDs.count > 0, @"productIDs argument is empty.");
  
  NSLog(@"(SECrackRock) requestProducts: %@", productIDs);
  
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
    NSLog(@"(SECrackRock) requestProducts: IAP Disabled");
    return NO;
  }
}



#pragma mark -
#pragma mark SKProductsRequestDelegate Methods

/**
 * Store Kit returns a response from an SKProductsRequest.
 */

- (void) productsRequest: (SKProductsRequest *)request
      didReceiveResponse: (SKProductsResponse *)response {
  
  NSAssert(request != nil, @"request argument is nil.");
  NSAssert(response != nil, @"response argument is nil.");
  
  NSLog(@"(SECrackRock) productsRequest:didReceiveResponse: -- %d requested products available", response.products.count);
  
  // release our reference to the SKProductsRequest
  self.productsRequest = nil;
  
  // update our cached products with the received product info
  for (SKProduct *product in response.products) {
    NSAssert(self.productsByID[ product.productIdentifier ] != nil, @"SKProductsRequest was returned a productID that was not requested.");
//      [self requestedProductNotValid: product.productIdentifier];
    
    [self requestedProductValidated:product
                          productID:product.productIdentifier
                               name:product.localizedTitle
                              price:product.price.stringValue
                        description:product.localizedDescription];
  }

  // if any of the requested product IDs were not valid, mark them as such
  NSLog(@"(SECrackRock) productsRequest:didReceiveResponse: -- %d invalid product IDs", response.invalidProductIdentifiers.count);
  for (NSString *invalidProductID in response.invalidProductIdentifiers) {
    [self requestedProductNotValid:invalidProductID];
  }
  
  
  // signal that we have processed all of the information from the SKProductsRequest
  [self storeTransactionDidEnd:SECrackRockStoreTransactionTypeProductsRequest];
  [self didFinishPreparingProductInfo:YES];
}


#pragma mark -
#pragma mark SKPaymentTransactionObserver Methods

/**
 * The transaction status of the SKPaymentQueue is sent here.
 */

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
  NSAssert(queue != nil, @"queue argument is nil.");
  NSAssert(transactions != nil, @"transactions argument is nil.");
  
  NSLog(@"(SECrackRock) updatedTransactions");
  
  NSMutableArray *restores = [NSMutableArray array];
  
	for (SKPaymentTransaction *transaction in transactions) {
    
		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchasing: {
        NSLog(@"(SECrackRock) updatedTransactions: Purchasing");
				// Item is still in the process of being purchased
      }	break;
				
			case SKPaymentTransactionStatePurchased: {
        NSLog(@"(SECrackRock) updatedTransactions: Purchased");
				// Item was successfully purchased!
				
				// Return transaction data. App should provide user with purchased product.
        [self successfulPurchase: transaction.payment.productIdentifier
                         receipt: transaction.transactionReceipt];
				
				// After customer has successfully received purchased content,
				// remove the finished transaction from the payment queue.
				[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
      } break;
				
			case SKPaymentTransactionStateRestored: {
        NSLog(@"(SECrackRock) updatedTransactions: Restored");
				// Verified that user has already paid for this item.
				// Ideal for restoring item across all devices of this customer.
				
        [restores addObject:transaction];
      } break;
				
			case SKPaymentTransactionStateFailed: {
				// Purchase was either cancelled by user or an error occurred.
				
				if (transaction.error.code == SKErrorPaymentCancelled) {
          NSLog(@"(SECrackRock) updatedTransactions: Cancelled");
          
          [self cancelledPurchase:transaction.error.localizedDescription];
        }
        else {
          NSLog(@"(SECrackRock) updatedTransactions: Failed");
          
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



/**
 * Called when one or more transactions have been removed from the queue.
 */

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
  NSAssert(queue != nil, @"queue argument is nil.");
  NSAssert(transactions != nil, @"transactions argument is nil.");
  
  NSLog(@"(SECrackRock) removedTransactions");
}



/**
 * Called when SKPaymentQueue has finished sending restored transactions.
 */

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
  NSAssert(queue != nil, @"queue argument is nil.");
  
  NSLog(@"(SECrackRock) paymentQueueRestoreCompletedTransactionsFinished");
  
  if (queue.transactions.count == 0) {
    NSLog(@"(SECrackRock) restore queue.transactions count == 0");
    
    // Queue does not include any transactions, so either user has not yet made a purchase
    // or the user's prior purchase is unavailable, so notify app (and user) accordingly.
    
    [self incompleteRestore];
  }
  else {
    // Queue does contain one or more transactions, so return transaction data.
    // App should provide user with purchased product.
    
    NSLog(@"(SECrackRock) restore queue.transactions available");
    
    for (SKPaymentTransaction *transaction in queue.transactions) {
      NSLog(@"(SECrackRock) restore queue.transactions - transaction data found");
    }
    
    NSLog(@"(SECrackRock) multiple restore was successful");
    [self successfulMultipleRestoreComplete];
  }
}



/**
 * Called if an error occurred while restoring transactions.
 */

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
  NSAssert(queue != nil, @"queue argument is nil.");
  NSAssert(error != nil, @"error argument is nil.");
  
  // Restore was cancelled or an error occurred, so notify user.
  NSLog(@"(SECrackRock) restoreCompletedTransactionsFailedWithError");
  [self failedRestore:error.code message:error.localizedDescription];
}





@end





