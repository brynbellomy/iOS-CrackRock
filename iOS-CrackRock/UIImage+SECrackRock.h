//
//  UIImage+SECrackRock.h
//  iOS-CrackRock
//
//  Created by bryn austin bellomy on 7/12/12.
//  Copyright (c) 2012 robot bubble bath LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage (SECrackRock)

- (UIImage *)imageWithOverlay:(UIImage *)overlay atPosition:(CGPoint)position withSize:(CGSize)size NS_RETURNS_RETAINED;

@end



