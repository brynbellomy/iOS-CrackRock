//
//  SECrackRockProduct.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SECrackRock.h"

typedef enum : NSUInteger {
    SECrackRockTransactionOutcome_Cancelled = 1,
    SECrackRockTransactionOutcome_Purchased = 2,
    SECrackRockTransactionOutcome_Restored  = 3
} SECrackRockTransactionOutcome;

@class SKProduct;

@interface SECrackRockProduct : NSObject <NSCopying>

//
// read-only properties
//

@property (nonatomic, copy,   readonly) NSString *productID;
@property (nonatomic, copy,   readonly) NSString *readableName;
@property (nonatomic, copy,   readonly) NSString *productDescription;
@property (nonatomic, copy,   readonly) NSString *price;
//@property (nonatomic, copy,   readonly) NSString *state;

@property (nonatomic, assign, readonly) SECrackRockProductStatus productStatus;
@property (nonatomic, assign, readonly) BOOL isAvailableInStore;
@property (nonatomic, assign, readonly) BOOL hasBeenPurchased;

@property (nonatomic, strong, readonly) SKProduct *skProduct;

//
// read-write properties
//

@property (nonatomic, copy, readwrite) NSString *thumbnailPNGFilename;

//
// methods
//

- (instancetype) initWithProductID:(NSString *)productID;
- (instancetype) initWithProductID:(NSString *)productID thumbnailPNGFilename:(NSString *)thumbnailPNGFilename;

@end





