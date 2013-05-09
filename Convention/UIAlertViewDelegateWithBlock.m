//
//  UIAlertViewDelegateWithBlock.m
//  Convention
//
//  Created by Kerry Sanders on 11/30/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "UIAlertViewDelegateWithBlock.h"

@implementation UIAlertViewDelegateWithBlock
@synthesize callback;

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    callback(buttonIndex);
}

+(void)showAlertView:(UIAlertView *)alertView withCallBack:(AlertViewCompletionBlock)callback {
    
    __block UIAlertViewDelegateWithBlock *delegate = [[UIAlertViewDelegateWithBlock alloc] init];
    alertView.delegate = delegate;
    delegate.callback = ^(NSInteger buttonIndex) {
        callback(buttonIndex);
        alertView.delegate = nil;
        delegate = nil;
    };
    
    [alertView show];
}

@end
