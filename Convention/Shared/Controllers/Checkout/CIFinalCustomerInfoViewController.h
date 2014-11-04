//
//  CIFinalCustomerInfoViewController.h
//  Convention
//
//  Created by Matthew Clark on 4/25/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

/**
* SG: This is the view that is displayed after you Submit an order. It prompts the user for information like Authorized By and Notes.
*/
#import <UIKit/UIKit.h>
#import "CICustomerInfoViewController.h"
#import "MICheckBox.h"
#import "OrderShipDateViewController.h"

@class Order;

@protocol CIFinalCustomerDelegate <NSObject>
- (NSDictionary *)getCustomerInfo;
- (IBAction)submit:(id)sender;
- (void)dismissFinalCustomerViewController;
@end

@interface CIFinalCustomerInfoViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
@property(nonatomic, assign) id <CIFinalCustomerDelegate> delegate;
@property Order *order;
@end
