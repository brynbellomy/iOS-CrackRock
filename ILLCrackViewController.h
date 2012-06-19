//
//  ILLCrackViewController.h
//  ILLCrack in-app purchase framework
//
//  Created by bryn austin bellomy on 6/19/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SEViewController.h"
#import "EBPurchase.h"

@class SESpringBoard;

static NSString *const ProductID = @"ProductID";
static NSString *const ReadableName = @"ReadableName";
static NSString *const Description = @"Description";
static NSString *const Price = @"Price";
static NSString *const PurchaseStatus = @"PurchaseStatus";
static NSString *const Thumbnail = @"Thumbnail";
static NSString *const ImageFilenameFormatString = @"ImageFilenameFormatString";
static NSString *const NumFrames = @"NumFrames";

typedef enum {
  ILLCrackPurchaseStatusUnknown = (1 << 0),
  ILLCrackPurchaseStatusFree = (1 << 1),
  ILLCrackPurchaseStatusNonfreeUnpurchased = (1 << 2),
  ILLCrackPurchaseStatusNonfreePurchased = (1 << 3)
} ILLCrackPurchaseStatus;

static NSString *const ILLCrackUserDefaultsKey_purchasedItems = @"ILLCrackUserDefaultsKey_purchasedItems";
static NSString *const ILLCrackNotification_iapProductInfoIsLoaded = @"ILLCrackNotification_iapProductInfoIsLoaded";

@interface ILLCrackViewController : SEViewController <EBPurchaseDelegate>

@property (nonatomic, weak,   readwrite) SESpringBoard *springboardView;
@property (nonatomic, strong, readonly)  NSMutableArray *productList;
@property (nonatomic, strong, readonly)  NSMutableArray *purchasedItems;

- (NSArray *) initializeFreeProducts;
- (NSArray *) initializePaidProducts;
- (void) tryToPurchaseProduct:(NSString *)purchaseID;
- (void) tryToRestorePurchase: (NSString *)purchaseID;


@end
