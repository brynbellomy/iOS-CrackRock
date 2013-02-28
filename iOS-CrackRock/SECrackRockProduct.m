//
//  SECrackRockProduct.m
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/8/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <libextobjc/EXTScope.h>
#import <BrynKit/BrynKit.h>
#import <BrynKit/NSObject+GCDThreadsafe.h>

#import "SECrackRockProduct.h"
#import "SECrackRockProduct-Private.h"


@interface SECrackRockProduct ()
    @property (nonatomic, copy, readwrite) SECrackRockTransactionResponseBlock blockTransactionCompletion;
@end


@implementation SECrackRockProduct


#pragma mark- Lifecycle
#pragma mark-

/**!
 * #### initWithProductID:
 *
 * @param {NSString*} productID
 * @return {instancetype}
 */

- (instancetype) initWithProductID:(NSString *)productID {
    self = [self initWithProductID:productID thumbnailPNGFilename:nil];
    return self;
}



/**!
 * #### initWithProductID:thumbnailPNGFilename:
 * 
 * @param {NSString*} productID
 * @param {NSString*} thumbnailPNGFilename
 * @return {instancetype}
 */
- (instancetype) initWithProductID: (NSString *)productID
              thumbnailPNGFilename: (NSString *)thumbnailPNGFilename
{
    self = [super init];

    if (self) {
        _productID			  = productID;
        _thumbnailPNGFilename = thumbnailPNGFilename;
    }
    return self;
}


/**!
 * #### copyWithZone:
 * 
 * @param {NSZone*} zone
 * @return {instancetype}
 */

- (instancetype) copyWithZone:(NSZone *)zone
{
    // use designated initializer
    id theCopy = [[[self class] allocWithZone:zone] initWithProductID: [self.productID copy]
                                                 thumbnailPNGFilename: [self.thumbnailPNGFilename copy]];

    [theCopy setReadableName: [self.readableName copy]];
    [theCopy setProductDescription: [self.productDescription copy]];
    [theCopy setPrice:[self.price copy]];
    [theCopy setProductStatus:self.productStatus];
    [theCopy setIsAvailableInStore:self.isAvailableInStore];
    [theCopy setHasBeenPurchased:self.hasBeenPurchased];
    [theCopy setSkProduct:[self.skProduct copy]];

    return theCopy;
}


- (BOOL) hasBeenPurchased
{
    __block BOOL hasBeenPurchased;
    @weakify(self);
    [self runCriticalReadonlySection:^{
        @strongify(self);
        hasBeenPurchased = [[[NSUserDefaults standardUserDefaults] arrayForKey:SECrackRockUserDefaultsKey_purchasedItems] containsObject:self.productID];
    }];
    return hasBeenPurchased;
}


- (void) setHasBeenPurchased:(BOOL)hasBeenPurchased
{
    @weakify(self);
    [self runCriticalMutableSection:^{
        @strongify(self);

        NSMutableArray *purchasedItems = [[NSUserDefaults standardUserDefaults] arrayForKey:SECrackRockUserDefaultsKey_purchasedItems].mutableCopy ?: [NSMutableArray array];
        BOOL hasBeenRecordedAsPurchased = [purchasedItems containsObject:self.productID];

        if (hasBeenPurchased == YES && hasBeenRecordedAsPurchased == NO) {
            [purchasedItems addObject:self.productID];
        }
        else if (hasBeenPurchased == NO && hasBeenRecordedAsPurchased == YES) {
            [purchasedItems removeObject:self.productID];
        }

        [[NSUserDefaults standardUserDefaults] setObject:purchasedItems forKey:SECrackRockUserDefaultsKey_purchasedItems];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
}


@end






