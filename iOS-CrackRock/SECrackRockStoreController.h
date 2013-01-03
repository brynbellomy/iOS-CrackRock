//
//  SECrackRockViewController.h
//  iOS-CrackRock in-app purchase framework
//
//  Created by bryn austin bellomy on 6/19/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <iOS-BlingLord/SEBlingLordView.h>


@class SECrackRockProduct;

//@protocol SECrackRockView <NSObject>
//@end


@interface SECrackRockStoreController : NSObject


/**!
 * ## Properties
 */
//@property (nonatomic, weak,   readwrite) SEBlingLordView *springboardView;
//@property (nonatomic, weak,   readwrite) UIView<SECrackRockView> *storeView;
//@property (nonatomic, assign, readwrite) CGSize springboardItemSize;
//@property (nonatomic, assign, readwrite) CGSize springboardItemMargins;
//@property (nonatomic, assign, readwrite) CGSize springboardOuterMargins;


typedef void(^NotificationUserInfoBlock)(NSDictionary *);

@property (nonatomic, strong, readwrite) NotificationUserInfoBlock successfulPurchase;
@property (nonatomic, strong, readwrite) NotificationUserInfoBlock cancelledPurchase;
@property (nonatomic, strong, readwrite) NotificationUserInfoBlock failedPurchase;
@property (nonatomic, strong, readwrite) NotificationUserInfoBlock successfulRestore;
@property (nonatomic, strong, readwrite) NotificationUserInfoBlock multipleRestoreComplete;
@property (nonatomic, strong, readwrite) NotificationUserInfoBlock incompleteRestore;
@property (nonatomic, strong, readwrite) NotificationUserInfoBlock failedRestore;
@property (nonatomic, strong, readwrite) NotificationUserInfoBlock didFinishPreparingProductInfo;
@property (nonatomic, strong, readwrite) NotificationUserInfoBlock transactionStateDidChange;
@property (nonatomic, strong, readwrite) NotificationUserInfoBlock productsRequestStateDidChange;
@property (nonatomic, strong, readwrite) void(^productAccessWasAttempted)(SECrackRockProduct *product);


/**!
 * ## Instance methods
 */

- (void) tryToPurchaseProduct: (NSString *)productID;
- (void) tryToRestorePurchase: (NSString *)productID;
- (void) tryToRestoreAllPurchases;

//! these need to be overridden when you subclass SECrackRockViewController
//- (UIImage *) purchaseableIndicatorForProduct: (SECrackRockProduct *)product;
//- (void) productAccessWasAttempted: (SECrackRockProduct *)product;

//! these are optionally overrideable
//- (void) didFinishPreparingProductInfo;
//- (void) displayAlertToUserWithTitle:(NSString *)title text:(NSString *)text dismissText:(NSString *)dismissText;
//- (IBAction) restorePurchasesButtonClicked;

@end




//@interface SECrackRockMenuItem : SEBlingLordMenuItem
//  @property (nonatomic, strong, readwrite) NSString *productID;
//@end





