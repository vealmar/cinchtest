//
//  UIAlertViewDelegateWithBlock.h
//  Convention
//
//  Created by Kerry Sanders on 11/30/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIAlertViewDelegateWithBlock : NSObject<UIAlertViewDelegate>

typedef void (^AlertViewCompletionBlock)(NSInteger buttonIndex);

@property (strong, nonatomic) AlertViewCompletionBlock callback;

+(void)showAlertView:(UIAlertView *)alertView withCallBack:(AlertViewCompletionBlock)callback;

@end
