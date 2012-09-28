# // iOS crack rock

## as in: the irresistible street drug

![crackrock](http://f.cl.ly/items/332U2r342K3Q1F1u0L1g/crack-rock.png)

(unbifurcations)

# what

helpers for brewing that delicious iOS fool-aid.  right now, it only supports a
springboard-style view for displaying products, although in the future, this will
be abstracted into a protocol so that any implementing view controller can be
used.

# how

more documentation to come, but for now, just subclass the
**SECrackRockViewController** class and implement the following methods:

```objective-c
- (NSArray *) initializePaidProducts {
  return @[
    [[SECrackRockProduct alloc] initWithProductID: @"com.yourcompany.SmallBagOfCrap"
                                     readableName: @"A bag of crap"
                                      description: @"It's not like you're not still gonna buy it"
                             thumbnailPNGFilename: @"small-bag-of-crap"], // thumbnails must be PNG so no extension is needed
    
    [[SECrackRockProduct alloc] initWithProductID: @"com.yourcompany.WillNeverGoBankruptAgain"
                                     readableName: @"Well-perfumed bag of crap"
                                      description: @"You know you can't help but click that buy button."
                             thumbnailPNGFilename: @"bag-of-crap-with-pink-bow"]

    // ... etc.
  ];
}

- (NSArray *) initializeFreeProducts {
  return @[
    [[SECrackRockProduct alloc] initWithProductID: @"com.yourcompany.FreeBagOfCrap"
                                     readableName: @"A teeny tiny bag of crap"
                                      description: @"Sample size."
                             thumbnailPNGFilename: @"can-barely-see-it"]
    
    // ... etc.
  ];
}
```

if you want SECrackRock to automatically add some kind of visible overlay to any
product icon that the user has not purchased yet (i.e. a small ribbon with the
price, etc.), implement the following method and return a UIImage with the same
dimensions as your product icons.

```objective-c
- (UIImage *) purchaseableIndicatorForProduct: (SECrackRockProduct *)product {
  if ([@"$0.99" compare:product.price] == NSOrderedSame)
    return UIImageWithBundlePNG(@"purchaseable-indicator-0.99");
  else if ([@"$1.99" compare:product.price] == NSOrderedSame)
    return UIImageWithBundlePNG(@"purchaseable-indicator-1.99");
  else
    return nil;
}
```

you can also set certain parameters in your init method that control the layout
of the springboard view used to display your products.  for more information on
these parameters, check out the
[iOS-BlingLord](http://github.com/brynbellomy/iOS-BlingLord) project on which
this project depends.  example:

```objective-c
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
      self.springboardItemSize = CGSizeMake(130.0f, 150.0f);
      self.springboardItemMargins = CGSizeMake(15.0f, 25.0f);
      self.springboardOuterMargins = CGSizeMake(10.0f, 10.0f);
    }
    return self;
}
```

finally, implement a handler that's fired when the user taps one of the product
icons.  the `tryToPurchaseProduct:` method (and maybe `tryToRestorePurchase:` as
well) will probably be useful here.

```objective-c
- (void) iconWasTappedForProduct: (SECrackRockProduct *)crackProduct {
  
  switch (product.purchaseStatus) {
    case SECrackRockPurchaseStatusFree:
    case SECrackRockPurchaseStatusNonfreePurchased: {

      // do whatever should be done here when a user taps on a product they have
      // access to already
      SomeViewController *vc = [[SomeViewController alloc] initWithNibName: @"SomeViewController" bundle: nil];
      vc.productToDisplay = crackProduct;
      [self.navigationController pushViewController:vc animated:YES];

    } break;
      
    case SECrackRockPurchaseStatusNonfreeUnpurchased: {

      // attempt to make a purchase
      [self tryToPurchaseProduct: product.productID];

    } break;
      
    default: {
      [[[UIAlertView alloc] initWithTitle: @"Our bad"
                                  message: @"An error occurred, and we don't know exactly why.  Maybe try again later!"
                                 delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } break;
  }
}
```

or even simpler, taking advantage of the default implementation:

```objective-c
- (void) iconWasTappedForProduct: (SECrackRockProduct *)crackProduct {
  
  switch (product.purchaseStatus) {
    case SECrackRockPurchaseStatusFree:
    case SECrackRockPurchaseStatusNonfreePurchased: {

      // do whatever should be done here when a user taps on a product they have
      // access to already
      SomeViewController *vc = [[SomeViewController alloc] initWithNibName: @"SomeViewController" bundle: nil];
      vc.productToDisplay = crackProduct;
      [self.navigationController pushViewController:vc animated:YES];

    } break;
      
      
    default: {
      [super iconWasTappedForProduct:crackProduct];
    } break;
  }
}
```

that should do it.  you can access all sorts of properties on the view
controller and the view to customize them both from here to perdition, but it's
pretty standard UIKit business at that point.

also be sure to check out [EBPurchase](http://github.com/ebutterfly/EBPurchase)
and [iOS-BlingLord](http://github.com/brynbellomy/iOS-BlingLord), which power
this project under the hood.



# license (WTFPL)

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
Version 2, December 2004

Copyright (C) 2004 Sam Hocevar <[sam@hocevar.net](mailto:sam@hocevar.net)>

Everyone is permitted to copy and distribute verbatim or modified 
copies of this license document, and changing it is allowed as long 
as the name is changed. 

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO. 

