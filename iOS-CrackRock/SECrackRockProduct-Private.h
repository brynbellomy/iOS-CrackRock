//
//  SECrackRockProduct-Private.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/23/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//


#import "SECrackRockCommon.h"

@interface SECrackRockProduct (Private)
    @property (nonatomic, strong, readwrite) SKProduct *skProduct;

    @property (nonatomic, copy, readwrite) NSString *productID;
    @property (nonatomic, copy, readwrite) NSString *readableName;
    @property (nonatomic, copy, readwrite) NSString *productDescription;
    @property (nonatomic, copy, readwrite) NSString *price;

    @property (nonatomic, assign, readwrite) BOOL isAvailableInStore;
    @property (nonatomic, assign, readwrite) BOOL hasBeenPurchased;
@end



