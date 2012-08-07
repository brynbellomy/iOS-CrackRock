//
//  SECrackRockSpec.m
//  iOS-CrackRock
//
//  Created by bryn austin bellomy on 7/22/12.
//  Copyright 2012 illumntr. All rights reserved.
//

#import "Kiwi.h"
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





//#import "Kiwi.h"
//#import "SEStatelyNotificationRobot.h"
//#import "SEStatelyNotificationHandler.h"
//
///**
// * SEStatelyNotificationRobot private interface for testing only
// */
//@interface SEStatelyNotificationRobot (PrivateInterfaceForTesting)
//
//@property (nonatomic, strong, readwrite) NSMutableDictionary *handlerIDsToHandlers;
//@property (nonatomic, strong, readwrite) NSMutableDictionary *stativeThingNamesToStativeThings;
//
//@end
//
//
//
//
//
///**
// * the spec
// */
//SPEC_BEGIN(SEStatelyNotificationRobotSpec)
//
//describe(@"SEStatelyNotificationRobot", ^{
//  
//  context(@"when first initialized", ^{
//    __block SEStatelyNotificationRobot *robot;
//    
//    beforeAll(^{
//      robot = [[SEStatelyNotificationRobot alloc] init];
//    });
//    
//    it(@"is not nil", ^{
//      [[robot shouldNot] beNil];
//    });
//    
//    it(@"has a 'handlerIDsToHandlers' property that is an empty NSMutableDictionary", ^{
//      [[robot.handlerIDsToHandlers shouldNot] beNil];
//      [[robot.handlerIDsToHandlers should] beKindOfClass:[NSMutableDictionary class]];
//      [[robot.handlerIDsToHandlers should] beEmpty];
//    });
//    
//    it(@"has a 'stativeThingNamesToStativeThings' property that is an empty NSMutableDictionary", ^{
//      [[robot.stativeThingNamesToStativeThings shouldNot] beNil];
//      [[robot.stativeThingNamesToStativeThings should] beKindOfClass:[NSMutableDictionary class]];
//      [[robot.stativeThingNamesToStativeThings should] beEmpty];
//    });
//    
//    it(@"always returns SEStateUndefined for '-stateOf:(NSString *)stativeThing'", ^{
//      [[robot should] receive:@selector(stateOf:) andReturn:theValue(SEStateUndefined) withArguments:any()];
//      SEState state = [robot stateOf:any()];
//      [[theValue(state) should] equal:theValue(SEStateUndefined)];
//    });
//    
//    it(@"always returns nil for '-stateInfoForStateOf:(NSString *)stativeThing'", ^{
//      [[robot should] receive:@selector(stateInfoForStateOf:) andReturn:nil withArguments:any()];
//      id stateInfo = [robot stateInfoForStateOf:any()];
//      [stateInfo shouldBeNil];
//    });
//    
//    
//  });
//  
//  context(@"when accessed through its singleton instance", ^{
//    __block SEStatelyNotificationRobot *singleton;
//    
//    beforeAll(^{
//      singleton = [SEStatelyNotificationRobot sharedRobot];
//    });
//    
//    it(@"is not nil", ^{
//      [singleton shouldNotBeNil];
//    });
//    
//    it(@"always returns a pointer to the same object", ^{
//      SEStatelyNotificationRobot *singleton2 = [SEStatelyNotificationRobot sharedRobot];
//      [[singleton should] beIdenticalTo:singleton2];
//    });
//  });
//  
//  
//  context(@"when a handler is registered for a new stativeThingName that has not yet been referred to with -[changeStateOf:to:]", ^{
//    NSString *const stativeThingName = @"myStativeThing";
//    NSString *const handlerID = @"testHandler1";
//    
//    __block NSNumber *outsideState;
//    __block NSDictionary *outsideStateInfo;
//    __block NSUInteger callsToHandlerBlock;
//    __block SEStatelyNotificationRobot *robot;
//    
//    beforeAll(^{
//      outsideState = nil;
//      outsideStateInfo = nil;
//      callsToHandlerBlock = 0;
//      
//      robot = [[SEStatelyNotificationRobot alloc] init];
//      
//      [robot handleStateOf: stativeThingName
//                 handlerID: handlerID
//                   onQueue: [NSOperationQueue mainQueue]
//                 withBlock: ^(SEState newState, NSDictionary *stateInfo) {
//                   outsideState = [NSNumber numberWithInteger:newState];
//                   outsideStateInfo = stateInfo;
//                   callsToHandlerBlock++;
//                 }];
//    });
//    
//    it(@"should immediately call the new handler block with a state of SEStateUndefined and an empty stateInfo dictionary", ^{
//      [[expectFutureValue(outsideState) shouldEventually] beNonNil];
//      [[expectFutureValue(outsideState) shouldEventually] beKindOfClass:[NSNumber class]];
//      [[expectFutureValue(outsideState) shouldEventually] equal:[NSNumber numberWithInteger:SEStateUndefined]];
//      [[expectFutureValue(outsideStateInfo) shouldEventually] beNonNil];
//      [[expectFutureValue(outsideStateInfo) shouldEventually] beKindOfClass:[NSDictionary class]];
//      [[expectFutureValue(outsideStateInfo) shouldEventually] beEmpty];
//    });
//    
//    it(@"returns SEStateUndefined for the state of that stative thing", ^{
//      SEState state = [robot stateOf:stativeThingName];
//      [[theValue(state) should] equal:theValue(SEStateUndefined)];
//    });
//    
//    it(@"returns an empty NSDictionary for the stateInfo of that stative thing", ^{
//      id stateInfo = [robot stateInfoForStateOf:stativeThingName];
//      [stateInfo shouldNotBeNil];
//      [[stateInfo should] beKindOfClass:[NSDictionary class]];
//      [[stateInfo should] beEmpty];
//    });
//    
//    it(@"has a 'handlerIDsToHandlers' property (NSDictionary, 1 elem) mapping the passed-in handlerID to an init'ed SEStatelyNotificationHandler object", ^{
//      [[robot.handlerIDsToHandlers should] haveCountOf:1];
//      
//      id handler = [robot.handlerIDsToHandlers objectForKey:handlerID];
//      [handler shouldNotBeNil];
//      [[handler should] beKindOfClass:[SEStatelyNotificationHandler class]];
//    });
//    
//    it(@"has only called its handler block once before changeStateOf:to: is ever called on it", ^{
//      [[theValue(callsToHandlerBlock) shouldEventually] equal:theValue(1)];
//    });
//    
//    
//    context(@"when it receives the first call to -[changeStateOf:to:stateInfo:]", ^{
//      const SEState newState = SEStateInProgress;
//      __block NSDictionary *newStateInfo;
//      
//      beforeAll(^{
//        newStateInfo = [NSDictionary dictionaryWithObject:@"the object" forKey:@"the key"];
//        [robot changeStateOf:stativeThingName to:newState stateInfo:newStateInfo];
//      });
//      
//      it(@"will have called the handler block exactly twice", ^{
//        [[theValue(callsToHandlerBlock) shouldEventually] equal:theValue(2)];
//      });
//      
//      it(@"calls the handler block with the same SEState passed to -[changeStateOf:to:stateInfo:]", ^{
//        [[expectFutureValue(outsideState) shouldEventually] equal:[NSNumber numberWithInteger:newState]];
//      });
//      
//      it(@"calls the handler block with the same stateInfo dictionary passed to -[changeStateOf:to:stateInfo:]", ^{
//        [[expectFutureValue(outsideStateInfo) shouldEventually] equal:newStateInfo];
//      });
//    });
//    
//  });
//  
//});



