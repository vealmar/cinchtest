//
// Created by David Jafari on 1/29/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIApplication.h"

@interface CIApplication ()

@property BOOL isDisabled;

@end

static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

+(id)currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(cifindFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}

-(void)cifindFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end

@implementation CIApplication
//
//- (BOOL)mayBecomeFirstResponder {
//    if (![self isFirstResponder]) {
//        [self becomeFirstResponder];
//    }
//    return [self isFirstResponder];
//}
//
//- (BOOL)canBecomeFirstResponder {
////    return YES;
//    return NO;
//}
//
//- (BOOL)becomeFirstResponder {
//    return NO;
//}
//
//- (NSArray *)keyCommands {
//    return [CIApplication allKeys];
//}

+ (NSArray *)allKeys {
    static NSArray *keys;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        NSMutableArray *keyBuilder = [NSMutableArray array];
        [keyBuilder addObjectsFromArray:[CIApplication alphanumericKeys]];
        [keyBuilder addObject:[CIApplication up:@selector(upKeyPressed)]];
        [keyBuilder addObject:[CIApplication down:@selector(downKeyPressed)]];
        [keyBuilder addObject:[CIApplication left:@selector(leftKeyPressed)]];
        [keyBuilder addObject:[CIApplication right:@selector(rightKeyPressed)]];
        [keyBuilder addObject:[CIApplication enter:@selector(enterKeyPressed)]];
        [keyBuilder addObject:[CIApplication escape:@selector(escapeKeyPressed)]];
        keys = [NSArray arrayWithArray:keyBuilder];
    });
    return keys;
}

+ (NSArray *)alphanumericKeys {
    NSMutableArray *keys = [NSMutableArray array];

    for (NSString *key in [self alphabet]) {
        SEL keyMethod = NSSelectorFromString([key stringByAppendingString:@"KeyPressed"]);
        [keys addObject:[UIKeyCommand keyCommandWithInput:key modifierFlags:0 action:keyMethod]];
        [keys addObject:[UIKeyCommand keyCommandWithInput:key modifierFlags:UIKeyModifierShift action:keyMethod]];
    }

    for (NSString *key in [self numbers]) {
        SEL keyMethod = NSSelectorFromString([NSString stringWithFormat:@"n%@KeyPressed", key]);
        [keys addObject:[UIKeyCommand keyCommandWithInput:key modifierFlags:0 action:keyMethod]];
        [keys addObject:[UIKeyCommand keyCommandWithInput:key modifierFlags:UIKeyModifierNumericPad action:keyMethod]];
    }

    return [NSArray arrayWithArray:keys];
}

+ (UIKeyCommand *)up:(SEL)targetAction {
    return [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:targetAction];
}

+ (UIKeyCommand *)down:(SEL)targetAction {
    return [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:targetAction];
}

+ (UIKeyCommand *)left:(SEL)targetAction {
    return [UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow modifierFlags:0 action:targetAction];
}

+ (UIKeyCommand *)right:(SEL)targetAction {
    return [UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow modifierFlags:0 action:targetAction];
}

+ (UIKeyCommand *)enter:(SEL)targetAction {
    return [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:targetAction];
}

+ (UIKeyCommand *)escape:(SEL)targetAction {
    return [UIKeyCommand keyCommandWithInput:UIKeyInputEscape modifierFlags:0 action:targetAction];
}

#pragma mark - Private

- (void)keyPressed:(KeyPressType)keyPressType withValue:(NSString *)value {
    NSLog(@"key pressed: %@", value);
    if (!self.isDisabled && [self.delegate respondsToSelector:@selector(keyPressed:withValue:)]) {
//        [self.delegate keyPressed:keyPressType withValue:value];
    }
}

- (void)upKeyPressed {
    [self keyPressed:KeyPressTypeArrow withValue:UIKeyInputUpArrow];
}

- (void)downKeyPressed {
    [self keyPressed:KeyPressTypeArrow withValue:UIKeyInputDownArrow];
}

- (void)leftKeyPressed {
    [self keyPressed:KeyPressTypeArrow withValue:UIKeyInputLeftArrow];
}

- (void)rightKeyPressed {
    [self keyPressed:KeyPressTypeArrow withValue:UIKeyInputRightArrow];
}

- (void)enterKeyPressed {
    [self keyPressed:KeyPressTypeEnter withValue:@"\r"];
}

- (void)escapeKeyPressed {
    [self keyPressed:KeyPressTypeEscape withValue:UIKeyInputEscape];
}

- (void)aKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"a"];
}

- (void)bKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"b"];
}

- (void)cKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"c"];
}

- (void)dKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"d"];
}

- (void)eKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"e"];
}

- (void)fKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"f"];
}

- (void)gKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"g"];
}

- (void)hKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"h"];
}

- (void)iKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"i"];
}

- (void)jKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"j"];
}

- (void)kKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"k"];
}

- (void)lKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"l"];
}

- (void)mKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"m"];
}

- (void)nKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"n"];
}

- (void)oKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"o"];
}

- (void)pKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"p"];
}

- (void)qKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"q"];
}

- (void)rKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"r"];
}

- (void)sKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"s"];
}

- (void)tKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"t"];
}

- (void)uKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"u"];
}

- (void)vKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"v"];
}

- (void)wKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"w"];
}

- (void)xKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"x"];
}

- (void)yKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"y"];
}

- (void)zKeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"z"];
}

- (void)n0KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"0"];
}

- (void)n1KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"1"];
}

- (void)n2KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"2"];
}

- (void)n3KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"3"];
}

- (void)n4KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"4"];
}

- (void)n5KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"5"];
}

- (void)n6KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"6"];
}

- (void)n7KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"7"];
}

- (void)n8KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"8"];
}

- (void)n9KeyPressed {
    [self keyPressed:KeyPressTypeAlphanumeric withValue:@"9"];
}

+ (NSArray *)alphabet {
    static NSArray *keys;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        keys = @[@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l", @"m", @"n", @"o", @"p", @"q", @"r", @"s", @"t", @"u", @"v", @"w", @"x", @"y", @"z"];
    });
    return keys;
}

+ (NSArray *)numbers {
    static NSArray *keys;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        keys = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0"];
    });
    return keys;
}

@end