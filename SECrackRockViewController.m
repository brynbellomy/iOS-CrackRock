//
//  SECrackRockViewController.m
//  SECrackRock in-app purchase framework
//
//  Created by bryn austin bellomy on 6/19/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "SECrackRockViewController.h"
#import "SECrackRockProduct.h"
#import "SEBlingLordView.h"
#import "SEBlingLordMenuItem.h"
#import "EBPurchase.h"
#import "SEStatelyNotificationRobot.h"
#import "UIImage+SECrackRock.h"
//#import "MBProgressHUD.h" // @@TODO: implement MBProgressHUD


typedef enum {
  SECrackRockTransactionStateInProgress = (1 << 0),
  SECrackRockTransactionStateAsleep = (1 << 1)
} SECrackRockTransactionState;

static NSString *const SECrackRockState_TransactionState = @"SECrackRockState_TransactionState";





@implementation SECrackRockMenuItem
  @synthesize productID = _productID;
@end



@interface SECrackRockViewController ()
  @property (nonatomic, strong, readwrite) NSArray *freeProducts;
  @property (nonatomic, strong, readwrite) NSArray *paidProducts;
  @property (nonatomic, assign, readwrite) NSUInteger productRequestsReturned;
  @property (nonatomic, strong, readwrite) id inAppPurchaseProductInfoIsLoadedNotificationHandler;
  @property (nonatomic, strong, readwrite) NSMutableArray *productList;
  @property (nonatomic, strong, readwrite) NSMutableArray *purchasedItems;
  @property (nonatomic, strong, readwrite) NSMutableDictionary *purchaseHelpers;
  @property (nonatomic, strong, readwrite) EBPurchase *restorePurchaseHelper;
  @property (nonatomic, weak,   readwrite) UIBarButtonItem *restorePurchasesButton;
  @property (nonatomic, assign, readwrite) BOOL isCurrentlyRestoringMultiplePurchases;
  @property (nonatomic, strong, readwrite) id transactionStateObserverHandle;
@end


@implementation SECrackRockViewController

@synthesize purchaseHelpers = _purchaseHelpers;
@synthesize springboardView = _springboardView;
@synthesize productList = _productList;
@synthesize purchasedItems = _purchasedItems;
@synthesize productRequestsReturned = _productRequestsReturned;
@synthesize inAppPurchaseProductInfoIsLoadedNotificationHandler = _inAppPurchaseProductInfoIsLoadedNotificationHandler;
@synthesize freeProducts = _freeProducts;
@synthesize paidProducts = _paidProducts;
@synthesize restorePurchaseHelper = _restorePurchaseHelper;
@synthesize restorePurchasesButton = _restorePurchasesButton;
@synthesize isCurrentlyRestoringMultiplePurchases = _isCurrentlyRestoringMultiplePurchases;
@synthesize transactionStateObserverHandle = _transactionStateObserverHandle;
@synthesize springboardItemSize = _springboardItemSize;
@synthesize springboardItemMargins = _springboardItemMargins;
@synthesize springboardOuterMargins = _springboardOuterMargins;



#pragma mark- View lifecycle
#pragma mark-

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
      self.isCurrentlyRestoringMultiplePurchases = NO;
      self.springboardItemSize = CGSizeMake(83.0f, 103.0f);
    }
    return self;
}



- (void)viewDidLoad {
  [super viewDidLoad];
  
  // initialize the global lists of free, purchased, and purchaseable products
  self.freeProducts = [self initializeFreeProducts];
  self.paidProducts = [self initializePaidProducts];
  
  // create instances of EBPurchase for all purchaseable items
  self.purchaseHelpers = [NSMutableDictionary dictionaryWithCapacity: self.paidProducts.count];
  for (SECrackRockProduct *product in self.paidProducts) {
    EBPurchase *purchaseHelper = [[EBPurchase alloc] init];
    purchaseHelper.delegate = self;
    [self.purchaseHelpers setObject:purchaseHelper forKey:product.productID];
  }
}



- (void) viewDidUnload {
  [super viewDidUnload];
  
  // always gotta unset delegate relationships!
  for (EBPurchase *purchaseHelper in self.purchaseHelpers)
    purchaseHelper.delegate = nil;
  
  self.purchaseHelpers = nil;
  
  // we recreate these in viewDidLoad anyway, so release them
  self.freeProducts = nil;
  self.paidProducts = nil;
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
  
  __weak SECrackRockViewController *weakSelf = self;
  [[SEStatelyNotificationRobot sharedInstance] respondToState: SECrackRockState_TransactionState
                                             withIdentifier: @"restorePurchasesButton"
                                                    onQueue: [NSOperationQueue mainQueue]
                                                  withBlock: ^(NSInteger state) {
                                                    __strong SECrackRockViewController *strongSelf = weakSelf;
                                                    
                                                    BOOL enabled = (state == SECrackRockTransactionStateAsleep);
                                                    if (enabled == YES) NSLog(@"***** restorePB: enabled == YES");
                                                    else NSLog(@"***** restorePB: enabled == NO");
                                                    strongSelf.restorePurchasesButton.enabled = enabled;
                                                  }];
  
  // create a local, merged version of the product list that's sorted into:
  // 1) free, 2) purchased, and finally, 3) not-yet-purchased products
  self.productList = [self createSortedProductList];
  
  // if there are actual, non-free in-app purchases to retrieve from apple,
  // watch for the notification telling us that all of that info has been
  // received
  if (self.paidProducts != nil && self.paidProducts.count > 0) {
    self.inAppPurchaseProductInfoIsLoadedNotificationHandler =
      [[NSNotificationCenter defaultCenter] addObserverForName: SECrackRockNotification_iapProductInfoIsLoaded
                                                        object: nil
                                                         queue: [NSOperationQueue mainQueue]
                                                    usingBlock: ^(NSNotification *note) {
                                                      // We're done retrieving product info from Apple, so populate and display the SEBlingLord view
                                                      __strong SECrackRockViewController *strongSelf = weakSelf;
                                                      [strongSelf didFinishPreparingProductInfo];
                                                    }];
  }
  else {
    [self didFinishPreparingProductInfo];
  }
  
  // Request In-App Purchase product info and availability
  [self requestAllInAppPurchaseProductInfo];
}



- (void) viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  // this will have to be recreated anyway, so release it
  self.productList = nil;
  
  // remove all notification handlers
  if (self.inAppPurchaseProductInfoIsLoadedNotificationHandler != nil) {
    [[NSNotificationCenter defaultCenter] removeObserver: self.inAppPurchaseProductInfoIsLoadedNotificationHandler];
    self.inAppPurchaseProductInfoIsLoadedNotificationHandler = nil;
  }
  
  // ... including SEStatelyNotificationRobot state handlers
  [[SEStatelyNotificationRobot sharedInstance] removeObserverWithIdentifier: @"springboardView"];
  [[SEStatelyNotificationRobot sharedInstance] removeObserverWithIdentifier: @"restorePurchasesButton"];
}






- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark- BlingLord springboard view (+ misc. graphics)
#pragma mark-

- (BOOL) shouldDisplayProductInStore:(SECrackRockProduct *)product {
  
  BOOL shouldDisplayItem = YES;
  
  switch (product.purchaseStatus) {
    // products that returned errors or nothing when app store was queried
    case SECrackRockPurchaseStatusUnknown:
    case SECrackRockPurchaseStatusError:
      shouldDisplayItem = NO;
      break;
      
    // paid/purchaseable products
    case SECrackRockPurchaseStatusNonfreePurchased:
    case SECrackRockPurchaseStatusNonfreeUnpurchased: {
      shouldDisplayItem = product.isAvailableInStore;
    } break;
      
    // free items might as well always show up
    case SECrackRockPurchaseStatusFree:
      shouldDisplayItem = YES;
      break;
      
    default:
      shouldDisplayItem = NO;
      break;
  }
  
  return shouldDisplayItem;
}



- (UIImage *) purchaseableIndicatorForProduct: (SECrackRockProduct *)product {
  return nil;
}


- (UIImage *) iconForProduct:(SECrackRockProduct *)product withPurchaseableIndicator:(BOOL)withPurchaseableIndicator {
  // load the product's icon, add the 'purchaseable' indicator overlay if it hasn't been purchased yet
  UIImage *icon = UIImageWithBundlePNG(product.thumbnailPNGFilename);
  
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
  NSMutableArray *items = [NSMutableArray arrayWithCapacity: self.productList.count];
  
  __weak SECrackRockViewController *weakSelf = self;
  for (SECrackRockProduct *product in self.productList) {
    
    // make sure we want to display each product (i.e. the request to the app store was successful) 
    if ([self shouldDisplayProductInStore: product] == NO)
      continue;
    
    // generate the product's icon
    BOOL showPurchaseableIndicator = (product.purchaseStatus == SECrackRockPurchaseStatusNonfreeUnpurchased);
    NSLog(@"ppppp: %@ (show = %@)", product.productID, [NSNumber numberWithBool:showPurchaseableIndicator]);
    UIImage *icon = [self iconForProduct:product withPurchaseableIndicator:showPurchaseableIndicator];

    // initialize the menu item object
    NSString *productID = product.productID;
    SECrackRockMenuItem *menuItem =
      [[SECrackRockMenuItem alloc] initWithFrame: CGRectMake(0.0f, 0.0f, self.springboardItemSize.width, self.springboardItemSize.height)
                                        title: product.readableName image: icon
                                    removable: NO canTriggerEditing: NO
                              tapHandlerBlock: ^{
                                  __strong SECrackRockViewController *strongSelf = weakSelf;
                                  SECrackRockProduct *blockProduct = [strongSelf getProductForProductID:productID];
                                  
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
      if (SESameStrings(productID, menuItem.productID))
        return menuItem;
    }
  }
  return nil;
}



#pragma mark- User interaction
#pragma mark-

- (void) iconWasTappedForProduct: (SECrackRockProduct *)product {
  
  switch (product.purchaseStatus) {
    case SECrackRockPurchaseStatusFree:
    case SECrackRockPurchaseStatusNonfreePurchased:
      // this is where you'd probably want to let the user use the purchase
      break;
      
    case SECrackRockPurchaseStatusNonfreeUnpurchased: {
      [self tryToPurchaseProduct: product.productID];
    } break;
      
    default: {
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
  
  [self storeTransactionWillBegin];
  
  // First, ensure that the SKProduct that was requested by
  // the EBPurchase requestProduct method in the viewWillAppear 
  // event is valid before trying to purchase it.
  
  EBPurchase *productPurchaseHelper = [self.purchaseHelpers objectForKey:productID];
  if (productPurchaseHelper.validProduct != nil)
  {
    // Then, call the purchase method.
    
    if (![productPurchaseHelper purchaseProduct: productPurchaseHelper.validProduct])
    {
      // Returned NO, so notify user that In-App Purchase is Disabled in their Settings.
      [[[UIAlertView alloc] initWithTitle: @"Allow Purchases"
                                  message: @"You must first enable In-App Purchase in your iOS Settings before making this purchase."
                                 delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
      
      [self storeTransactionDidEnd];
    }
  }
}



/**
 * Attempt to restore a customer's previous non-consumable or subscription
 * In-App Purchase with a given product ID.  Required if a user reinstalled app
 * on same device or another device.
 */

- (void) tryToRestorePurchase: (NSString *)productID {
  
  [self storeTransactionWillBegin];
  
  EBPurchase *productPurchaseHelper = [self.purchaseHelpers objectForKey:productID];
  
  // Call restore method.
  if (![productPurchaseHelper restorePurchase])
  {
    // Returned NO, so notify user that In-App Purchase is Disabled in their Settings.
    [[[UIAlertView alloc] initWithTitle: @"Allow Purchases"
                                message: @"You must first enable In-App Purchase in your iOS Settings before restoring a previous purchase."
                               delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
    
    [self storeTransactionDidEnd];
  }
}



/**
 * Attempt to restore all purchases made with the current apple ID.
 */

- (void) tryToRestoreAllPurchases {
  
  [self storeTransactionWillBegin];
  self.isCurrentlyRestoringMultiplePurchases = YES;
  
  // set up a special EBPurchase object that's not tied to one individual productID
  self.restorePurchaseHelper = [[EBPurchase alloc] init];
  self.restorePurchaseHelper.delegate = self;
  
  // Call restore method
  if (![self.restorePurchaseHelper restorePurchase])
  {
    // Returned NO, so notify user that In-App Purchase is Disabled in their Settings.
    [[[UIAlertView alloc] initWithTitle: @"Allow Purchases"
                                message: @"You must first enable In-App Purchase in your iOS Settings before restoring a previous purchase."
                               delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
    
    self.isCurrentlyRestoringMultiplePurchases = NO;
    [self storeTransactionDidEnd];
  }
}



#pragma mark- Product data
#pragma mark-

/**
 * Must be overridden by subclasses.  This method must return an NSArray
 * containing SECrackRockItem objects representing the free items to which the user
 * already has access by default upon installing the app.
 */

- (NSArray *) initializeFreeProducts {
  return [NSArray array];
}



/**
 * Must be overridden by subclasses.  This method must return an NSArray
 * containing SECrackRockItem objects representing the purchaseable/paid items that
 * the user is able to buy.
 */

- (NSArray *) initializePaidProducts {
  return [NSArray array];
}



/**
 * Convenience method to fetch a product based on the provided productID.
 */

- (SECrackRockProduct *) getProductForProductID:(NSString *)productID {
  if (productID != nil) {
    for (SECrackRockProduct *product in self.productList) {
      if (SESameStrings(productID, product.productID))
        return product;
    }
  }
  return nil;
}



/**
 * Creates an array of all visible products (free and purchaseable) in the order
 * that they ought to appear in the springboard view.
 */

- (NSMutableArray *) createSortedProductList {
  
  int i = 0;
  NSMutableArray *productList = [NSMutableArray new];
  
  // Populate the arrays that the SEBlingLord view draws on for its contents:
  
  // ... first add all of the free/default products to the list
  for (SECrackRockProduct *product in self.freeProducts) {
    SECrackRockProduct *productCopy = [product copy];
    productCopy.purchaseStatus = SECrackRockPurchaseStatusFree;
    [productList addObject: productCopy];
    i++;
  }
  
  // ... then add all of the purchased products to the list
  for (SECrackRockProduct *product in self.paidProducts) {
    if ([self hasProductBeenPurchased: product.productID] == YES) {
      SECrackRockProduct *productCopy = [product copy];
      productCopy.purchaseStatus = SECrackRockPurchaseStatusNonfreePurchased;
      productCopy.isAvailableInStore = NO; // set to NO until we get confirmation of YES from apple
      [productList addObject: productCopy];
      i++;
    }
  }
  
  // ... finally add all of the unpurchased products to the list
  for (SECrackRockProduct *product in self.paidProducts) {
    if ([self hasProductBeenPurchased: product.productID] == NO) {
      SECrackRockProduct *productCopy = [product copy];
      productCopy.purchaseStatus = SECrackRockPurchaseStatusNonfreeUnpurchased;
      productCopy.isAvailableInStore = NO; // set to NO until we get confirmation of YES from apple
      [productList addObject: productCopy];
      i++;
    }
  }
  
  return productList;
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
    if (_purchasedItems == nil) {
      _purchasedItems = [NSMutableArray new];
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

- (BOOL) hasProductBeenPurchased: (NSString *)productID {
  return [self.purchasedItems containsObject: productID];
}



/**
 * Set whether or not a given product has been purchased (written into the
 * locally-cached record of purchased items in NSUserDefaults).
 */

- (void) setProduct:(NSString *)productID hasBeenPurchased:(BOOL)hasBeenPurchased {
  if (hasBeenPurchased == YES)
    [self.purchasedItems addObject: productID];
  else
    [self.purchasedItems removeObject: productID];
  
  [[NSUserDefaults standardUserDefaults] setObject: self.purchasedItems forKey: SECrackRockUserDefaultsKey_purchasedItems];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // also update the productList array for convenience's sake
  NSUInteger index = [self.productList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
    SECrackRockProduct *product = obj;
    if (SESameStrings(productID, product.productID)) {
      *stop = YES;
      return YES;
    }
    return NO;
  }];
  
  SECrackRockProduct *product = [self.productList objectAtIndex:index];
  product.purchaseStatus = (hasBeenPurchased ? SECrackRockPurchaseStatusNonfreePurchased : SECrackRockPurchaseStatusNonfreeUnpurchased);
}



#pragma mark- Purchasing/restoring convenience methods
#pragma mark-

/**
 * Requests product info for all products registered using the subclass's
 * -initializeFreeProducts and -initializePaidProducts methods.
 */

- (void) requestAllInAppPurchaseProductInfo {
  
  [self storeTransactionWillBegin];
  
  // reset the response counter
  self.productRequestsReturned = 0;
  
  // send a request for each product
  for (SECrackRockProduct *product in self.paidProducts) {
    EBPurchase *purchaseHelper = [self.purchaseHelpers objectForKey:product.productID];
    
    NSLog(@">> requesting product: %@", product.productID);
    NSAssert(purchaseHelper != nil, @"purchaseHelper == nil");
    
    if (![purchaseHelper requestProduct: product.productID]) {
      NSLog(@">> not available: %@", product.productID);
      // product is not available
      
      // @@TODO: ?? probably already mostly handled by EBPurchase
      // @@TODO: maybe remove the purchase from the view or grey it out or something
    }
  }
}



/**
 * Sets up the springboard view and creates a menu item for each product that
 * was verified as purchaseable by the app store.
 *
 * Note: if you override this method in a subclass, you really oughta call the
 * superclass's method (i.e., [super didFinishPreparingProductInfo]).
 */

- (void) didFinishPreparingProductInfo {
  
  // initialize the menu items
  
  NSMutableArray *menuItems = [self initializeMenuItems];
  
  
  // pass the array to a new instance of SEBlingLord and add it to the view

  CGRect frame;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
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
  
  [[SEStatelyNotificationRobot sharedInstance] removeObserverWithIdentifier: @"springboardView"]; // remove any existing observer
  
  __weak SECrackRockViewController *weakSelf = self;
  [[SEStatelyNotificationRobot sharedInstance] respondToState: SECrackRockState_TransactionState
                                             withIdentifier: @"springboardView"
                                                    onQueue: [NSOperationQueue mainQueue]
                                                  withBlock: ^(NSInteger state) {
                                                    
                                                    __strong SECrackRockViewController *strongSelf = weakSelf;
                                                    BOOL enabled = (state == SECrackRockTransactionStateAsleep);
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



#pragma mark- UI interactivity toggle on transaction begin/end
#pragma mark-

- (void) enableUserInteractionAfterTransaction {
  self.restorePurchasesButton.enabled = YES;
  self.springboardView.userInteractionEnabled = YES;
}



- (void) disableUserInteractionDuringTransaction {
  self.restorePurchasesButton.enabled = NO;
  self.springboardView.userInteractionEnabled = NO;
}



- (void) storeTransactionWillBegin {
  [[SEStatelyNotificationRobot sharedInstance] postNotification: SECrackRockState_TransactionState
                                                    withState: SECrackRockTransactionStateInProgress];
}



- (void) storeTransactionDidEnd {
  [[SEStatelyNotificationRobot sharedInstance] postNotification: SECrackRockState_TransactionState
                                                    withState: SECrackRockTransactionStateAsleep];
}



- (void) initializeTransactionStateObserver {
  __weak SECrackRockViewController *weakSelf = self;
  
  [[SEStatelyNotificationRobot sharedInstance]
          respondToState: SECrackRockState_TransactionState
          withIdentifier: @"restorePurchasesButton"
                 onQueue: [NSOperationQueue mainQueue]
               withBlock: ^(NSInteger state) {
           
                 __strong SECrackRockViewController *strongSelf = weakSelf;
                 if (state == SECrackRockTransactionStateInProgress)
                   [strongSelf disableUserInteractionDuringTransaction];
                 else if (state == SECrackRockTransactionStateAsleep)
                   [strongSelf enableUserInteractionAfterTransaction];
               }];
}



- (void) destroyTransactionStateObserver {
  [[SEStatelyNotificationRobot sharedInstance] removeObserverWithIdentifier: @"restorePurchasesButton"];
}



#pragma mark- EBPurchaseDelegate Methods
#pragma mark-

/**
 * Request for product information to app store servers has returned. If
 * the product was found and is available for purchase, the arguments to
 * this function will all contain valid values.  If the product was not
 * found or is unavailable for some other reason, all of the arguments
 * will be nil.
 */

- (void) requestedProduct: (EBPurchase *)ebp
               identifier: (NSString *)productID
                     name: (NSString *)productName
                    price: (NSString *)productPrice
              description: (NSString *)productDescription {
  
  NSLog(@"ViewController requestedProduct");
  
  // the request succeeded and the product is available for purchase
  if (productID != nil) {
    
    // find the product in our local product list and update it with whatever apple sent
    NSUInteger i = 0;
    SECrackRockProduct *updatedProduct = nil;
    for (SECrackRockProduct *product in self.productList) {
      
      if (SESameStrings(productID, product.productID)) {
        updatedProduct = [product copy];
        
        // Product is available: update the product's info
        if (productPrice != nil)       updatedProduct.price = productPrice;
        if (productName != nil)        updatedProduct.readableName = productName;
        if (productDescription != nil) updatedProduct.productDescription = productDescription;
        updatedProduct.isAvailableInStore = YES;
        
        break;
      }
      i++;
    }
      
    if (updatedProduct != nil)
      // update the product in self.productList
      [self.productList replaceObjectAtIndex:i withObject:updatedProduct];
    else
      // the productID returned by the app store servers couldn't
      // be found in the productList (this would be bizarre)
      NSLog(@"Product unavailable");
  }
  else
    // the request failed and the product is unavailable
    NSLog(@"Product unavailable");

  // increment the counter, see if we're done
  self.productRequestsReturned++;
  
  if (self.productRequestsReturned >= self.paidProducts.count) {
    [self storeTransactionDidEnd];
    
    // we're done, so post a notification
    [[NSNotificationCenter defaultCenter] postNotificationName: SECrackRockNotification_iapProductInfoIsLoaded
                                                        object: nil];
  }
}



/**
 * Helper method that contains code common to the respective handler methods for
 * successful purchases and successful restores.
 */

- (void) successfulPurchaseAndRestoreCommon:(NSString *)productID {
  
  // save a record that this has been purchased locally to the phone (ends up in NSUserDefaults)
  [self setProduct:productID hasBeenPurchased:YES];
  
  // recreate the product's icon without the purchaseable indicator
  __weak SECrackRockViewController *weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    __strong SECrackRockViewController *strongSelf = weakSelf;
    
    SECrackRockMenuItem *springboardMenuItem = [strongSelf menuItemForProductID:productID];
    SECrackRockProduct *product = [strongSelf getProductForProductID:productID];
    
    springboardMenuItem.imageView.image = [strongSelf iconForProduct:product withPurchaseableIndicator:NO];
  });
}



/**
 * Purchase request was successful, so unlock the new content for your new
 * customer and notify them that the transaction was successful.
 */

- (void) successfulPurchase: (EBPurchase *)purchaseHelper
                 identifier: (NSString *)productID
                    receipt: (NSData *)transactionReceipt {
  
  NSLog(@"ViewController successfulPurchase (productID: %@)", productID);

  [self successfulPurchaseAndRestoreCommon:productID];
  
  // notify the user that the purchase was successful
  [[[UIAlertView alloc] initWithTitle: @"Thank You!"
                              message: @"Your purchase was successful!"
                             delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
  
  [self storeTransactionDidEnd];
}


/**
 * Restore request was successful, so unlock the purchased content for your
 * customer and notify them that the transaction was successful.
 */

- (void) successfulRestore: (EBPurchase *)purchaseHelper
                identifier: (NSString *)productID
                   receipt: (NSData *)transactionReceipt {
  
  NSLog(@"ViewController successfulRestore (productID: %@)", productID);
  
  [self successfulPurchaseAndRestoreCommon:productID];
  
  // if it's a single item restore, notify the user that the restore was successful
  if (NO == self.isCurrentlyRestoringMultiplePurchases) {
    [[[UIAlertView alloc] initWithTitle: @"Thank You!"
                                message: @"Your purchase was successfully restored!"
                               delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
    
    [self storeTransactionDidEnd];
  }
}



/**
 * All restore requests in the transaction queue have succeeded.
 */

- (void) successfulMultipleRestoreComplete {
  
  // set the flag
  self.isCurrentlyRestoringMultiplePurchases = NO;
  
  // re-enable the springboard items and whatever buttons were disabled during the transaction
  [self storeTransactionDidEnd];
  
  NSLog(@"ViewController successfulMultipleRestoreComplete");
  [[[UIAlertView alloc] initWithTitle: @"Success!"
                                                        message: @"Your purchases were successfully restored."
                                                       delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
}



/**
 * Purchase or Restore request failed or was cancelled, so notify the user.
 */

- (void) failedPurchase: (EBPurchase *)purchaseHelper
                  error: (NSInteger)errorCode
                message: (NSString *)errorMessage {
  
  NSLog(@"ViewController failedPurchase");
  UIAlertView *failedAlert = [[UIAlertView alloc] initWithTitle: @"Purchase Stopped"
                                                        message: @"Either you cancelled the request or Apple reported a transaction error. Please try again later, or contact the app's customer support for assistance."
                                                       delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
  [failedAlert show];
  
  [self storeTransactionDidEnd];
}



/**
 * Restore queue did not include any transactions, so either the user has not yet made a purchase
 * or the user's prior purchase is unavailable, so notify user to make a purchase within the app.
 * If the user previously purchased the item, they will NOT be re-charged again, but it should 
 * restore their purchase. 
 */

- (void) incompleteRestore: (EBPurchase *)purchaseHelper {
  
  NSLog(@"ViewController incompleteRestore");
  [[[UIAlertView alloc] initWithTitle: @"Restore Issue"
                              message: @"A prior purchase transaction could not be found. To restore the purchased product, tap the Buy button. Paid customers will NOT be charged again, but the purchase will be restored."
                             delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
  
  [self storeTransactionDidEnd];
}



/**
 * Restore request failed or was cancelled, so notify the user.
 */

- (void) failedRestore: (EBPurchase *)purchaseHelper
                 error: (NSInteger)errorCode
               message: (NSString*)errorMessage {
  
  NSLog(@"ViewController failedRestore");
  [[[UIAlertView alloc] initWithTitle: @"Restore Stopped"
                              message: @"Either you cancelled the request or your prior purchase could not be restored. Please try again later, or contact customer support for assistance."
                             delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
  
  [self storeTransactionDidEnd];
}




@end
