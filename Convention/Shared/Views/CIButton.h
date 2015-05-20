//
// Created by David Jafari on 2/13/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    CIButtonSizeLarge,
    CIButtonSizeSmall
} CIButtonSize;

typedef enum {
    CIButtonStyleCreate,
    CIButtonStyleDestroy,
    CIButtonStyleNeutral,
    CIButtonStyleCancel
} CIButtonStyle;

#define CIBUTTON_MARGIN 8.0F

@interface CIButton : UIButton

@property (assign) NSString *title;

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle;

- (instancetype)initWithOrigin:(CGPoint)origin title:(NSString *)title size:(CIButtonSize)size style:(CIButtonStyle)style;

@end