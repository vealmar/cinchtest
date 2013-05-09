//
//  CIFinalCustomerInfoViewController.h
//  Convention
//
//  Created by Matthew Clark on 4/25/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CICustomerInfoViewController.h"
#import "MICheckBox.h"

@protocol CIFinalCustomerDelegate <NSObject>

-(NSDictionary*)getCustomerInfo;
//- (IBAction)Cancel:(id)sender;
- (IBAction)submit:(id)sender;

@end

@interface CIFinalCustomerInfoViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *shippingNotes;
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *Notes;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *Authorizer;
@property (strong, nonatomic) IBOutlet UIScrollView *scroll;

@property (nonatomic, strong) NSArray* tableData;
@property (nonatomic, strong) NSMutableArray* filteredtableData;
-(void) setCustomerData:(NSArray *)customerData;
//- (IBAction)back:(id)sender;
//@property (weak, nonatomic) IBOutlet UISwitch *contact;
//@property (nonatomic, strong) IBOutlet MICheckBox *contactBeforeShipping;

@property (nonatomic, assign) id<CICustomerDelegate,CIFinalCustomerDelegate> delegate;

- (IBAction)submit:(id)sender;

@end
