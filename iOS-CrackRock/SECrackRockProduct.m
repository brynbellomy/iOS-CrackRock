//
//  SECrackRockProduct.m
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "SECrackRockProduct.h"



@implementation SECrackRockProduct


/**!
 * #### initWithProductID:thumbnailPNGFilename:
 * 
 * @param {NSString*} productID
 * @param {NSString*} thumbnailPNGFilename
 * @return {id}
 */

- (id) initWithProductID: (NSString *)productID
    thumbnailPNGFilename: (NSString *)thumbnailPNGFilename {
  
  self = [super init];
  if (self) {
    self.productID = productID;
    self.thumbnailPNGFilename = thumbnailPNGFilename;
  }
  return self;
}



/**!
 * #### initWithProductID:readableName:description:thumbnailPNGFilename:
 * 
 * @param {NSString*} productID
 * @param {NSString*} readableName
 * @param {NSString*} description
 * @param {NSString*} thumbnailPNGFilename
 * @return {id}
 */

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



/**!
 * #### copyWithZone:
 * 
 * @param {NSZone*} zone
 * @return {id}
 */

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

