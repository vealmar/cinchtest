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
       orientation:(CIBarButtonOrientation)orientation
           handler:(void (^)(id sender))handler {
    return [self initWithFrame:CGRectMake(0, 0, 44.0f, 44.0f) text:string style:style orientation:orientation handler:handler];
}

- (id)initWithFrame:(CGRect)frame
               text:(NSString *)string
              style:(CIBarButtonStyle)style
        orientation:(CIBarButtonOrientation)orientation
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
        [self initCircleView:orientation];
        [self initLabel:string attributes:self.defaultLabelAttributes orientation:orientation];

        [self setColorsForControlState:UIControlStateNormal];
        [self addSubview:self.circleView];
        [self addSubview:self.label];

        self.showsTouchWhenHighlighted = YES;
    }

    return self;
}

+ (UIBarButtonItem *)buttonItemWithText:(NSString *)string
                                  style:(CIBarButtonStyle)style
                            orientation:(CIBarButtonOrientation)orientation
                                handler:(void (^)(id sender))handler {
    CIBarButton *button = [[CIBarButton alloc] initWithText:string style:style orientation:orientation handler:handler];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    return item;
}   

- (void)initCircleView:(CIBarButtonOrientation)orientation {
    UIView *circleView = [[UIView alloc] initWithFrame:CGRectMake((orientation == CIBarButtonOrientationLeft ? 0 : 10.0f), 5.0f, 34.0f, 34.0f)];
    circleView.userInteractionEnabled = NO;
    circleView.layer.cornerRadius = 17.0;
    circleView.layer.borderWidth = 2.0;
    self.circleView = circleView;
}

- (void)initLabel:(NSString *)string attributes:(NSDictionary *)attributes orientation:(CIBarButtonOrientation)orientation {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((orientation == CIBarButtonOrientationLeft ? 0 : 10.0f), 0, 34.0f, 44.0f)];
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