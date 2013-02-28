////
////  SECrackRockViewController.m
////  iOS-CrackRock in-app purchase framework
////
////  Created by bryn austin bellomy on 6/19/12.
////  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
////
//
////#import <iOS-BlingLord/SEBlingLordView.h>
////#import <iOS-BlingLord/SEBlingLordMenuItem.h>
//#import <ObjC-StatelyNotificationRobot/SEStatelyNotificationRobot.h>
//#import <BrynKit/BrynKit.h>
//
//#import "SECrackRockStoreController.h"
//#import "SECrackRock.h"
//#import "SECrackRockProduct.h"
////#import "UIImage+SECrackRock.h"
//
//
//Key(StateObserver_Transaction_SpringboardView);
//Key(StateObserver_Transaction_RestorePurchases);
//Key(StateObserver_ProductsRequest_SECrackRockStoreController);
//
//
////@implementation SECrackRockMenuItem
////@end
//
//
//
//@interface SECrackRockStoreController ()
////  @property (nonatomic, weak, readwrite) UIBarButtonItem *restorePurchasesButton;
//@end
//
//
///**!
// * ## SECrackRockViewController
// */
//@implementation SECrackRockStoreController
//
//
//#pragma mark- View lifecycle
//#pragma mark-
//
//- (instancetype) init {
//    self = [super init];
//    if (self) {
//        [self registerForAllStoreNotifications];
//    }
//    return self;
//}
//
///**!
// * #### initWithNibName:bundle:
// *
// * @param {NSString*} nibNameOrNil
// * @param {NSBundle*} nibBundleOrNil
// * @return {id}
// */
//
////- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
////    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
////    if (self) {
////      self.springboardItemSize = CGSizeMake(83.0f, 103.0f);
////    }
////    return self;
////}
//
//
//
///**!
// * #### viewWillAppear:
// *
// * @param {BOOL} animated
// * @return {void}
// */
//
////- (void) viewWillAppear:(BOOL)animated {
////    [super viewWillAppear: animated];
////
////    // register for the notifications posted by SECrackRock
////    [self registerForAllStoreNotifications];
////}
//
//
//
///**!
// * #### viewWillDisappear:
// *
// * @param {BOOL} animated
// * @return {void}
// */
//
////- (void) viewWillDisappear:(BOOL)animated {
////  [super viewWillDisappear:animated];
////
////  // remove all notification handlers and SEStatelyNotificationRobot state handlers
////  [self unregisterForAllStoreNotifications];
////}
//
//
//
//- (void) dealloc {
//    [self unregisterForAllStoreNotifications];
//}
//
//
//
//#pragma mark- Notification handling
//#pragma mark-
//
///**!
// * #### registerForAllStoreNotifications
// *
// * @return {void}
// */
//
//- (void) registerForAllStoreNotifications {
//    // remove any existing observer
//    [SEStatelyNotificationRobot.sharedRobot removeHandlerWithID: StateObserver_Transaction_RestorePurchases];
//    [SEStatelyNotificationRobot.sharedRobot removeHandlerWithID: StateObserver_ProductsRequest_SECrackRockStoreController];
//    
//    @weakify(self);
//    [SEStatelyNotificationRobot.sharedRobot handleStateOf: ObservableState_Transaction
//                                                handlerID: StateObserver_Transaction_RestorePurchases
//                                                  onQueue: NSOperationQueue.mainQueue
//                                                withBlock: ^(SEState newState, NSDictionary *stateInfo) {
//                                                    
//                                                    BrynFnLog(@"handler for TransactionState state change: newState == %d", newState);
//                                                    @strongify(self);
//                                                    
//                                                    if (self.transactionStateDidChange != nil)
//                                                        self.transactionStateDidChange(stateInfo);
//                                                    
////                                                    BOOL enabled = (newState == SECrackRockTransactionStateAsleep);
////                                                    self.restorePurchasesButton.enabled = enabled;
//                                                    
//                                                }];
//    
//    [SEStatelyNotificationRobot.sharedRobot handleStateOf: ObservableState_ProductsRequest
//                                                handlerID: StateObserver_ProductsRequest_SECrackRockStoreController
//                                                  onQueue: NSOperationQueue.mainQueue
//                                                withBlock: ^(SEState newState, NSDictionary *stateInfo) {
//                                                    
//                                                    BrynFnLog(@"handler for ProductsRequest state change: newState == %d", newState);
//                                                    @strongify(self);
//                                                    
//                                                    if (self.productsRequestStateDidChange != nil)
//                                                        self.productsRequestStateDidChange(stateInfo);
//                                                    
//                                                    if (newState == SECrackRockProductsRequestStateFinished) {
//                                                        if (self.didFinishPreparingProductInfo != nil)
//                                                            self.didFinishPreparingProductInfo(stateInfo);
//                                                    }
//                                                    
//                                                }];
//
//    [NSNotificationCenter.defaultCenter addObserver: self selector: @selector(successfulPurchase:)
//                                               name: SECrackRockNotification_SuccessfulPurchase      object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter addObserver: self selector: @selector(cancelledPurchase:)
//                                               name: SECrackRockNotification_CancelledPurchase       object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter addObserver: self selector: @selector(failedPurchase:)
//                                               name: SECrackRockNotification_FailedPurchase          object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter addObserver: self selector: @selector(successfulRestore:)
//                                               name: SECrackRockNotification_SuccessfulRestore       object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter addObserver: self selector: @selector(multipleRestoreComplete:)
//                                               name: SECrackRockNotification_MultipleRestoreComplete object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter addObserver: self selector: @selector(incompleteRestore:)
//                                               name: SECrackRockNotification_IncompleteRestore       object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter addObserver: self selector: @selector(failedRestore:)
//                                               name: SECrackRockNotification_FailedRestore           object:SECrackRock.sharedInstance];
//}
//
///**!
// * #### unregisterForAllStoreNotifications
// *
// * @return {void}
// */
//
//- (void) unregisterForAllStoreNotifications {
//    [SEStatelyNotificationRobot.sharedRobot removeHandlerWithID: StateObserver_Transaction_SpringboardView];
//    [SEStatelyNotificationRobot.sharedRobot removeHandlerWithID: StateObserver_Transaction_RestorePurchases];
//    [SEStatelyNotificationRobot.sharedRobot removeHandlerWithID: StateObserver_ProductsRequest_SECrackRockStoreController];
//
//    [NSNotificationCenter.defaultCenter removeObserver:self name:SECrackRockNotification_SuccessfulPurchase object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter removeObserver:self name:SECrackRockNotification_CancelledPurchase object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter removeObserver:self name:SECrackRockNotification_FailedPurchase object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter removeObserver:self name:SECrackRockNotification_SuccessfulRestore object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter removeObserver:self name:SECrackRockNotification_MultipleRestoreComplete object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter removeObserver:self name:SECrackRockNotification_IncompleteRestore object:SECrackRock.sharedInstance];
//    [NSNotificationCenter.defaultCenter removeObserver:self name:SECrackRockNotification_FailedRestore object:SECrackRock.sharedInstance];
//}
//
//
//
//#pragma mark- BlingLord springboard view (+ misc. graphics)
//#pragma mark-
//
///**!
// * #### shouldDisplayProductInStore:
// *
// * @param {SECrackRockProduct*} product
// * @return {BOOL}
// */
//
//- (BOOL) shouldDisplayProductInStore:(SECrackRockProduct *)product {
//  yssert(product != nil, @"product argument is nil.");
//
//  BOOL shouldDisplayItem = YES;
//
//  switch (product.productStatus) {
//    // products that returned errors or nothing when app store was queried
//    default:
//    case SECrackRockProductStatusUnknown:
//    case SECrackRockProductStatusError:
//      shouldDisplayItem = NO;
//      break;
//
//    // paid/purchaseable products
//    case SECrackRockProductStatusNonfreePurchased:
//    case SECrackRockProductStatusNonfreeUnpurchased: {
//      shouldDisplayItem = product.isAvailableInStore;
//    } break;
//
//    // free items might as well always show up, right?
//    case SECrackRockProductStatusFree:
//      shouldDisplayItem = YES;
//      break;
//  }
//
//  return shouldDisplayItem;
//}
//
//
//
///**!
// * #### purchaseableIndicatorForProduct:
// *
// * @param {SECrackRockProduct*} product
// * @return {UIImage*}
// */
//
////- (UIImage *) purchaseableIndicatorForProduct: (SECrackRockProduct *)product {
////  return nil;
////}
//
//
///**!
// * #### iconForProduct:withPurchaseableIndicator:
// *
// * @param {SECrackRockProduct*} product
// * @param {BOOL} withPurchaseableIndicator
// * @return {UIImage*}
// */
//
////- (UIImage *) iconForProduct:(SECrackRockProduct *)product withPurchaseableIndicator:(BOOL)withPurchaseableIndicator {
////  yssert(product != nil, @"product argument is nil.");
////
////  // load the product's icon, add the 'purchaseable' indicator overlay if it hasn't been purchased yet
////  UIImage *icon = UIImageWithBundlePNG(product.thumbnailPNGFilename);
////  yssert(icon != nil, @"icon is nil.");
////
////  if (withPurchaseableIndicator == YES) {
////    UIImage *purchaseableIndicator = [self purchaseableIndicatorForProduct: product];
////
////    // if a purchaseableIndicator was provided, replace the existing icon with one that has the indicator overlaid
////    if (purchaseableIndicator != nil) {
////      icon = [icon imageWithOverlay:purchaseableIndicator atPosition:CGPointZero withSize:icon.size];
////    }
////  }
////
////  return icon;
////}
//
//
///**!
// * #### initializeMenuItems
// *
// * @return {NSMutableArray*}
// */
//
////- (NSMutableArray *) initializeMenuItems {
////
////  // create an array of SEBlingLord objects
////  NSMutableArray *items = [NSMutableArray arrayWithCapacity: SECrackRock.sharedInstance.sortedProductIDs.count];
////
////  __bryn_weak SECrackRockViewController *weakSelf = self;
////  for (NSString *productID in SECrackRock.sharedInstance.sortedProductIDs) {
////    SECrackRockProduct *product = SECrackRock.sharedInstance.productsByID[ productID ];
////
////    // make sure we want to display each product (i.e. the request to the app store was successful)
////    if ([self shouldDisplayProductInStore: product] == NO)
////      continue;
////
////    // generate the product's icon
////    BOOL showPurchaseableIndicator = (product.productStatus == SECrackRockProductStatusNonfreeUnpurchased);
////    UIImage *icon = [self iconForProduct:product withPurchaseableIndicator:showPurchaseableIndicator];
////
////    // initialize the menu item object
////    SECrackRockMenuItem *menuItem =
////      [[SECrackRockMenuItem alloc] initWithFrame: CGRectMake(0.0f, 0.0f, self.springboardItemSize.width, self.springboardItemSize.height)
////                                           title: product.readableName image: icon
////                                       removable: NO
////                                 tapHandlerBlock: ^{
////                                     __strong SECrackRockViewController *strongSelf = weakSelf;
////                                     SECrackRockProduct *blockProduct = SECrackRock.sharedInstance.productsByID[ productID ];
////                                     yssert(blockProduct != nil, @"blockProduct is nil.");
////
////                                     [strongSelf productAccessWasAttempted: blockProduct];
////                                 }];
////
////    menuItem.productID = product.productID;
////    [items addObject: menuItem];
////  }
////
////  return items;
////}
//
//
//
///**!
// * #### menuItemForProductID:
// *
// * @param {NSString*} productID
// * @return {SECrackRockMenuItem*}
// */
//
////- (SECrackRockMenuItem *) menuItemForProductID:(NSString *)productID {
////  if (productID != nil) {
////    for (SECrackRockMenuItem *menuItem in self.springboardView.items) {
////      if ([productID isEqualToString:menuItem.productID])
////        return menuItem;
////    }
////  }
////  return nil;
////}
//
//
//
//#pragma mark- User interaction
//#pragma mark-
//
///**!
// * #### productAccessWasAttempted:
// *
// * @param {SECrackRockProduct*} product
// * @return {void}
// */
//
//- (void) tryToAccessProduct: (NSString *)productID {
//  yssert(productID != nil, @"productID argument is nil.");
//
//    SECrackRockProduct *product = SECrackRock.sharedInstance.productsByID[ productID ];
//    assert(product != nil);
//
//    if (self.productAccessWasAttempted != nil)
//        self.productAccessWasAttempted(product);
//
////  switch (product.productStatus) {
////    case SECrackRockProductStatusFree:
////    case SECrackRockProductStatusNonfreePurchased:
////      // this is where you'd probably want to let the user use the purchase
////      break;
////
////    case SECrackRockProductStatusNonfreeUnpurchased: {
////      [self tryToPurchaseProduct: product.productID];
////    } break;
////
////    default: {
////      yssert(NO, @"SECrackRockProduct productStatus is unknown.");
////      [[[UIAlertView alloc] initWithTitle: @"Our bad"
////                                  message: @"An error occurred, and we don't know exactly why.  Maybe try again later!"
////                                 delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
////    } break;
////  }
//}
//
//
//
//#pragma mark- Public methods for purchasing/restoring
//#pragma mark-
//
///**!
// * #### tryToPurchaseProduct:
// *
// * Attempt to purchase a product with a given product ID.
// *
// * @param {NSString*} productID
// * @return {void}
// */
//
//- (void) tryToPurchaseProduct:(NSString *)productID {
//
//  BOOL success = [SECrackRock.sharedInstance tryToPurchaseProduct:productID];
//  if (success == NO) {
//    // Returned NO, so notify user that In-App Purchase is Disabled in their Settings.
//    [[[UIAlertView alloc] initWithTitle: @"Allow Purchases"
//                                message: @"You must first enable In-App Purchase in your iOS Settings before making this purchase."
//                               delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//
//  }
//}
//
//
//
///**!
// * #### tryToRestorePurchase:
// *
// * Attempt to restore a customer's previous non-consumable or subscription
// * In-App Purchase with a given product ID.  Required if a user reinstalled app
// * on same device or another device.
// *
// * @param {NSString*} productID
// * @return {void}
// */
//
//- (void) tryToRestorePurchase: (NSString *)productID {
//
//  BOOL success = [SECrackRock.sharedInstance tryToRestorePurchase:productID];
//
//  if (success == NO) {
//    [[[UIAlertView alloc] initWithTitle: @"Allow Purchases"
//                                message: @"You must first enable In-App Purchase in your iOS Settings before restoring a previous purchase."
//                               delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
//  }
//}
//
//
///**!
// * #### tryToRestoreAllPurchases
// *
// * Attempt to restore all purchases made with the current apple ID.
// *
// * @return {void}
// */
//
//- (void) tryToRestoreAllPurchases {
//
//  BOOL success = [SECrackRock.sharedInstance tryToRestoreAllPurchases];
//
//  if (success == NO) {
//    // notify user that In-App Purchase is Disabled in their Settings.
//    [[[UIAlertView alloc] initWithTitle: @"Allow Purchases"
//                                message: @"You must first enable In-App Purchase in your iOS Settings before restoring a previous purchase."
//                               delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
//
//  }
//}
//
//
//
//
///**!
// * #### didFinishPreparingProductInfo
// *
// * Called in response to `SECrackRockNotification_DidFinishPreparingProductInfo`.
// *
// * Sets up the springboard view and creates a menu item for each product that
// * was verified as purchaseable by the app store.
// *
// * Note: if you override this method in a subclass, you really oughta call the
// * superclass's method (i.e., `[super didFinishPreparingProductInfo]`).
// *
// * @return {void}
// */
//
////- (void) didFinishPreparingProductInfo {
////
////  // initialize the menu items
////
////  NSMutableArray *menuItems = [self initializeMenuItems];
////
////  yssert(menuItems != nil, @"menuItems array is nil.");
////
////  // pass the array to a new instance of SEBlingLord and add it to the view
////
////  CGRect frame;
////  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
////    frame = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f - 20.0f); // 20.0f = status bar
////  else
////    frame = CGRectMake(0.0f, 0.0f, 768.0f, 1024.0f - 20.0f); // @@TODO: is this correct for an iPad?
////
////  SEBlingLordView *board = [[SEBlingLordView alloc] initWithFrame:frame];
////  board.itemSize = self.springboardItemSize;
////  board.itemMargins = self.springboardItemMargins; //  CGSizeMake(15.0f, 15.0f);
////  board.outerMargins = self.springboardOuterMargins; // CGSizeMake(10.0f, 10.0f);
////  board.allowsEditing = NO;
////  [board addMenuItems:menuItems];
////
////
////  if (self.springboardView != nil) {
////    [self.springboardView removeFromSuperview];
////    self.springboardView = nil;
////  }
////
////  [self.view addSubview: board];
////  self.springboardView = board;
////
////
////  // register a block to respond to the transaction state (i.e. whether or not a
////  // transaction with the app store servers is pending).  this block toggles
////  // user interaction with the springboard off when a transaction is underway,
////  // and back on when it is done.
////
////    [SEStatelyNotificationRobot.sharedRobot removeHandlerWithID: StateObserver_Transaction_SpringboardView]; // remove any existing observer
////    
////    @weakify(self);
////    [SEStatelyNotificationRobot.sharedRobot handleStateOf: ObservableState_Transaction
////                                                handlerID: StateObserver_Transaction_SpringboardView
////                                                  onQueue: NSOperationQueue.mainQueue
////                                                withBlock: ^(SEState newState, NSDictionary *stateInfo) {
////                                                    @strongify(self);
////                                                    BOOL enabled = (newState == SECrackRockTransactionStateAsleep);
////                                                    self.springboardView.userInteractionEnabled = enabled;
////                                                }];
////}
//
//
//
///**!
// * #### restorePurchasesButtonClicked
// *
// * Called when the user has clicked the 'restore all purchases' button.  Can
// * be rigged up to a button using Interface Builder, but does not need to be.
// *
// * @return {IBAction}
// */
//
////- (IBAction) restorePurchasesButtonClicked {
////  [self tryToRestoreAllPurchases];
////}
//
//
//
///**
// *
// */
//
///**!
// * #### recreateProductIconWithoutPurchaseableIndicator:
// *
// * @param {NSString*} productID
// *
// * @return {void}
// */
//
////- (void) recreateProductIconWithoutPurchaseableIndicator:(NSString *)productID {
////  yssert(productID != nil, @"productID argument is nil.");
////
////  // recreate the product's icon without the purchaseable indicator
////
////  __bryn_weak SECrackRockViewController *weakSelf = self;
////  dispatch_async(dispatch_get_main_queue(), ^{
////    __strong SECrackRockViewController *strongSelf = weakSelf;
////
////    SECrackRockMenuItem *springboardMenuItem = [strongSelf menuItemForProductID:productID];
////    SECrackRockProduct *product = SECrackRock.sharedInstance.productsByID[ productID ];
////
////    springboardMenuItem.imageView.image = [strongSelf iconForProduct:product withPurchaseableIndicator:NO];
////  });
////
////}
//
//
///**!
// * #### displayAlertToUserWithTitle:text:dismissText:
// *
// * @param {NSString*} title
// * @param {NSString*} text
// * @param {NSString*} dismissText
// *
// * @return {void}
// */
//
//- (void) displayAlertToUserWithTitle:(NSString *)title text:(NSString *)text dismissText:(NSString *)dismissText {
//  [[[UIAlertView alloc] initWithTitle:title message:text delegate:nil cancelButtonTitle:dismissText otherButtonTitles:nil] show];
//}
//
//
//
///**!
// * #### successfulPurchase:
// *
// * @param {NSNotification*} notification
// * @return {void}
// */
//
//- (void) successfulPurchase:(NSNotification *)notification {
//    yssert(notification != nil, @"notification argument is nil.");
//    
//    //  NSString *productID = notification.userInfo[ SECrackRockUserInfoKey_ProductID ];
//    //  [self recreateProductIconWithoutPurchaseableIndicator:productID];
//    
//    // notify the user that the purchase was successful
//    if (self.successfulPurchase != nil)
//        self.successfulPurchase(notification.userInfo);
//    else
//        [self displayAlertToUserWithTitle: @"Thank You!" text: @"Your purchase was successful!" dismissText: @"OK"];
//
//}
//
//
//
///**!
// * #### cancelledPurchase:
// *
// * @param {NSNotification*} notification
// * @return {void}
// */
//
//- (void) cancelledPurchase:(NSNotification *)notification {
//    yssert(notification != nil, @"notification argument is nil.");
//    
//    // no-op
//    
//    if (self.cancelledPurchase != nil)
//        self.cancelledPurchase(notification.userInfo);
//}
//
//
//
///**!
// * #### failedPurchase:
// *
// * @param {NSNotification*} notification
// * @return {void}
// */
//
//- (void) failedPurchase:(NSNotification *)notification {
//    yssert(notification != nil, @"notification argument is nil.");
//    
//    if (self.failedPurchase != nil)
//        self.failedPurchase(notification.userInfo);
//    else
//        [self displayAlertToUserWithTitle: @"Purchase Failed" text: @"There was a transaction error. Please try again later, or contact customer support for assistance." dismissText: @"OK"];
//
//}
//
//
//
///**!
// * #### successfulRestore:
// *
// * @param {NSNotification*} notification
// * @return {void}
// */
//
//- (void) successfulRestore:(NSNotification *)notification {
//    yssert(notification != nil, @"notification argument is nil.");
//    
//    //  NSString *productID = notification.userInfo[ SECrackRockUserInfoKey_ProductID ];
//    //  [self recreateProductIconWithoutPurchaseableIndicator:productID];
//    
//    // if it's a single item restore, notify the user that the restore was successful
//    if (NO == SECrackRock.sharedInstance.isCurrentlyRestoringMultiplePurchases) {
//        if (self.successfulRestore != nil)
//            self.successfulRestore(notification.userInfo);
//        else
//            [self displayAlertToUserWithTitle: @"Thank You!" text: @"Your purchase was successfully restored!" dismissText: @"OK"];
//
//    }
//}
//
//
//
///**!
// * #### multipleRestoreComplete:
// *
// * @param {NSNotification*} notification
// * @return {void}
// */
//
//- (void) multipleRestoreComplete:(NSNotification *)notification {
//    yssert(notification != nil, @"notification argument is nil.");
//    
//    if (self.multipleRestoreComplete != nil)
//        self.multipleRestoreComplete(notification.userInfo);
//    else
//        [self displayAlertToUserWithTitle: @"Success!" text: @"Your purchases were successfully restored!" dismissText: @"OK"];
//}
//
//
//
///**!
// * #### incompleteRestore:
// *
// * @param {NSNotification*} notification
// * @return {void}
// */
//
//- (void) incompleteRestore:(NSNotification *)notification {
//    yssert(notification != nil, @"notification argument is nil.");
//    
//
//    if (self.incompleteRestore != nil)
//        self.incompleteRestore(notification.userInfo);
//    else
//        [self displayAlertToUserWithTitle: @"Restore Issue" text: @"A prior purchase transaction could not be found. To restore the purchased product, tap the product's icon. Paid customers will NOT be charged again, but the purchase will be restored." dismissText: @"OK"];
//}
//
//
//
///**!
// * #### failedRestore:
// *
// * @param {NSNotification*} notification
// * @return {void}
// */
//
//- (void) failedRestore:(NSNotification *)notification {
//    yssert(notification != nil, @"notification argument is nil.");
//    
//
//    if (self.failedRestore != nil)
//        self.failedRestore(notification.userInfo);
//    else
//        [self displayAlertToUserWithTitle: @"Restore Stopped" text: @"Either you cancelled the request or your prior purchase could not be restored. Please try again later, or contact customer support for assistance." dismissText: @"OK"];
//}
//
//
//
//
//
//@end
//
//
//
//
//
//
//
