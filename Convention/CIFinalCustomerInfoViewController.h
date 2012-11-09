//
//  CIFinalCustomerInfoViewController.h
//  Convention
//
//  Created by Matthew Clark on 4/25/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CICustomerInfoViewController.h"
@protocol CIFinalCustomerDelegate <NSObject>

-(NSDictionary*)getCustomerInfo;
- (IBAction)Cancel:(id)sender;
- (IBAction)submit:(id)sender;

@end

@interface CIFinalCustomerInfoViewController : UIViewController
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *shippingNotes;
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *Notes;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *Authorizer;
@property (strong, nonatomic) IBOutlet UIScrollView *scroll;
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *sendEmail;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *email;

@property (nonatomic, strong) NSArray* tableData;
@property (nonatomic, strong) NSMutableArray* filteredtableData;
-(void) setCustomerData:(NSArray *)customerData;
- (IBAction)back:(id)sender;

@property (nonatomic, assign) id<CICustomerDelegate,CIFinalCustomerDelegate> delegate;

- (IBAction)submit:(id)sender;

@end
