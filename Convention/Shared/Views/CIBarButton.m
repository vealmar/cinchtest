//
// Created by David Jafari on 12/21/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CIBarButton.h"
#import "ThemeUtil.h"

@interface CIBarButton()

@property UIView *circleView;
@property NSMutableDictionary *controlStateColors;
@property NSDictionary *defaultLabelAttributes;

@end

@implementation CIBarButton

- (id)initWithText:(NSString *)string
              style:(CIBarButtonStyle)style
            handler:(void (^)(id sender))handler {
    return [self initWithFrame:CGRectMake(5.0, 0, 34.0, 44.0) text:string style:style handler:handler];
}

- (id)initWithFrame:(CGRect)frame
                         text:(NSString *)string
                        style:(CIBarButtonStyle)style
                      handler:(void (^)(id sender))handler {
    self = [super initWithFrame:frame];
    if (self) {
        self.controlStateColors = [NSMutableDictionary dictionary];

        if (CIBarButtonStyleRoundButton == style) {
            [self setBackgroundColor:[ThemeUtil lightGreenColor] borderColor:[ThemeUtil lightGreenBorderColor] textColor:nil forControlState:UIControlStateNormal];
            self.defaultLabelAttributes = [ThemeUtil navigationRightActionButtonTextAttributes];
        } else {
            [self setBackgroundColor:[UIColor clearColor] borderColor:[UIColor clearColor] textColor:nil forControlState:UIControlStateNormal];
            self.defaultLabelAttributes = [ThemeUtil navigationLeftActionButtonTextAttributes];
        }

        [self bk_addEventHandler:handler forControlEvents:UIControlEventTouchUpInside];
        [self initCircleView];
        [self initLabel:string attributes:self.defaultLabelAttributes];

        [self setColorsForControlState:UIControlStateNormal];
        [self addSubview:self.circleView];
        [self addSubview:self.label];

        self.showsTouchWhenHighlighted = YES;
//        button.imageEdgeInsets = UIEdgeInsetsMake(0, 5.0, 0, -5.0);
    }

    return self;
}

+ (UIBarButtonItem *)buttonItemWithText:(NSString *)string
                              style:(CIBarButtonStyle)style
                            handler:(void (^)(id sender))handler {
    CIBarButton *button = [[CIBarButton alloc] initWithText:string
                                                       style:style
                                                     handler:handler];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    return item;
}   

- (void)initCircleView {
    UIView *circleView = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 34.0, 34.0)];
    circleView.userInteractionEnabled = NO;
    circleView.layer.cornerRadius = 17.0;
    circleView.layer.borderWidth = 2.0;
    self.circleView = circleView;
}

- (void)initLabel:(NSString *)string attributes:(NSDictionary *)attributes {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5.0, 0, 34.0, 44.0)];
    label.userInteractionEnabled = NO;
    label.textAlignment = NSTextAlignmentCenter;
    label.attributedText = [[NSAttributedString alloc] initWithString:string attributes:attributes];
    self.label = label;
}

- (void)setColorsForControlState:(UIControlState)uiControlState {
    NSArray *colors = (NSArray *) self.controlStateColors[[NSNumber numberWithInt:uiControlState]];
    if (!colors) {
        colors = (NSArray *) self.controlStateColors[[NSNumber numberWithInt:UIControlStateNormal]];
    }
    self.circleView.backgroundColor = colors[0];
    self.circleView.layer.borderColor = [colors[1] CGColor];
    self.tintColor = colors[0];
    self.label.textColor = [[NSNull null] isEqual:colors[2]] ? self.defaultLabelAttributes[NSForegroundColorAttributeName] : colors[2];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor borderColor:(UIColor *)borderColor textColor:(UIColor *)textColor forControlState:(UIControlState)uiControlState {
    self.controlStateColors[[NSNumber numberWithInt:uiControlState]] = @[backgroundColor, borderColor, (textColor ? textColor : [NSNull null])];
    if (UIControlStateNormal == uiControlState) {
        [self setColorsForControlState:UIControlStateNormal];
    }
}

- (void)setActive:(BOOL)active {
    if (active) {
        [self setColorsForControlState:UIControlStateHighlighted];
    } else {
        [self setColorsForControlState:UIControlStateNormal];
    }
}

@end