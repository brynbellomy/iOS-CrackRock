
#import "SECrackRockCommon.h"

@interface SECrackRockProduct (Private)
    @property (nonatomic, strong, readwrite) SKProduct *skProduct;

    @property (nonatomic, copy, readwrite) NSString *productID;
    @property (nonatomic, copy, readwrite) NSString *readableName;
    @property (nonatomic, copy, readwrite) NSString *productDescription;
    @property (nonatomic, copy, readwrite) NSString *price;

    @property (nonatomic, assign, readwrite) SECrackRockProductStatus productStatus;
    @property (nonatomic, assign, readwrite) BOOL isAvailableInStore;
    @property (nonatomic, assign, readwrite) BOOL hasBeenPurchased;
@end



