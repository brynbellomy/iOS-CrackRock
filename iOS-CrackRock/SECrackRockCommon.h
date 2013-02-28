//
//  SECrackRockCommon.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/23/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//

#import <BrynKit/BrynKit.h>
#import <libextobjc/metamacros.h>


Key(SECrackRockUserDefaultsKey_purchasedItems);

#define SECrackRock_LOG_CONTEXT 1119

#define lllog(severity, __FORMAT__, ...) metamacro_concat(SECrackRockLog,severity)((__FORMAT__), ## __VA_ARGS__)

#define SECrackRockLogError(__FORMAT__, ...)     SYNC_LOG_OBJC_MAYBE([SECrackRock ddLogLevel], LOG_FLAG_ERROR,   SECrackRock_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define SECrackRockLogWarn(__FORMAT__, ...)     ASYNC_LOG_OBJC_MAYBE([SECrackRock ddLogLevel], LOG_FLAG_WARN,    SECrackRock_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define SECrackRockLogInfo(__FORMAT__, ...)     ASYNC_LOG_OBJC_MAYBE([SECrackRock ddLogLevel], LOG_FLAG_INFO,    SECrackRock_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)
#define SECrackRockLogVerbose(__FORMAT__, ...)  ASYNC_LOG_OBJC_MAYBE([SECrackRock ddLogLevel], LOG_FLAG_VERBOSE, SECrackRock_LOG_CONTEXT, (__FORMAT__), ## __VA_ARGS__)


/**!
 * ## Notification names
 */
//Key(SECrackRockNotification_SuccessfulPurchase);
//Key(SECrackRockNotification_CancelledPurchase);
//Key(SECrackRockNotification_FailedPurchase);
//Key(SECrackRockNotification_SuccessfulRestore);
//Key(SECrackRockNotification_MultipleRestoreComplete);
//Key(SECrackRockNotification_IncompleteRestore);
//Key(SECrackRockNotification_FailedRestore);
//Key(SECrackRockNotification_ProductWasValidated);
//Key(SECrackRockNotification_ProductWasNotValidated);
//Key(SECrackRockNotification_DidFinishPreparingProductInfo);
//Key(SECrackRockNotification_StoreTransactionWillBegin);
//Key(SECrackRockNotification_StoreTransactionDidEnd);

/**!
 * ## Notification user info dictionary keys
 */
//Key(SECrackRockUserInfoKey_TransactionType);
//Key(SECrackRockUserInfoKey_CrackRock);
//Key(SECrackRockUserInfoKey_ProductID);
//Key(SECrackRockUserInfoKey_Success);
//Key(SECrackRockUserInfoKey_Receipt);
//Key(SECrackRockUserInfoKey_Message);
//Key(SECrackRockUserInfoKey_ErrorCode);

///**!
// * ## Observable states (see SEStatelyNotificationRobot in Vendor/iOS-StatefulNotifications)
// */
//Key(ObservableState_Transaction);
//Key(ObservableState_ProductsRequest);


//typedef enum {
//  SECrackRockTransactionStateInProgress = (1 << 1),
//  SECrackRockTransactionStateAsleep = (1 << 2)
//} SECrackRockTransactionState;
//
//typedef enum {
//  SECrackRockProductsRequestStateUnfinished = (1 << 1),
//  SECrackRockProductsRequestStateFinished = (1 << 2)
//} SECrackRockProductsRequestState;
//
//
//typedef enum {
//  SECrackRockStoreTransactionTypeUndefined       = (1 << 0),
//  SECrackRockStoreTransactionTypePurchase        = (1 << 1),
//  SECrackRockStoreTransactionTypeRestore         = (1 << 2),
//  SECrackRockStoreTransactionTypeProductsRequest = (1 << 3)
//} SECrackRockStoreTransactionType;
//
typedef enum {
  SECrackRockProductStatusUnknown = (1 << 0),
  SECrackRockProductStatusError = (1 << 1),
  SECrackRockProductStatusFree = (1 << 2),
  SECrackRockProductStatusNonfreeUnpurchased = (1 << 3),
  SECrackRockProductStatusNonfreePurchased = (1 << 4)
} SECrackRockProductStatus;



