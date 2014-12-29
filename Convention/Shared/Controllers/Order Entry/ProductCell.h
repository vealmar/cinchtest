//
// Created by septerr on 8/19/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class LineItem;

@interface ProductCell : UITableViewCell <UITextFieldDelegate>
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *InvtID;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *errorMessageHeightConstraint;
@property(weak, nonatomic) IBOutlet UITextView *errorMessageView;

- (void)updateErrorsView:(LineItem *)cart;

@end