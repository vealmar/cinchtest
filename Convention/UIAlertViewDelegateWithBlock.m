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
    
    UIAlertViewDelegateWithBlock __block *delegate = [[UIAlertViewDelegateWithBlock alloc] init];
    delegate.callback = ^(NSInteger buttonIndex) {
        callback(buttonIndex);
        alertView.delegate = nil;
//        delegate = nil;
    };
    
    [alertView setDelegate:delegate];
    [alertView show];
}

@end
