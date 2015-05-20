//
// Created by David Jafari on 2/16/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CIModalFormViewController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) XLFormViewController *formController;

- (id)initWithTitle:(NSString *)title;

- (void)addSections:(XLFormDescriptor *)formDescriptor;
- (void)setDefaultStyle:(XLFormRowDescriptor *)descriptor;
- (void)submit:(id)sender;
- (void)back:(id)sender;

@end