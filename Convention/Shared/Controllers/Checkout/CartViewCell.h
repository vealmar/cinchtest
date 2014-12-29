//
// Created by septerr on 9/2/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@protocol ProductCellDelegate;
@class LineItem;


@interface CartViewCell : UITableViewCell <UITextFieldDelegate>
@property(weak, nonatomic) IBOutlet UILabel *InvtID;
@property(nonatomic, assign) id <ProductCellDelegate> delegate;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *errorMessageHeightConstraint;
@property(weak, nonatomic) IBOutlet UITextView *errorMessageView;

- (void)updateErrorsView:(LineItem *)lineItem;
@end