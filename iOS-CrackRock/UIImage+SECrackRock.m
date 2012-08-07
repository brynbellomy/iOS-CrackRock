//
//  UIImage+SECrackRock.m
//  Catcorder
//
//  Created by bryn austin bellomy on 7/12/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import "UIImage+SECrackRock.h"


@implementation UIImage (SECrackRock)

- (UIImage *)imageWithOverlay:(UIImage *)overlay atPosition:(CGPoint)position withSize:(CGSize)size {
  CGSize finalSize = self.size;
  
  UIGraphicsBeginImageContext(finalSize);
  [self drawInRect: CGRectMake(0, 0, finalSize.width, finalSize.height)];
  [overlay drawInRect: CGRectMake(position.x, position.y, size.width, size.height)];
  
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return newImage;
}

@end
