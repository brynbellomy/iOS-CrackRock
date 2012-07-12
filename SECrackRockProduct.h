//
//  SECrackRockProduct.h
//  SECrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  SECrackRockPurchaseStatusUnknown = (1 << 0),
  SECrackRockPurchaseStatusError = (1 << 1),
  SECrackRockPurchaseStatusFree = (1 << 2),
  SECrackRockPurchaseStatusNonfreeUnpurchased = (1 << 3),
  SECrackRockPurchaseStatusNonfreePurchased = (1 << 4)
} SECrackRockPurchaseStatus;

@interface SECrackRockProduct : NSObject <NSCopying>
  
@property (nonatomic, strong, readwrite) NSString *productID;
@property (nonatomic, strong, readwrite) NSString *readableName;
@property (nonatomic, strong, readwrite) NSString *productDescription;
@property (nonatomic, strong, readwrite) NSString *price;
@property (nonatomic, assign, readwrite) SECrackRockPurchaseStatus purchaseStatus;
@property (nonatomic, assign, readwrite) BOOL isAvailableInStore;
@property (nonatomic, strong, readwrite) NSString *thumbnailPNGFilename;

- (id) initWithProductID:(NSString *)productID thumbnailPNGFilename:(NSString *)thumbnailPNGFilename;
- (id) initWithProductID:(NSString *)productID readableName:(NSString *)readableName description:(NSString *)description thumbnailPNGFilename:(NSString *)thumbnailPNGFilename;

@end
