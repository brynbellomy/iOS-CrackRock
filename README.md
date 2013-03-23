# // iOS crack rock

## as in: the irresistible street drug

![crackrock](http://f.cl.ly/items/332U2r342K3Q1F1u0L1g/crack-rock.png)

(unbifurcations)

# what

Helpers for brewing that delicious iOS fool-aid.

Github's excellent [**ReactiveCocoa**](http://github.com/ReactiveCocoa/ReactiveCocoa) was used extensively under the hood, and it's highly recommended that you use it to interface with **iOS-CrackRock**.

# how

## some useful properties

It'll probably be helpful to add properties like the following to whichever class ends up being responsible for your **SECrackRock** implementation.

```objective-c
@property (nonatomic, strong, readwrite) SECrackRock *crackRock;
@property (nonatomic, strong, readwrite) NSSet *availablePowerups;
@property (nonatomic, strong, readwrite) NSSet *allProducts;

@property (nonatomic, strong, readonly)  NSSet *paidProducts;
@property (nonatomic, strong, readonly)  NSSet *freeProducts;
```

## declare your IAP products

In addition to regular products, you can declare 'free' products when appropriate.  These are useful when your app sells a product -- let's say, for example, Instagram-style photo filters -- but also offers a reduced set of these for free by default.

Because the IAP servers aren't queried for any of your 'free' products, you have to specify all required metadata when initializing these products (basically just name and description, unless you subclass `SECrackRockProduct` and add others).  Your 'paid' products can simply specify a product ID -- the other parameters of `-[SECrackRockProduct initWithProductID:readableName:productDescription:isFree:]` can simply be given as `nil`

```objective-c
- (NSSet *) freeProducts
{
    NSArray *productMetadata = @[
        @{  @"product id": @"freeproduct1",
            @"name": @"super jump",
            @"description": @"boing boing boing",
            @"is powerup": @YES,
            @"free": @YES, },

        @{  @"product id": @"freeproduct2",
            @"name": @"power walk",
            @"description": @"get swole",
            @"is powerup": @NO,
            @"free": @YES, },
    ];
    return [self productsFromMetadata: productMetadata];
}

- (NSSet *) paidProducts
{
    NSArray *productMetadata = @[
        @{  @"product id": @"paidproduct1", @"is powerup": @YES, },
        @{  @"product id": @"paidproduct2", @"is powerup": @NO,  },
    ];
    return [self productsFromMetadata: productMetadata];
}

- (NSSet *) productsFromMetadata: (NSArray *)productMetadata
{
    NSMutableSet *products = [NSMutableSet set];
    for (NSDictionary *metadata in productMetadata) {
        SECrackRockProduct *product = nil;
        if ([metadata[@"is powerup"] boolValue] == YES) {
            product = [MyAppPowerUpProduct initWithProductID: metadata[@"product id"]
                                                readableName: metadata[@"name"]
                                          productDescription: metadata[@"description"]
                                                      isFree: metadata[@"free"]];
        }
        else {
            product = [SECrackRockProduct initWithProductID: metadata[@"product id"]
                                               readableName: metadata[@"name"]
                                         productDescription: metadata[@"description"]
                                                     isFree: metadata[@"free"]];
        }
        [products addObject: product];
    }
    return products;
}
```

## initialize the crack rock

Add something like the following to whichever part of your application should bootstrap the in-app purchase functionality.  Probably best to do this in `-application:didFinishLaunchingWithOptions:`.

```objective-c
- (BOOL)              application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.crackRock = [[SECrackRock alloc] initWithFreeProducts: freeProducts
                                                  paidProducts: paidProducts];

    // ...
}
```

## reactive crack

Speaking of ReactiveCocoa, you might find some benefit in setting up a few properties like the following.

```objective-c
RAC(self.allProducts) =
    [RACSignal combineLatest: @[
            [RACAbleWithStart([self freeProducts]) distinctUntilChanged],
            [RACAbleWithStart([self paidProducts]) distinctUntilChanged], ]
        reduce:^id (NSSet *freeProducts, NSSet *paidProducts) {
            return [freeProducts setByAddingObjectsFromSet: paidProducts];
        }];

RAC(self.availablePowerups) =
    [[RACAbleWithStart(self.crackRock.freeAndPurchasedProducts)
        distinctUntilChanged]
        map:^id (NSSet *freeAndPurchasedProducts) {
            NSMutableSet *availablePowerups = [NSMutableSet set];

            for (SECrackRockProduct *product in freeAndPurchasedProducts) {
                if ([product isKindOfClass: [MyAppPowerUpProducts class]]) {
                    [availablePowerups addObject: product];
                }
            }
            return availablePowerups;
        }];
}
```

## buy stuff

When you purchase and restore items, `SECrackRock`'s properties will send KVO notifications.  You can observe these properties using KVO or a framework like [ReactiveCocoa](http://github.com/ReactiveCocoa/ReactiveCocoa) and update the UI and application state accordingly.

```objective-c
[self.crackRock purchase: productID
              completion:^(NSError *error) {
                  if (error != nil) {
                      NSLog(@"purchase error = %@", error);
                      return;
                  }

                  NSLog(@"purchase success!");
              }];
```

Restoring is just as easy.

```objective-c
[self.crackRock restoreAllPurchases:^(NSError *error) {
    if (error != nil) {
        NSLog(@"error = %@", error);
        return;
    }

    NSLog(@"restore success!");
}];
```


# license (WTFPL)

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
Version 2, December 2004

Copyright (C) 2004 Sam Hocevar <[sam@hocevar.net](mailto:sam@hocevar.net)>

Everyone is permitted to copy and distribute verbatim or modified 
copies of this license document, and changing it is allowed as long 
as the name is changed. 

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO. 

