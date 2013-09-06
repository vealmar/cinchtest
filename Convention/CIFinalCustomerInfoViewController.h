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

@protocol CIFinalCustomerDelegate <NSObject>

- (NSDictionary *)getCustomerInfo;

- (IBAction)submit:(id)sender;

- (void)setAuthorizedByInfo:(NSDictionary *)info;

@end

@interface CIFinalCustomerInfoViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
@property(unsafe_unretained, nonatomic) IBOutlet UITextView *shippingNotes;
@property(unsafe_unretained, nonatomic) IBOutlet UITextView *Notes;
@property(unsafe_unretained, nonatomic) IBOutlet UITextField *Authorizer;
@property(strong, nonatomic) IBOutlet UIScrollView *scroll;

@property(nonatomic, strong) NSArray *tableData;
@property(nonatomic, strong) NSMutableArray *filteredtableData;

@property(nonatomic, assign) id <CIFinalCustomerDelegate> delegate;

- (IBAction)submit:(id)sender;

@end
