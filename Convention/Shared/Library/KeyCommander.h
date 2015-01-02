//
// Created by David Jafari on 1/2/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    KeyPressTypeAlphanumeric,
    KeyPressTypeArrow,
    KeyPressTypeEscape,
    KeyPressTypeEnter
} KeyPressType;

@protocol KeyCommanderDelegate <NSObject>

@optional

- (NSArray *)keyPressed:(KeyPressType)keyPressType withValue:(NSString *)value;

@end

@interface KeyCommander : UIView

@property (nonatomic, weak) id <KeyCommanderDelegate> delegate;

- (id)initWithDelegate:(id <KeyCommanderDelegate>)delegate;

- (BOOL)mayBecomeFirstResponder;

+ (NSArray *)alphanumericKeys:(SEL)targetAction;

+ (UIKeyCommand *)up:(SEL)targetAction;

+ (UIKeyCommand *)down:(SEL)targetAction;

+ (UIKeyCommand *)left:(SEL)targetAction;

+ (UIKeyCommand *)right:(SEL)targetAction;

+ (UIKeyCommand *)enter:(SEL)targetAction;

+ (UIKeyCommand *)escape:(SEL)targetAction;

@end