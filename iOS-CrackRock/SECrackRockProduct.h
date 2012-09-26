//
//  SECrackRockProduct.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SECrackRock.h"

@class SKProduct;

@interface SECrackRockProduct : NSObject <NSCopying>
  
@property (nonatomic, strong, readwrite) NSString *productID;
@property (nonatomic, strong, readwrite) NSString *readableName;
@property (nonatomic, strong, readwrite) NSString *productDescription;
@property (nonatomic, strong, readwrite) NSString *price;
@property (nonatomic, assign, readwrite) SECrackRockPurchaseStatus purchaseStatus;
@property (nonatomic, assign, readwrite) bool isAvailableInStore;
@property (nonatomic, strong, readwrite) NSString *thumbnailPNGFilename;
@property (nonatomic, strong, readwrite) SKProduct *skProduct;

- (id) initWithProductID:(NSString *)productID thumbnailPNGFilename:(NSString *)thumbnailPNGFilename;
- (id) initWithProductID:(NSString *)productID readableName:(NSString *)readableName description:(NSString *)description thumbnailPNGFilename:(NSString *)thumbnailPNGFilename;

@end
