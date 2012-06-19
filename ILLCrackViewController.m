//
//  ILLCrackViewController.m
//  ILLCrack in-app purchase framework
//
//  Created by bryn austin bellomy on 6/19/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "ILLCrackViewController.h"
#import "SESpringBoard.h"
#import "SEMenuItem.h"
#import "EBPurchase.h"
#import "MBProgressHUD.h" // @@TODO: implement MBProgressHUD


@interface ILLCrackViewController ()
  @property (nonatomic, strong, readwrite) NSArray *freeProducts;
  @property (nonatomic, strong, readwrite) NSArray *paidProducts;
  @property (nonatomic, assign, readwrite) NSUInteger productRequestsReturned;
  @property (nonatomic, strong, readwrite) id inAppPurchaseProductInfoIsLoadedNotificationHandler;
  @property (nonatomic, strong, readwrite) NSMutableArray *productList;
  @property (nonatomic, strong, readwrite) NSMutableArray *purchasedItems;
  @property (nonatomic, strong, readwrite) NSMutableDictionary *purchaseHelpers;
@end


@implementation ILLCrackViewController

@synthesize purchaseHelpers = _purchaseHelpers;
@synthesize springboardView = _springboardView;
@synthesize productList = _productList;
@synthesize purchasedItems = _purchasedItems;
@synthesize productRequestsReturned = _productRequestsReturned;
@synthesize inAppPurchaseProductInfoIsLoadedNotificationHandler = _inAppPurchaseProductInfoIsLoadedNotificationHandler;
@synthesize freeProducts = _freeProducts;
@synthesize paidProducts = _paidProducts;



#pragma mark- View lifecycle
#pragma mark-

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
  for (NSDictionary *product in self.paidProducts) {
    EBPurchase *purchaseHelper = [[EBPurchase alloc] init];
    purchaseHelper.delegate = self;
    self.purchaseHelpers[ product[ ProductID ] ] = purchaseHelper;
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
  
  // provide a default title for the view
  self.navigationItem.title = @"Store";
  
  // create a local, merged version of the product list that's sorted into: 1) free, 2) purchased, and finally, 3) not-yet-purchased products
  self.productList = [self createSortedProductList];
  
  // watch for the notification telling us that all of the in app purchase info has been received from apple
  __weak ILLCrackViewController *weakSelf = self;
  self.inAppPurchaseProductInfoIsLoadedNotificationHandler =
    [[NSNotificationCenter defaultCenter] addObserverForName: ILLCrackNotification_iapProductInfoIsLoaded
                                                      object: nil
                                                       queue: [NSOperationQueue mainQueue]
                                                  usingBlock: ^(NSNotification *note) {
                                                    // We're done retrieving product info from Apple, so populate and display the SESpringBoard view
                                                    [weakSelf didReceiveAllInAppPurchaseProductInfo];
                                                  }];
  
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
}



- (void) initializeSpringboardView {
  // create an array of SEMenuItem objects
  NSMutableArray *items = [NSMutableArray array];
  
  __weak ILLCrackViewController *weakSelf = self;
  for (NSDictionary *product in self.productList) {
    NSString *iconPath = [[NSBundle mainBundle] pathForResource: product[ Thumbnail ] ofType: @"png"]; // @@TODO: refactor to framework style
    UIImage *icon = [UIImage imageWithContentsOfFile: iconPath];
    
    __block NSDictionary *productCopy = [product copy];
    SEMenuItem *menuItem = [SEMenuItem initWithTitle: productCopy[ ReadableName ] image: icon removable: NO
                                     tapHandlerBlock: ^{
                                       NSUInteger purchaseStatus = ((NSNumber *)productCopy[ PurchaseStatus ]).unsignedIntegerValue;
                                       [weakSelf iconWasTappedForProduct:productCopy purchaseStatus:purchaseStatus];
                                     }];
    [items addObject: menuItem];
  }
  
  // pass the array to a new instance of SESpringBoard and add it to the view
  SESpringBoard *board = [SESpringBoard initWithNavbarTitle: nil //@"Characters"
                                                      items: items
                                              launcherImage: [UIImage imageNamed:@"navbtn_home.png"]];
  board.allowsEditing = NO;
  if (self.springboardView != nil) {
    [self.springboardView removeFromSuperview];
    self.springboardView = nil;
  }
  [self.view addSubview: board];
  self.springboardView = board;
}



- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark- User interaction
#pragma mark-

- (void) iconWasTappedForProduct: (NSDictionary *)product
                  purchaseStatus: (ILLCrackPurchaseStatus)purchaseStatus {
  
  switch (purchaseStatus) {
    case ILLCrackPurchaseStatusFree:
    case ILLCrackPurchaseStatusNonfreePurchased:
      // this is where you'd probably want to let the user use the purchase
      break;
      
    case ILLCrackPurchaseStatusNonfreeUnpurchased: {
      [self tryToPurchaseProduct: product[ ProductID ]];
    } break;
      
    default: {
      [[[UIAlertView alloc] initWithTitle: @"Our bad"
                                  message: @"An error occurred, and we don't know exactly why.  Maybe try again later!"
                                 delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } break;
  }
}




#pragma mark- Product data
#pragma mark-

- (NSArray *) initializeFreeProducts {
  return [NSArray array];
}

- (NSArray *) initializePaidProducts {
  return [NSArray array];
}

- (NSMutableArray *) createSortedProductList {
  
  int i = 0;
  NSMutableArray *productList = [NSMutableArray new];
  
  // Populate the arrays that the SESpringBoard view draws on for its contents:
  
  // ... first add all of the free/default products to the list
  for (NSDictionary *product in self.freeProducts) {
    NSMutableDictionary *productCopy = [product mutableCopy];
    productCopy[ PurchaseStatus ] = @(ILLCrackPurchaseStatusFree);
    [productList addObject: productCopy];
    i++;
  }
  
  // ... then add all of the purchased products to the list
  for (NSDictionary *product in self.paidProducts) {
    if ([self hasProductBeenPurchased: product[ ProductID ]] == YES) {
      NSMutableDictionary *productCopy = [product mutableCopy];
      productCopy[ PurchaseStatus ] = @(ILLCrackPurchaseStatusNonfreePurchased);
      [productList addObject: productCopy];
      i++;
    }
  }
  
  // ... finally add all of the unpurchased products to the list
  for (NSDictionary *product in self.paidProducts) {
    if ([self hasProductBeenPurchased: product[ ProductID ]] == NO) {
      NSMutableDictionary *productCopy = [product mutableCopy];
      productCopy[ PurchaseStatus ] = @(ILLCrackPurchaseStatusNonfreeUnpurchased);
      [productList addObject: productCopy];
      i++;
    }
  }
  
  return productList;
}



#pragma mark- Helpers for stored list of purchased items
#pragma mark-

- (NSMutableArray *) purchasedItems {
  if (_purchasedItems == nil) {
    _purchasedItems = [[NSUserDefaults standardUserDefaults] objectForKey: ILLCrackUserDefaultsKey_purchasedItems];
    
    // if the purchased items array has never been written to disk, create an empty array and save it
    if (_purchasedItems == nil) {
      _purchasedItems = [NSMutableArray new];
      [[NSUserDefaults standardUserDefaults] synchronize];
    }
  }
  return _purchasedItems;
}


- (BOOL) hasProductBeenPurchased: (NSString *)productID {
  return [self.purchasedItems containsObject: productID];
}


- (void) setProductHasBeenPurchased: (NSString *)productID {
  [self.purchasedItems addObject: productID];
  [[NSUserDefaults standardUserDefaults] setObject: self.purchasedItems forKey: ILLCrackUserDefaultsKey_purchasedItems];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  // also update the productList array for convenience's sake
  NSUInteger idx = [self.productList indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
    NSMutableDictionary *product = obj;
    if ([productID compare: product[ ProductID ]] == NSOrderedSame) {
      *stop = YES;
      return YES;
    }
    return NO;
  }];
  NSMutableDictionary *product = self.productList[ idx ];
  product[ PurchaseStatus ] = @(ILLCrackPurchaseStatusNonfreePurchased);
}



#pragma mark- Purchasing/restoring convenience methods
#pragma mark-

- (void) requestAllInAppPurchaseProductInfo {
  
  // reset the response counter
  self.productRequestsReturned = 0;
  
  // send a request for each product
  for (NSDictionary *product in self.paidProducts) {
    NSString *productID = product[ ProductID ];
    EBPurchase *purchaseHelper = self.purchaseHelpers[ productID ];
    NSLog(@">> requesting product: %@", productID);
    if (![purchaseHelper requestProduct: productID]) {
      NSLog(@">> not available: %@", productID);
      // product is not available
      
      // @@TODO: ?? probably already mostly handled by EBPurchase
      // @@TODO: maybe remove the purchase from the view or grey it out or something
    }
  }
}


- (void) didReceiveAllInAppPurchaseProductInfo {
  [self initializeSpringboardView];
}



- (void) tryToPurchaseProduct:(NSString *)purchaseID {
  
  // First, ensure that the SKProduct that was requested by
  // the EBPurchase requestProduct method in the viewWillAppear 
  // event is valid before trying to purchase it.
  
  EBPurchase *productPurchaseHelper = self.purchaseHelpers[ purchaseID ];
  
  if (productPurchaseHelper.validProduct != nil)
  {
    // Then, call the purchase method.
    
    if (![productPurchaseHelper purchaseProduct: productPurchaseHelper.validProduct])
    {
      // Returned NO, so notify user that In-App Purchase is Disabled in their Settings.
      UIAlertView *settingsAlert = [[UIAlertView alloc] initWithTitle: @"Allow Purchases"
                                                              message: @"You must first enable In-App Purchase in your iOS Settings before making this purchase."
                                                             delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      [settingsAlert show];
    }
  }
}


- (void) tryToRestorePurchase: (NSString *)purchaseID {
  
  // Restore a customer's previous non-consumable or subscription In-App Purchase.
  // Required if a user reinstalled app on same device or another device.
  
  EBPurchase *productPurchaseHelper = self.purchaseHelpers[ purchaseID ];
  
  // Call restore method.
  if (![productPurchaseHelper restorePurchase])
  {
    // Returned NO, so notify user that In-App Purchase is Disabled in their Settings.
    UIAlertView *settingsAlert = [[UIAlertView alloc] initWithTitle: @"Allow Purchases"
                                                            message: @"You must first enable In-App Purchase in your iOS Settings before restoring a previous purchase."
                                                           delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
    [settingsAlert show];
  }
}



#pragma mark- EBPurchaseDelegate Methods
#pragma mark-

- (void) requestedProduct: (EBPurchase *)ebp
               identifier: (NSString *)productId
                     name: (NSString *)productName
                    price: (NSString *)productPrice
              description: (NSString *)productDescription {
  
  NSLog(@"ViewController requestedProduct");
  
  // find the product in our local product list and update it with whatever apple sent
  NSUInteger i = 0;
  for (NSDictionary *product in self.productList) {
    
    if ([productId compare:product[ ProductID ] ] == NSOrderedSame) {
      NSMutableDictionary *updatedProduct = [product mutableCopy];
      
      // Product is available: update the product's info
      if (productPrice != nil) {
        updatedProduct[ Price ] = productPrice;
        updatedProduct[ ReadableName ] = productName;
        updatedProduct[ Description ] = productDescription;
      }
      
      // Product is NOT available in the App Store, so notify user
      else {
        updatedProduct[ Price ] = @"N/A";
        updatedProduct[ Description ] = @"This item is not available at this time.  Please try again later.";
      }
      
      self.productList[ i ] = updatedProduct;
      break;
    }
    i++;
  }
  
  // Increment the counter, see if we're done
  self.productRequestsReturned++;
  
  if (self.productRequestsReturned >= self.paidProducts.count) {
    [[NSNotificationCenter defaultCenter] postNotificationName: ILLCrackNotification_iapProductInfoIsLoaded
                                                        object: nil];
  }
}



- (void) successfulPurchase: (EBPurchase *)purchaseHelper
                 identifier: (NSString *)productID
                    receipt: (NSData *)transactionReceipt {
  
  NSLog(@"ViewController successfulPurchase");
  
  // Purchase or Restore request was successful, so...
  // 1 - Unlock the purchased content for your new customer!
  // 2 - Notify the user that the transaction was successful.
  
  if ([self hasProductBeenPurchased: productID] == NO)
  {
    // If paid status has not yet changed, then do so now. Checking 
    // isPurchased boolean ensures user is only shown Thank You message 
    // once even if multiple transaction receipts are successfully 
    // processed (such as past subscription renewals).
    
    [self setProductHasBeenPurchased: productID];
    
    //-------------------------------------
    
    // @@TODO: Unlock the purchased content and update the app's stored settings.
    
    //-------------------------------------
    
    // Notify the user that the transaction was successful.
    UIAlertView *updatedAlert = [[UIAlertView alloc] initWithTitle: @"Thank You!"
                                                           message: @"Your purhase was successful and the Game Levels Pack is now unlocked for your enjoyment!"
                                                          delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
    [updatedAlert show];
  }
  
}


- (void) failedPurchase: (EBPurchase *)purchaseHelper
                  error: (NSInteger)errorCode
                message: (NSString *)errorMessage {
  
  NSLog(@"ViewController failedPurchase");
  
  // Purchase or Restore request failed or was cancelled, so notify the user.
  UIAlertView *failedAlert = [[UIAlertView alloc] initWithTitle: @"Purchase Stopped"
                                                        message: @"Either you cancelled the request or Apple reported a transaction error. Please try again later, or contact the app's customer support for assistance."
                                                       delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
  [failedAlert show];
}


- (void) incompleteRestore:(EBPurchase *)purchaseHelper {
  
  NSLog(@"ViewController incompleteRestore");
  
  // Restore queue did not include any transactions, so either the user has not yet made a purchase
  // or the user's prior purchase is unavailable, so notify user to make a purchase within the app.
  // If the user previously purchased the item, they will NOT be re-charged again, but it should 
  // restore their purchase. 
  
  UIAlertView *restoreAlert = [[UIAlertView alloc] initWithTitle:@"Restore Issue" message:@"A prior purchase transaction could not be found. To restore the purchased product, tap the Buy button. Paid customers will NOT be charged again, but the purchase will be restored." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
  [restoreAlert show];
}


- (void) failedRestore: (EBPurchase *)purchaseHelper
                 error: (NSInteger)errorCode
               message: (NSString*)errorMessage {
  
  NSLog(@"ViewController failedRestore");
  
  // Restore request failed or was cancelled, so notify the user.
  UIAlertView *failedAlert = [[UIAlertView alloc] initWithTitle: @"Restore Stopped"
                                                        message: @"Either you cancelled the request or your prior purchase could not be restored. Please try again later, or contact the app's customer support for assistance."
                                                       delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
  [failedAlert show];
}




@end
