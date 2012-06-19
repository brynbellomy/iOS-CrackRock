# // crack

## as in: the irresistible street drug

# what

relatively inflexible, specific use-case helpers for brewing that delicious iOS
fool-aid.

# how

more documentation to come, but for now, just subclass the
**ILLCrackViewController** class and implement the following two methods:

```objective-c
- (NSArray *) initializePaidProducts {
  return @[
    @{ ReadableName : @"A bag of crap",
       Description : @"It's not like you're not still gonna buy it",
       Price : @"$0.99",
       ProductID : @"com.yourcompany.SmallBagOfCrap",
       Thumbnail : @"small-bag-of-crap" } // thumbnails must be PNG so no extension is needed
    
    @{ ReadableName : @"Well-perfumed bag of crap",
       Description : @"It's exactly what it sounds like.  You know you can't help but click that buy button.",
       Price : @"$1.99",
       ProductID : @"com.yourcompany.WillNeverGoBankruptAgain",
       Thumbnail : @"bag-of-crap-with-pink-bow" }

    // ... etc.
  ];
}

- (NSArray *) initializeFreeProducts {
  return @[
    @{ ReadableName : @"A teeny tiny bag of crap",
       Description : @"Just a taste!  Eww, wait, bad choice of metaphors.",
       Thumbnail : @"can-barely-see-it" }
    
    // ... etc.
  ];
}
```

that should do it.  you can access all sorts of properties on the view
controller and the view to customize them both from here to perdition, but it's
pretty standard UIKit business at that point.

also be sure to check out [EBPurchase](http://github.com/ebutterfly/EBPurchase)
and [iOS-BlingLord](http://github.com/brynbellomy/iOS-BlingLord), which power
this project under the hood.

