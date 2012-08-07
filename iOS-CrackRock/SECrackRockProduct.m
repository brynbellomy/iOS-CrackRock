//
//  SECrackRockProduct.m
//  SECrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "SECrackRockProduct.h"

@interface SECrackRockProduct ()
@end



@implementation SECrackRockProduct

@synthesize productID = _productID;
@synthesize readableName = _readableName;
@synthesize productDescription = _productDescription;
@synthesize price = _price;
@synthesize purchaseStatus = _purchaseStatus;
@synthesize isAvailableInStore = _isAvailableInStore;
@synthesize thumbnailPNGFilename = _thumbnailPNGFilename;
@synthesize skProduct = _skProduct;



- (id) initWithProductID: (NSString *)productID
    thumbnailPNGFilename: (NSString *)thumbnailPNGFilename {
  
  self = [super init];
  if (self) {
    self.productID = productID;
    self.thumbnailPNGFilename = thumbnailPNGFilename;
  }
  return self;
}



- (id) initWithProductID: (NSString *)productID
            readableName: (NSString *)readableName
             description: (NSString *)description
    thumbnailPNGFilename: (NSString *)thumbnailPNGFilename {
  
  self = [self initWithProductID:productID thumbnailPNGFilename:thumbnailPNGFilename];
  if (self) {
    self.readableName = readableName;
    self.productDescription = description;
  }
  return self;
}



- (id) copyWithZone:(NSZone *)zone {
  
  // use designated initializer
  id theCopy = [[[self class] allocWithZone:zone] initWithProductID: [self.productID copy]
                                                       readableName: [self.readableName copy]
                                                        description: [self.productDescription copy]
                                               thumbnailPNGFilename: [self.thumbnailPNGFilename copy]];
  
  [theCopy setPrice:[self.price copy]];
  [theCopy setPurchaseStatus:self.purchaseStatus];
  [theCopy setIsAvailableInStore:self.isAvailableInStore];
  [theCopy setSkProduct:[self.skProduct copy]];
  
  return theCopy;
}

@end
