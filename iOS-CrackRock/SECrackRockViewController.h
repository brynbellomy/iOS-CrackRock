//
//  SECrackRockViewController.h
//  iOS-CrackRock in-app purchase framework
//
//  Created by bryn austin bellomy on 6/19/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iOS-BlingLord/SEBlingLordView.h>


@class SEBlingLordView, SECrackRockProduct;


@interface SECrackRockViewController : UIViewController


/**!
 * ## Properties
 */
@property (nonatomic, weak,   readwrite) SEBlingLordView *springboardView;
@property (nonatomic, assign, readwrite) CGSize springboardItemSize;
@property (nonatomic, assign, readwrite) CGSize springboardItemMargins;
@property (nonatomic, assign, readwrite) CGSize springboardOuterMargins;



/**!
 * ## Instance methods
 */

- (void) tryToPurchaseProduct: (NSString *)productID;
- (void) tryToRestorePurchase: (NSString *)productID;
- (void) tryToRestoreAllPurchases;

//! these need to be overridden when you subclass SECrackRockViewController
- (UIImage *) purchaseableIndicatorForProduct: (SECrackRockProduct *)product;
- (void) iconWasTappedForProduct: (SECrackRockProduct *)product;

//! these are optionally overrideable
- (void) didFinishPreparingProductInfo;
- (void) displayAlertToUserWithTitle:(NSString *)title text:(NSString *)text dismissText:(NSString *)dismissText;
- (IBAction) restorePurchasesButtonClicked;

@end




@interface SECrackRockMenuItem : SEBlingLordMenuItem
  @property (nonatomic, strong, readwrite) NSString *productID;
@end





