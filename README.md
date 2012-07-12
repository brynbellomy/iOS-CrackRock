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

# license (MIT)

Copyright (c) 2012 bryn austin bellomy < <bryn@signals.io> >

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

