//
//  SECrackRockCommon.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/23/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//



static NSString *const SECrackRockUserDefaultsKey_purchasedItems = @"SECrackRockUserDefaultsKey_purchasedItems";

/**!
 * ## Notification names
 */
static NSString *const SECrackRockNotification_SuccessfulPurchase = @"SECrackRockNotification_SuccessfulPurchase";
static NSString *const SECrackRockNotification_CancelledPurchase = @"SECrackRockNotification_CancelledPurchase";
static NSString *const SECrackRockNotification_FailedPurchase = @"SECrackRockNotification_FailedPurchase";
static NSString *const SECrackRockNotification_SuccessfulRestore = @"SECrackRockNotification_SuccessfulRestore";
static NSString *const SECrackRockNotification_MultipleRestoreComplete = @"SECrackRockNotification_MultipleRestoreComplete";
static NSString *const SECrackRockNotification_IncompleteRestore = @"SECrackRockNotification_IncompleteRestore";
static NSString *const SECrackRockNotification_FailedRestore = @"SECrackRockNotification_FailedRestore";
static NSString *const SECrackRockNotification_ProductWasValidated = @"SECrackRockNotification_ProductWasValidated";
static NSString *const SECrackRockNotification_ProductWasNotValidated = @"SECrackRockNotification_ProductWasNotValidated";
static NSString *const SECrackRockNotification_DidFinishPreparingProductInfo = @"SECrackRockNotification_DidFinishPreparingProductInfo";
static NSString *const SECrackRockNotification_StoreTransactionWillBegin = @"SECrackRockNotification_StoreTransactionWillBegin";
static NSString *const SECrackRockNotification_StoreTransactionDidEnd = @"SECrackRockNotification_StoreTransactionDidEnd";

/**!
 * ## Notification user info dictionary keys
 */
static NSString *const SECrackRockUserInfoKey_TransactionType = @"SECrackRockUserInfoKey_TransactionType";
static NSString *const SECrackRockUserInfoKey_CrackRock = @"SECrackRockUserInfoKey_CrackRock";
static NSString *const SECrackRockUserInfoKey_ProductID = @"SECrackRockUserInfoKey_ProductID";
static NSString *const SECrackRockUserInfoKey_Success = @"SECrackRockUserInfoKey_Success";
static NSString *const SECrackRockUserInfoKey_Receipt = @"SECrackRockUserInfoKey_Receipt";
static NSString *const SECrackRockUserInfoKey_Message = @"SECrackRockUserInfoKey_Message";
static NSString *const SECrackRockUserInfoKey_ErrorCode = @"SECrackRockUserInfoKey_ErrorCode";

/**!
 * ## Observable states (see SEStatelyNotificationRobot in Vendor/iOS-StatefulNotifications)
 */
static NSString *const SECrackRockState_TransactionState = @"SECrackRockState_TransactionState";
static NSString *const SECrackRockState_ProductsRequestState = @"SECrackRockState_ProductsRequestState";


typedef enum {
  SECrackRockTransactionStateInProgress = (1 << 1),
  SECrackRockTransactionStateAsleep = (1 << 2)
} SECrackRockTransactionState;

typedef enum {
  SECrackRockProductsRequestStateUnfinished = (1 << 1),
  SECrackRockProductsRequestStateFinished = (1 << 2)
} SECrackRockProductsRequestState;


typedef enum {
  SECrackRockStoreTransactionTypeUndefined       = (1 << 0),
  SECrackRockStoreTransactionTypePurchase        = (1 << 1),
  SECrackRockStoreTransactionTypeRestore         = (1 << 2),
  SECrackRockStoreTransactionTypeProductsRequest = (1 << 3)
} SECrackRockStoreTransactionType;

typedef enum {
  SECrackRockPurchaseStatusUnknown = (1 << 0),
  SECrackRockPurchaseStatusError = (1 << 1),
  SECrackRockPurchaseStatusFree = (1 << 2),
  SECrackRockPurchaseStatusNonfreeUnpurchased = (1 << 3),
  SECrackRockPurchaseStatusNonfreePurchased = (1 << 4)
} SECrackRockPurchaseStatus;



