//
//  SECrackRockViewController.h
//  SECrackRock in-app purchase framework
//
//  Created by bryn austin bellomy on 6/19/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SEBlingLordViewController.h"
#import "SEBlingLordMenuItem.h"
#import "EBPurchase.h"

#if !defined(UIImageWithBundlePNG)
  #define UIImageWithBundlePNG(x) \
            ([UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:(x)] \
                                                                               ofType: @"png"]])
#endif

#if !defined(SESameStrings)
  #define SESameStrings(x, y) (BOOL)((x != nil) && ([(NSString *)(x) compare:(NSString *)(y)] == NSOrderedSame))
#endif

@class SEBlingLordView, SECrackRockProduct;

static NSString *const SECrackRockUserDefaultsKey_purchasedItems = @"SECrackRockUserDefaultsKey_purchasedItems";
static NSString *const SECrackRockNotification_iapProductInfoIsLoaded = @"SECrackRockNotification_iapProductInfoIsLoaded";



@interface SECrackRockViewController : UIViewController <EBPurchaseDelegate>


// Properties //

@property (nonatomic, weak,   readwrite) SEBlingLordView *springboardView;
@property (nonatomic, strong, readonly)  NSMutableArray *productList;
@property (nonatomic, strong, readonly)  NSMutableArray *purchasedItems;
@property (nonatomic, assign, readwrite) CGSize springboardItemSize;
@property (nonatomic, assign, readwrite) CGSize springboardItemMargins;
@property (nonatomic, assign, readwrite) CGSize springboardOuterMargins;



// Instance methods //

- (void) tryToPurchaseProduct: (NSString *)productID;
- (void) tryToRestorePurchase: (NSString *)productID;
- (void) tryToRestoreAllPurchases;

// these need to be overridden when you subclass SECrackRockViewController
- (NSArray *) initializeFreeProducts;
- (NSArray *) initializePaidProducts;
- (UIImage *) purchaseableIndicatorForProduct: (SECrackRockProduct *)product;
- (void) didFinishPreparingProductInfo;
- (void) iconWasTappedForProduct: (SECrackRockProduct *)product;
- (IBAction) restorePurchasesButtonClicked;
  
// this method is only exposed for debug purposes, really
- (void) setProduct:(NSString *)productID hasBeenPurchased:(BOOL)hasBeenPurchased;

@end




@interface SECrackRockMenuItem : SEBlingLordMenuItem

@property (nonatomic, strong, readwrite) NSString *productID;

@end





