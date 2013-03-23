//
//  SECrackRockProductSpec.m
//  iOS-CrackRock
//
//  Created by bryn austin bellomy on 2/27/2013.
//  Copyright 2013 bryn austin bellomy. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <BrynKit/BrynKit.h>
#import <BrynKit/BrynKitEDColor.h>
#import <BrynKit/BrynKitDDLogColorFormatter.h>
#import <BrynKit/GCDThreadsafe.h>

#import "SECrackRockProduct.h"
#import "SECrackRockCommon-Private.h"

@interface SECrackRockProduct (PrivateInterface)
    @property (nonatomic, strong, readwrite) SKProduct *skProduct;

    @property (nonatomic, copy, readwrite) NSString *productID;
    @property (nonatomic, copy, readwrite) NSString *readableName;
    @property (nonatomic, copy, readwrite) NSString *productDescription;
    @property (nonatomic, copy, readwrite) NSString *price;

    @property (nonatomic, assign, readwrite) BOOL isAvailableInStore;
    @property (nonatomic, assign, readwrite) BOOL hasBeenPurchased;
@end

@interface SECrackRockProduct (GCDThreadsafe) <GCDThreadsafe>
@end


#define  context(msg, blk)  context(CCCrayola(@"Mulberry", msg), (blk))
#define       it(msg, blk)       it(CCCrayola(@"Cerulean", msg), (blk))
#define describe(msg, blk) describe(CCCrayola(@"RedOrange", msg), (blk))

SPEC_BEGIN(SECrackRockProductSpec)

describe(@"SECrackRockProduct", ^{
    beforeAll(^{
        DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
        ttyLogger.logFormatter = [[BrynKitDDLogColorFormatter alloc] init];
        [DDLog addLogger: ttyLogger];
    });

    __block SECrackRockProduct *product = nil;
    NSString *productID = @"FakeProductID";

    beforeEach(^{
        product = [[SECrackRockProduct alloc] initWithProductID: productID];
    });

    context(@"when it's initialized", ^{
        it(@"is not nil", ^{ [product shouldNotBeNil]; });
        it(@"is an SECrackRockProduct", ^{ [[product should] beKindOfClass: [SECrackRockProduct class]]; });

        context(@"its productID", ^{
            it(@"is set to the string passed to the -init method", ^{ [product.productID isEqualToString:productID]; });
        });

        describe(@"its 'hasBeenPurchased' property", ^{
            beforeEach(^{
                [[NSUserDefaults standardUserDefaults] setObject:@[] forKey:SECrackRockUserDefaultsKey_purchasedItems];
                [[NSUserDefaults standardUserDefaults] synchronize];
                lllog(Verbose, @"clearing NSUserDefaults");
            });

            it(@"initially returns NO", ^{ [[@(product.hasBeenPurchased) should] beFalse]; });

            context(@"when set to YES", ^{
                beforeEach(^{
                    product.hasBeenPurchased = YES;
                    lllog(Verbose, @"setting product.hasBeenPurchased = YES");
                });

                it(@"returns YES", ^{
                    [[@(product.hasBeenPurchased) should] beTrue];
                });

                it(@"is reflected in NSUserDefaults", ^{
                    __block BOOL isInNSUserDefaults = NO;
                    [product runCriticalReadonlySection:^{
                        NSArray *purchasedItems = [[NSUserDefaults standardUserDefaults] arrayForKey:SECrackRockUserDefaultsKey_purchasedItems];
                        isInNSUserDefaults      = [purchasedItems containsObject:product.productID];
                    }];
                    [[theValue(isInNSUserDefaults) shouldEventually] beTrue];
                });
            });


            context(@"when set to NO", ^{
                beforeEach(^{
                    product.hasBeenPurchased = NO;
                    lllog(Verbose, @"setting product.hasBeenPurchased = NO");
                });

                it(@"returns NO", ^{ [[@(product.hasBeenPurchased) should] beFalse]; });

                it(@"is reflected in NSUserDefaults", ^{
                    NSArray *purchasedItems = [[NSUserDefaults standardUserDefaults] arrayForKey:SECrackRockUserDefaultsKey_purchasedItems];
                    [[purchasedItems shouldNot] contain:product.productID];
                });
            });

        });
    });
});


SPEC_END







