//
//  SECrackRock.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/16/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import "SECrackRockCommon-Private.h"

Key(SECrackRockNotification_CollectionWasUpdated);


@class RACSignal;

typedef void(^SECrackRockTransactionResponseBlock)(NSError *error);


/**!
 * # SECrackRock
 */
@interface SECrackRock : NSObject <DDRegisteredDynamicLogging>

- (instancetype) initWithFreeProducts: (NSSet *)freeProductIDs
                         paidProducts: (NSSet *)paidProducts;

- (void)   purchase: (NSString *)productID
         completion: (SECrackRockTransactionResponseBlock)blockCompletion;

- (void) restoreAllPurchases:(SECrackRockTransactionResponseBlock)blockTransactionCompletion;

//
// RAC/KVO-based properties
//
@property (nonatomic, strong, readonly) NSSet *products;
@property (nonatomic, strong, readonly) NSSet *purchasedProducts;
@property (nonatomic, strong, readonly) NSSet *freeAndPurchasedProducts;
@property (nonatomic, strong, readonly) NSDictionary *productsByID;

//
// backing stores for RAC/KVO-based properties
//
@property (nonatomic, strong, readonly) NSSet *freeProducts;
@property (nonatomic, strong, readonly) NSSet *paidProducts;
@property (nonatomic, copy,   readonly) NSString *state;

//
// other properties
//
@property (nonatomic, assign, readonly) BOOL isCurrentlyRestoringMultiplePurchases;

@end









