//
//  CIPrintViewController.h
//  Convention
//
//  Created by Matthew Clark on 8/1/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPrintViewController : UIViewController
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *isle;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *booth;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *notesLbl;
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *notes;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *PrintHeader;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblorder;
@property (nonatomic, strong) NSString* orderID;
- (IBAction)cancel:(id)sender;
- (IBAction)submit:(id)sender;

@end
