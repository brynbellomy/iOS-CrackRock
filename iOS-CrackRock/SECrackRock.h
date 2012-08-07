//
//  SECrackRock.h
//  SECrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/16/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "SECrackRockCommon.h"



@protocol SECrackRockDataSource <NSObject>

/**
 * Must be overridden by subclasses.  This method must return an NSArray
 * containing SECrackRockItem objects representing the free items to which the user
 * already has access by default upon installing the app.
 */
- (NSArray *) freeProducts;


/**
 * Must be overridden by subclasses.  This method must return an NSArray
 * containing SECrackRockItem objects representing the purchaseable/paid items that
 * the user is able to buy.
 */
- (NSArray *) paidProducts;

@end





@interface SECrackRock : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>

+ (SECrackRock *) sharedInstance;

- (bool) startMonitoringTransactions;
- (void) stopMonitoringTransactions;

- (bool) tryToPurchaseProduct:(NSString *)productID;
- (bool) tryToRestorePurchase:(NSString *)productID;
- (bool) tryToRestoreAllPurchases;

@property (nonatomic, weak,   readwrite) id<SECrackRockDataSource> dataSource;
@property (nonatomic, strong, readwrite) NSArray *freeProducts;
@property (nonatomic, strong, readwrite) NSArray *paidProducts;
@property (nonatomic, strong, readwrite) NSMutableArray *sortedProductIDs;
@property (nonatomic, strong, readwrite) NSMutableDictionary *productsByID;
@property (nonatomic, strong, readwrite) NSMutableArray *purchasedItems;
@property (nonatomic, assign, readonly)  bool isCurrentlyRestoringMultiplePurchases;

@end









