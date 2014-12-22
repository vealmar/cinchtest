//
// Created by David Jafari on 12/21/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CIBarButtonStyle) {
    CIBarButtonStyleRoundButton,
    CIBarButtonStyleTextButton
};

@interface CIBarButton : UIButton

@property (assign) BOOL active;
@property UILabel *label;

+ (UIBarButtonItem *)buttonItemWithText:(NSString *)string
                                  style:(CIBarButtonStyle)style
                                handler:(void (^)(id sender))handler;

- (id)initWithText:(NSString *)string
             style:(CIBarButtonStyle)style
           handler:(void (^)(id sender))handler;

- (void)setBackgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor textColor:(UIColor *)textColor forControlState:(UIControlState)uiControlState;

@end


