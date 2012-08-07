//
//  SECrackRockViewController.m
//  SECrackRock in-app purchase framework
//
//  Created by bryn austin bellomy on 6/19/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <iOS-BlingLord/SEBlingLordView.h>
#import <iOS-BlingLord/SEBlingLordMenuItem.h>
#import <ObjC-StatelyNotificationRobot/SEStatelyNotificationRobot.h>

#import "SECrackRockViewController.h"
#import "SECrackRock.h"
#import "SECrackRockProduct.h"
#import "UIImage+SECrackRock.h"

//#import "MBProgressHUD.h" // @@TODO: implement MBProgressHUD


static NSString *const SECrackRockTransactionStateObserver_SpringboardView = @"SECrackRockTransactionStateObserver_SpringboardView";
static NSString *const SECrackRockTransactionStateObserver_RestorePurchasesButton = @"SECrackRockTransactionStateObserver_RestorePurchasesButton";
static NSString *const SECrackRockProductsRequestStateObserver_SECrackRockViewController = @"SECrackRockProductsRequestStateObserver_SECrackRockViewController";





@implementation SECrackRockMenuItem
  @synthesize productID = _productID;
@end



@interface SECrackRockViewController ()
  @property (nonatomic, bryn_weak, readwrite) UIBarButtonItem *restorePurchasesButton;
@end


@implementation SECrackRockViewController

@synthesize springboardView = _springboardView;
@synthesize restorePurchasesButton = _restorePurchasesButton;
@synthesize springboardItemSize = _springboardItemSize;
@synthesize springboardItemMargins = _springboardItemMargins;
@synthesize springboardOuterMargins = _springboardOuterMargins;



#pragma mark- View lifecycle
#pragma mark-

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
      self.springboardItemSize = CGSizeMake(83.0f, 103.0f);
    }
    return self;
}



- (void) viewDidLoad {
  [super viewDidLoad];
}



- (void) viewDidUnload {
  [super viewDidUnload];
}



- (void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear: animated];
  
  // provide a default title on the view's navigation bar
  self.navigationItem.title = @"Store";
  
  // add the 'restore purchases' button to the navigation bar
  UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle: @"Restore Purchases"
                                                             style: UIBarButtonItemStylePlain target: self
                                                            action: @selector(restorePurchasesButtonClicked)];
  button.enabled = NO;
  self.navigationItem.rightBarButtonItem = button;
  self.restorePurchasesButton = button;
  
  // remove any existing observer
  [[SEStatelyNotificationRobot sharedRobot] removeHandlerWithID: SECrackRockTransactionStateObserver_RestorePurchasesButton];
  [[SEStatelyNotificationRobot sharedRobot] removeHandlerWithID: SECrackRockProductsRequestStateObserver_SECrackRockViewController];
  
  __bryn_weak SECrackRockViewController *weakSelf = self;
  [[SEStatelyNotificationRobot sharedRobot] handleStateOf: SECrackRockState_TransactionState
                                                handlerID: SECrackRockTransactionStateObserver_RestorePurchasesButton
                                                  onQueue: [NSOperationQueue mainQueue]
                                                withBlock: ^(SEState newState, NSDictionary *stateInfo) {
                                                  
                                                    NSLog(@"handler for TransactionState state change: newState == %d", newState);
                                                    __strong SECrackRockViewController *strongSelf = weakSelf;
                                                    
                                                    BOOL enabled = (newState == SECrackRockTransactionStateAsleep);
                                                    strongSelf.restorePurchasesButton.enabled = enabled;
                                                  
                                                }];
  
  [[SEStatelyNotificationRobot sharedRobot] handleStateOf: SECrackRockState_ProductsRequestState
                                                handlerID: SECrackRockProductsRequestStateObserver_SECrackRockViewController
                                                  onQueue: [NSOperationQueue mainQueue]
                                                withBlock: ^(SEState newState, NSDictionary *stateInfo) {
                                                  
                                                    NSLog(@"handler for ProductsRequestState state change: newState == %d", newState);
                                                    __strong SECrackRockViewController *strongSelf = weakSelf;
                                                    if (newState == SECrackRockProductsRequestStateFinished) {
                                                      [strongSelf didFinishPreparingProductInfo];
                                                    }
                                                  
                                                }];

  // register for the notifications posted by SECrackRock
  [self registerForAllNotifications];
}



- (void) viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
    
  // remove all notification handlers and SEStatelyNotificationRobot state handlers
  [self unregisterForAllNotifications];
  [[SEStatelyNotificationRobot sharedRobot] removeHandlerWithID: SECrackRockTransactionStateObserver_SpringboardView];
  [[SEStatelyNotificationRobot sharedRobot] removeHandlerWithID: SECrackRockTransactionStateObserver_RestorePurchasesButton];
  [[SEStatelyNotificationRobot sharedRobot] removeHandlerWithID: SECrackRockProductsRequestStateObserver_SECrackRockViewController];
}



- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark- Notification handling
#pragma mark-

- (void) registerForAllNotifications {
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(successfulPurchase:)
                                               name: SECrackRockNotification_SuccessfulPurchase      object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(cancelledPurchase:)
                                               name: SECrackRockNotification_CancelledPurchase       object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(failedPurchase:)
                                               name: SECrackRockNotification_FailedPurchase          object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(successfulRestore:)
                                               name: SECrackRockNotification_SuccessfulRestore       object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(multipleRestoreComplete:)
                                               name: SECrackRockNotification_MultipleRestoreComplete object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(incompleteRestore:)
                                               name: SECrackRockNotification_IncompleteRestore       object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(failedRestore:)
                                               name: SECrackRockNotification_FailedRestore           object:[SECrackRock sharedInstance]];
}

- (void) unregisterForAllNotifications {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SECrackRockNotification_SuccessfulPurchase object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SECrackRockNotification_CancelledPurchase object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SECrackRockNotification_FailedPurchase object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SECrackRockNotification_SuccessfulRestore object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SECrackRockNotification_MultipleRestoreComplete object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SECrackRockNotification_IncompleteRestore object:[SECrackRock sharedInstance]];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SECrackRockNotification_FailedRestore object:[SECrackRock sharedInstance]];
}



#pragma mark- BlingLord springboard view (+ misc. graphics)
#pragma mark-

- (BOOL) shouldDisplayProductInStore:(SECrackRockProduct *)product {
  NSAssert(product != nil, @"product argument is nil.");
  
  BOOL shouldDisplayItem = YES;
  
  switch (product.purchaseStatus) {
    // products that returned errors or nothing when app store was queried
    default:
    case SECrackRockPurchaseStatusUnknown:
    case SECrackRockPurchaseStatusError:
      shouldDisplayItem = NO;
      break;
      
    // paid/purchaseable products
    case SECrackRockPurchaseStatusNonfreePurchased:
    case SECrackRockPurchaseStatusNonfreeUnpurchased: {
      shouldDisplayItem = product.isAvailableInStore;
    } break;
      
    // free items might as well always show up, right?
    case SECrackRockPurchaseStatusFree:
      shouldDisplayItem = YES;
      break;
  }
  
  return shouldDisplayItem;
}



- (UIImage *) purchaseableIndicatorForProduct: (SECrackRockProduct *)product {
  return nil;
}


- (UIImage *) iconForProduct:(SECrackRockProduct *)product withPurchaseableIndicator:(BOOL)withPurchaseableIndicator {
  NSAssert(product != nil, @"product argument is nil.");
  
  // load the product's icon, add the 'purchaseable' indicator overlay if it hasn't been purchased yet
  UIImage *icon = UIImageWithBundlePNG(product.thumbnailPNGFilename);
  NSAssert(icon != nil, @"icon is nil.");   
  
  if (withPurchaseableIndicator == YES) {
    UIImage *purchaseableIndicator = [self purchaseableIndicatorForProduct: product];
    
    // if a purchaseableIndicator was provided, replace the existing icon with one that has the indicator overlaid
    if (purchaseableIndicator != nil) {
      icon = [icon imageWithOverlay:purchaseableIndicator atPosition:CGPointZero withSize:icon.size];
    }
  }
  
  return icon;
}


- (NSMutableArray *) initializeMenuItems {
  
  // create an array of SEBlingLord objects
  NSMutableArray *items = [NSMutableArray arrayWithCapacity: [SECrackRock sharedInstance].sortedProductIDs.count];
  
  __bryn_weak SECrackRockViewController *weakSelf = self;
  for (NSString *productID in [SECrackRock sharedInstance].sortedProductIDs) {
    SECrackRockProduct *product = [SECrackRock sharedInstance].productsByID[ productID ];
    
    // make sure we want to display each product (i.e. the request to the app store was successful) 
    if ([self shouldDisplayProductInStore: product] == NO)
      continue;
    
    // generate the product's icon
    BOOL showPurchaseableIndicator = (product.purchaseStatus == SECrackRockPurchaseStatusNonfreeUnpurchased);
    UIImage *icon = [self iconForProduct:product withPurchaseableIndicator:showPurchaseableIndicator];

    // initialize the menu item object
    SECrackRockMenuItem *menuItem =
      [[SECrackRockMenuItem alloc] initWithFrame: CGRectMake(0.0f, 0.0f, self.springboardItemSize.width, self.springboardItemSize.height)
                                           title: product.readableName image: icon
                                       removable: NO
                                 tapHandlerBlock: ^{
                                     __strong SECrackRockViewController *strongSelf = weakSelf;
                                     SECrackRockProduct *blockProduct = [SECrackRock sharedInstance].productsByID[ productID ];
                                     NSAssert(blockProduct != nil, @"blockProduct is nil.");
                                     
                                     [strongSelf iconWasTappedForProduct: blockProduct];
                                 }];
      
    menuItem.productID = product.productID;
    [items addObject: menuItem];
  }
  
  return items;
}



- (SECrackRockMenuItem *) menuItemForProductID:(NSString *)productID {
  if (productID != nil) {
    for (SECrackRockMenuItem *menuItem in self.springboardView.items) {
      if ([productID isEqualToString:menuItem.productID])
        return menuItem;
    }
  }
  return nil;
}



#pragma mark- User interaction
#pragma mark-

- (void) iconWasTappedForProduct: (SECrackRockProduct *)product {
  NSAssert(product != nil, @"product argument is nil.");
  
  switch (product.purchaseStatus) {
    case SECrackRockPurchaseStatusFree:
    case SECrackRockPurchaseStatusNonfreePurchased:
      // this is where you'd probably want to let the user use the purchase
      break;
      
    case SECrackRockPurchaseStatusNonfreeUnpurchased: {
      [self tryToPurchaseProduct: product.productID];
    } break;
      
    default: {
      NSAssert(NO, @"SECrackRockProduct purchaseStatus is unknown.");
      [[[UIAlertView alloc] initWithTitle: @"Our bad"
                                  message: @"An error occurred, and we don't know exactly why.  Maybe try again later!"
                                 delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } break;
  }
}



#pragma mark- Public methods for purchasing/restoring
#pragma mark-

/**
 * Attempt to purchase a product with a given product ID.
 */

- (void) tryToPurchaseProduct:(NSString *)productID {
  
  bool success = [[SECrackRock sharedInstance] tryToPurchaseProduct:productID];
  if (success == NO) {
    // Returned NO, so notify user that In-App Purchase is Disabled in their Settings.
    [[[UIAlertView alloc] initWithTitle: @"Allow Purchases"
                                message: @"You must first enable In-App Purchase in your iOS Settings before making this purchase."
                               delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    
  }
}



/**
 * Attempt to restore a customer's previous non-consumable or subscription
 * In-App Purchase with a given product ID.  Required if a user reinstalled app
 * on same device or another device.
 */

- (void) tryToRestorePurchase: (NSString *)productID {
  
  bool success = [[SECrackRock sharedInstance] tryToRestorePurchase:productID];
  
  if (success == NO) {
    [[[UIAlertView alloc] initWithTitle: @"Allow Purchases"
                                message: @"You must first enable In-App Purchase in your iOS Settings before restoring a previous purchase."
                               delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show]; 
  }
}


/**
 * Attempt to restore all purchases made with the current apple ID.
 */

- (void) tryToRestoreAllPurchases {
  
  bool success = [[SECrackRock sharedInstance] tryToRestoreAllPurchases];
  
  if (success == NO) {
    // notify user that In-App Purchase is Disabled in their Settings.
    [[[UIAlertView alloc] initWithTitle: @"Allow Purchases"
                                message: @"You must first enable In-App Purchase in your iOS Settings before restoring a previous purchase."
                               delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];

  }
}




/**
 * Called in response to SECrackRockNotification_DidFinishPreparingProductInfo.
 *
 * Sets up the springboard view and creates a menu item for each product that
 * was verified as purchaseable by the app store.
 *
 * Note: if you override this method in a subclass, you really oughta call the
 * superclass's method (i.e., [super didFinishPreparingProductInfo]).
 */

- (void) didFinishPreparingProductInfo {
  
  // initialize the menu items
  
  NSMutableArray *menuItems = [self initializeMenuItems];
  
  NSAssert(menuItems != nil, @"menuItems array is nil.");
  
  // pass the array to a new instance of SEBlingLord and add it to the view
  
  CGRect frame;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    frame = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f - 20.0f); // 20.0f = status bar
  else
    frame = CGRectMake(0.0f, 0.0f, 768.0f, 1024.0f - 20.0f); // @@TODO: is this correct for an iPad?
  
  SEBlingLordView *board = [[SEBlingLordView alloc] initWithFrame:frame];
  board.itemSize = self.springboardItemSize;
  board.itemMargins = self.springboardItemMargins; //  CGSizeMake(15.0f, 15.0f);
  board.outerMargins = self.springboardOuterMargins; // CGSizeMake(10.0f, 10.0f);
  board.allowsEditing = NO;
  [board addMenuItems:menuItems];
  
  
  if (self.springboardView != nil) {
    [self.springboardView removeFromSuperview];
    self.springboardView = nil;
  }
  
  [self.view addSubview: board];
  self.springboardView = board;
  
  
  // register a block to respond to the transaction state (i.e. whether or not a
  // transaction with the app store servers is pending).  this block toggles
  // user interaction with the springboard off when a transaction is underway,
  // and back on when it is done.
  
  [[SEStatelyNotificationRobot sharedRobot] removeHandlerWithID: SECrackRockTransactionStateObserver_SpringboardView]; // remove any existing observer
  
  __bryn_weak SECrackRockViewController *weakSelf = self;
  [[SEStatelyNotificationRobot sharedRobot] handleStateOf: SECrackRockState_TransactionState
                                                handlerID: SECrackRockTransactionStateObserver_SpringboardView
                                                  onQueue: [NSOperationQueue mainQueue]
                                                withBlock: ^(SEState newState, NSDictionary *stateInfo) {
                                                  
                                                    __strong SECrackRockViewController *strongSelf = weakSelf;
                                                    BOOL enabled = (newState == SECrackRockTransactionStateAsleep);
                                                    strongSelf.springboardView.userInteractionEnabled = enabled;
                                                  
                                                }];
}



/**
 * Called when the user has clicked the 'restore all purchases' button.  Can
 * be rigged up to a button using Interface Builder, but does not need to be.
 */

- (IBAction) restorePurchasesButtonClicked {
  [self tryToRestoreAllPurchases];
}



/**
 *
 */

- (void) recreateProductIconWithoutPurchaseableIndicator:(NSString *)productID {
  NSAssert(productID != nil, @"productID argument is nil.");

  // recreate the product's icon without the purchaseable indicator
  
  __bryn_weak SECrackRockViewController *weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong SECrackRockViewController *strongSelf = weakSelf;
    
    SECrackRockMenuItem *springboardMenuItem = [strongSelf menuItemForProductID:productID];
    SECrackRockProduct *product = [SECrackRock sharedInstance].productsByID[ productID ];
    
    springboardMenuItem.imageView.image = [strongSelf iconForProduct:product withPurchaseableIndicator:NO];
  });
  
}


- (void) displayAlertToUserWithTitle:(NSString *)title text:(NSString *)text dismissText:(NSString *)dismissText {
  [[[UIAlertView alloc] initWithTitle:title message:text delegate:nil cancelButtonTitle:dismissText otherButtonTitles:nil] show];
}



- (void) successfulPurchase:(NSNotification *)notification {
  NSAssert(notification != nil, @"notification argument is nil.");
  
  NSString *productID = notification.userInfo[ SECrackRockUserInfoKey_ProductID ];
  [self recreateProductIconWithoutPurchaseableIndicator:productID];
    
  // notify the user that the purchase was successful
  [self displayAlertToUserWithTitle: @"Thank You!"
                               text: @"Your purchase was successful!"
                        dismissText: @"OK"];
}



- (void) cancelledPurchase:(NSNotification *)notification {
  NSAssert(notification != nil, @"notification argument is nil.");
  // no-op
}



- (void) failedPurchase:(NSNotification *)notification {
  NSAssert(notification != nil, @"notification argument is nil.");
  
  [self displayAlertToUserWithTitle: @"Purchase Failed"
                               text: @"There was a transaction error. Please try again later, or contact customer support for assistance."
                        dismissText: @"OK"];
}



- (void) successfulRestore:(NSNotification *)notification {
  NSAssert(notification != nil, @"notification argument is nil.");
  
  NSString *productID = notification.userInfo[ SECrackRockUserInfoKey_ProductID ];
  [self recreateProductIconWithoutPurchaseableIndicator:productID];
  
  // if it's a single item restore, notify the user that the restore was successful
  if (NO == [SECrackRock sharedInstance].isCurrentlyRestoringMultiplePurchases) {
    [self displayAlertToUserWithTitle: @"Thank You!"
                                 text: @"Your purchase was successfully restored!"
                          dismissText: @"OK"];
  }
}



- (void) multipleRestoreComplete:(NSNotification *)notification {
  NSAssert(notification != nil, @"notification argument is nil.");
  
  [self displayAlertToUserWithTitle: @"Success!"
                               text: @"Your purchases were successfully restored!"
                        dismissText: @"OK"];
}



- (void) incompleteRestore:(NSNotification *)notification {
  NSAssert(notification != nil, @"notification argument is nil.");
  
  [self displayAlertToUserWithTitle: @"Restore Issue"
                               text: @"A prior purchase transaction could not be found. To restore the purchased product, tap the product's icon. Paid customers will NOT be charged again, but the purchase will be restored."
                        dismissText: @"OK"];
}



- (void) failedRestore:(NSNotification *)notification {
  NSAssert(notification != nil, @"notification argument is nil.");
  
  [self displayAlertToUserWithTitle: @"Restore Stopped"
                               text: @"Either you cancelled the request or your prior purchase could not be restored. Please try again later, or contact customer support for assistance."
                        dismissText: @"OK"];
}





@end






