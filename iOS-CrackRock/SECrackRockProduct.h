//
//  SECrackRockProduct.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BrynKit/GCDThreadsafe.h>
#import <StoreKit/StoreKit.h>
#import "SECrackRock.h"

@interface SECrackRockProduct : NSObject <GCDThreadsafe>

//
// read-only properties
// hint: observe these with ReactiveCocoa KVO
//

@property (nonatomic, copy,   readonly) NSString *productID;
@property (nonatomic, copy,   readonly) NSString *readableName;
@property (nonatomic, copy,   readonly) NSString *productDescription;
@property (nonatomic, copy,   readonly) NSString *price;

@property (nonatomic, assign, readonly) BOOL isAvailableInStore;
@property (nonatomic, assign, readonly) BOOL hasBeenPurchased;
@property (nonatomic, assign, readonly) BOOL isFree;

@property (nonatomic, strong, readonly) SKProduct *skProduct;

//
// methods
//

- (instancetype) initWithProductID: (NSString *)productID;

- (instancetype) initWithProductID: (NSString *)productID
                      readableName: (NSString *)readableName
                productDescription: (NSString *)productDescription
                            isFree: (BOOL)isFree;

@end





