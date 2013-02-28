//
//  SECrackRock.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/16/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <CocoaLumberjack/DDLog.h>
#import "SECrackRockCommon.h"


@class RACSignal;

typedef void(^SECrackRockTransactionResponseBlock)(NSError *error);


/**!
 * # SECrackRock
 */
@interface SECrackRock : NSObject <DDRegisteredDynamicLogging>

- (instancetype) initWithFreeProductIDs: (NSSet *)freeProductIDs
                         paidProductIDs: (NSSet *)paidProductIDs;

- (void)   purchase: (NSString *)productID
         completion: (SECrackRockTransactionResponseBlock)blockCompletion;

- (void) restoreAllPurchases:(SECrackRockTransactionResponseBlock)blockTransactionCompletion;

//
// RAC-KVO generated properties
//
@property (nonatomic, strong, readonly) NSSet *products;
@property (nonatomic, strong, readonly) NSSet *purchasedItems;
@property (nonatomic, strong, readonly) NSDictionary *productsByID;

@property (nonatomic, strong, readonly) RACSignal *rac_products;
@property (nonatomic, strong, readonly) RACSignal *rac_freeProducts;
@property (nonatomic, strong, readonly) RACSignal *rac_paidProducts;
@property (nonatomic, strong, readonly) RACSignal *rac_state;

//
// backing stores for RAC-KVO properties
//
@property (nonatomic, strong, readonly) NSSet *freeProducts;
@property (nonatomic, strong, readonly) NSSet *paidProducts;
@property (nonatomic, copy,   readonly) NSString *state;

//
// other properties
//
@property (nonatomic, assign, readonly) BOOL isCurrentlyRestoringMultiplePurchases;

@end









