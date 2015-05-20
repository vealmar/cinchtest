//
// Created by David Jafari on 2/13/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIButton.h"
#import "ThemeUtil.h"

@interface CIButton ()

@property CIButtonSize size;
@property CIButtonStyle style;

@end

@implementation CIButton

- (instancetype)initWithOrigin:(CGPoint)origin title:(NSString *)title size:(CIButtonSize)size style:(CIButtonStyle)style {
    self = [super initWithFrame:CGRectMake(
            origin.x,
            origin.y,
            size == CIButtonSizeSmall ? 75.0F : 100.0F,
            size == CIButtonSizeSmall ? 30.0F : 40.0F
    )];
    if (self) {
        self.size = size;
        self.style = style;
        self.userInteractionEnabled = YES;
        self.layer.borderColor = [self borderColorFor:style];
        self.backgroundColor = [self backgroundColorFor:style];
        self.layer.borderWidth = 1.0f;
        self.layer.cornerRadius = 3.0f;

        self.showsTouchWhenHighlighted = YES;

        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self setTitle:title];
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *submitButtonTitleAttributes = @{
            NSFontAttributeName: [UIFont regularFontOfSize:(self.size == CIButtonSizeSmall ? 13 : 15)],
            NSForegroundColorAttributeName: [self fontColorFor:self.style],
            NSParagraphStyleAttributeName: paragraphStyle
    };
    self.titleLabel.numberOfLines = 1;
    [self setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:submitButtonTitleAttributes] forState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title subtitle:(NSString *)subtitle {
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *submitButtonTitleAttributes = @{
            NSFontAttributeName: [UIFont regularFontOfSize:(self.size == CIButtonSizeSmall ? 11 : 12)],
            NSForegroundColorAttributeName: [self fontColorFor:self.style],
            NSParagraphStyleAttributeName: paragraphStyle
    };
    NSDictionary *submitButtonSubtitleAttributes = @{
            NSFontAttributeName: [UIFont regularFontOfSize:9],
            NSForegroundColorAttributeName: [self fontColorFor:self.style],
            NSParagraphStyleAttributeName: paragraphStyle
    };

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:title attributes:submitButtonTitleAttributes]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:submitButtonTitleAttributes]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:subtitle attributes:submitButtonSubtitleAttributes]];
    [self setAttributedTitle:string forState:UIControlStateNormal];
    self.titleLabel.numberOfLines = 2;
}

- (CGColorRef)borderColorFor:(CIButtonStyle)style {
    switch(style) {
        case CIButtonStyleNeutral: { return [UIColor colorWithRed:0.902 green:0.494 blue:0.129 alpha:1.000].CGColor; }
        case CIButtonStyleCreate: { return [ThemeUtil lightGreenBorderColor].CGColor; }
        case CIButtonStyleDestroy: { return [ThemeUtil redBorderColor].CGColor; }
        case CIButtonStyleCancel: { return [ThemeUtil offWhiteBorderColor].CGColor; }
    }
    return nil;
}

- (UIColor *)backgroundColorFor:(CIButtonStyle)style {
    switch(style) {
        case CIButtonStyleNeutral: { return [UIColor colorWithRed:0.922 green:0.647 blue:0.416 alpha:1.000]; }
        case CIButtonStyleCreate: { return [ThemeUtil lightGreenColor]; }
        case CIButtonStyleDestroy: { return [ThemeUtil redBackgroundColor]; }
        case CIButtonStyleCancel: { return [ThemeUtil offWhiteColor]; }
    }
    return nil;
}

- (UIColor *)fontColorFor:(CIButtonStyle)style {
    switch(style) {
        case CIButtonStyleNeutral: { return [UIColor whiteColor]; }
        case CIButtonStyleCreate: { return [UIColor whiteColor]; }
        case CIButtonStyleDestroy: { return [UIColor whiteColor]; }
        case CIButtonStyleCancel: { return [ThemeUtil offBlackColor]; }
    }
    return [UIColor whiteColor];
}

@end