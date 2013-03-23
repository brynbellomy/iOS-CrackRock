//
//  SECrackRockSpec.m
//  iOS-CrackRock
//
//  Created by bryn austin bellomy on 7/22/12.
//  Copyright 2012 illumntr. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <iOS-CrackRock/SECrackRock.h>


SPEC_BEGIN(SECrackRockSpec)

describe(@"SECrackRock", ^{
  
  context(@"when it's initialized", ^{
    
    __block SECrackRock *crackRock = nil;
    
    beforeAll(^{
        crackRock = [[SECrackRock alloc] init];
    });
    
    it(@"is not nil", ^{
      [crackRock shouldNotBeNil];
    });
    
  });
  
});


SPEC_END







