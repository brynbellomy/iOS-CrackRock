//
//  SECrackRock.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/16/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "SECrackRockCommon.h"



/**!
 * # SECrackRockDataSource
 */
@protocol SECrackRockDataSource <NSObject>

/**!
 * Must be overridden by subclasses.  This method must return an NSArray
 * containing SECrackRockItem objects representing the free items to which the user
 * already has access by default upon installing the app.
 */
- (NSArray *) freeProducts;


/**!
 * Must be overridden by subclasses.  This method must return an NSArray
 * containing SECrackRockItem objects representing the purchaseable/paid items that
 * the user is able to buy.
 */
- (NSArray *) paidProducts;

@end




/**!
 * # SECrackRock
 */
@interface SECrackRock : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>

+ (SECrackRock *) sharedInstance;

- (bool) startMonitoringTransactions;
- (void) stopMonitoringTransactions;

- (bool) tryToPurchaseProduct:(NSString *)productID;
- (bool) tryToRestorePurchase:(NSString *)productID;
- (bool) tryToRestoreAllPurchases;

- (bool) hasProductBeenPurchased: (NSString *)productID;
+ (bool) hasProductBeenPurchased: (NSString *)productID;

@property (nonatomic, weak,   readwrite) id<SECrackRockDataSource> dataSource;
@property (nonatomic, strong, readwrite) NSString *userDefaultsKey;
@property (nonatomic, strong, readwrite) NSArray *freeProducts;
@property (nonatomic, strong, readwrite) NSArray *paidProducts;
@property (nonatomic, strong, readwrite) NSMutableArray *sortedProductIDs;
@property (nonatomic, strong, readwrite) NSMutableDictionary *productsByID;
@property (nonatomic, strong, readwrite) NSMutableArray *purchasedItems;
@property (nonatomic, assign, readonly)  bool isCurrentlyRestoringMultiplePurchases;

@end









