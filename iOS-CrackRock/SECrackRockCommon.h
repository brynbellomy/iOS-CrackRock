//
//  SECrackRockCommon.h
//  iOS-CrackRock iOS in-app purchase framework
//
//  Created by bryn austin bellomy on 7/23/12.
//  Copyright (c) 2012 bryn austin bellomy. All rights reserved.
//



Key(SECrackRockUserDefaultsKey_purchasedItems);

/**!
 * ## Notification names
 */
Key(SECrackRockNotification_SuccessfulPurchase);
Key(SECrackRockNotification_CancelledPurchase);
Key(SECrackRockNotification_FailedPurchase);
Key(SECrackRockNotification_SuccessfulRestore);
Key(SECrackRockNotification_MultipleRestoreComplete);
Key(SECrackRockNotification_IncompleteRestore);
Key(SECrackRockNotification_FailedRestore);
Key(SECrackRockNotification_ProductWasValidated);
Key(SECrackRockNotification_ProductWasNotValidated);
Key(SECrackRockNotification_DidFinishPreparingProductInfo);
Key(SECrackRockNotification_StoreTransactionWillBegin);
Key(SECrackRockNotification_StoreTransactionDidEnd);

/**!
 * ## Notification user info dictionary keys
 */
Key(SECrackRockUserInfoKey_TransactionType);
Key(SECrackRockUserInfoKey_CrackRock);
Key(SECrackRockUserInfoKey_ProductID);
Key(SECrackRockUserInfoKey_Success);
Key(SECrackRockUserInfoKey_Receipt);
Key(SECrackRockUserInfoKey_Message);
Key(SECrackRockUserInfoKey_ErrorCode);

/**!
 * ## Observable states (see SEStatelyNotificationRobot in Vendor/iOS-StatefulNotifications)
 */
Key(ObservableState_Transaction);
Key(ObservableState_ProductsRequest);


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



