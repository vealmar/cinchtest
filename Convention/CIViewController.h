//
//  CIViewController.h
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CIProductViewController.h"

@interface CIViewController : UIViewController <UITextFieldDelegate>
@property(unsafe_unretained, nonatomic) IBOutlet UITextField *email;
@property(unsafe_unretained, nonatomic) IBOutlet UITextField *password;
@property(unsafe_unretained, nonatomic) IBOutlet UITextView *error;
@property(nonatomic, strong) NSString *authToken;
@property(nonatomic, strong) NSDictionary *vendorInfo;
//Logged in vendor's details.
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *lblVersion;
@property(strong, nonatomic) IBOutlet UIView *mainView;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (IBAction)login:(id)sender;

- (IBAction)dismissKB:(id)sender;

@end
