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
#import <BrynKit/GCDThreadsafe.h>

#import "SECrackRockProduct.h"
#import "SECrackRockProduct-Private.h"


@interface SECrackRockProduct ()
    @property (nonatomic, strong, readwrite) SKProduct *skProduct;

    @property (nonatomic, copy,   readwrite) SECrackRockTransactionResponseBlock blockTransactionCompletion;
    @property (nonatomic, copy,   readwrite) NSString *productID;
    @property (nonatomic, copy,   readwrite) NSString *readableName;
    @property (nonatomic, copy,   readwrite) NSString *productDescription;
    @property (nonatomic, copy,   readwrite) NSString *price;

    @property (nonatomic, assign, readwrite) BOOL isAvailableInStore;
    @property (nonatomic, assign, readwrite) BOOL hasBeenPurchased;
@end


@implementation SECrackRockProduct
    @gcd_threadsafe


#pragma mark- Lifecycle
#pragma mark-

/**!
 * #### initWithProductID:
 *
 * @param {NSString*} productID
 * @return {instancetype}
 */
- (instancetype) initWithProductID:(NSString *)productID
{
    self = [self initWithProductID:productID
                      readableName:nil
                productDescription:nil
                            isFree:NO];
    return self;
}



/**
 * #### initWithProductID:readableName:productDescription:isFree:
 *
 * @param {NSString*} productID
 * @param {NSString*} readableName
 * @param {NSString*} productDescription
 * @param {BOOL} isFree
 * @return {instancetype}
 */
- (instancetype) initWithProductID: (NSString *)productID
                      readableName: (NSString *)readableName
                productDescription: (NSString *)productDescription
                            isFree: (BOOL)isFree
{
    self = [super init];
    if (self)
    {
        _productID          = productID;
        _readableName       = readableName;
        _productDescription = productDescription;
        _isAvailableInStore = NO;
        _isFree             = isFree;
        _queueCritical      = dispatch_queue_create("com.signalenvelope.SECrackRock.Product.queueCritical", 0);
    }
    return self;
}



- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass: [SECrackRockProduct class]])
    {
        SECrackRockProduct *product = object;
        if ([product.productID isEqualToString:self.productID]) {
            return YES;
        }
    }
    return NO;
}



- (BOOL) hasBeenPurchased
{
    __block BOOL hasBeenPurchased;
    @weakify(self);
    [self runCriticalReadonlySection:^{
        @strongify(self);
        hasBeenPurchased = !self.isFree && [[[NSUserDefaults standardUserDefaults] arrayForKey:SECrackRockUserDefaultsKey_purchasedItems] containsObject:self.productID];
    }];
    return hasBeenPurchased;
}



- (void) setHasBeenPurchased:(BOOL)hasBeenPurchased
{
    @weakify(self);
    [self runCriticalMutableSection:^{
        @strongify(self);

        if (self.isFree == YES) {
            return;
        }

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






