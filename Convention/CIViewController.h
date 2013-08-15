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
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *email;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *password;
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *error;
@property (nonatomic, strong) NSString* authToken;
@property (nonatomic, strong) NSDictionary* vendorInfo;//SG: NSDictionary containing the JSON returned by the web app after the user logs in. It contains vendor fields:id, name, auth_token, hideshprice, vendorgroup_id, isle, booth, dept and shows. I think shows points to one of the shows the vendor has been associated with. Not necessarily the show we are presently dealing with.
@property (nonatomic, strong) NSString* vendorGroup; //SG: This is actually the vendor's id i.e. id field of the logged in vendor.
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblVersion;
@property (strong, nonatomic) IBOutlet UIView *mainView;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;

- (IBAction)login:(id)sender;
- (IBAction)dismissKB:(id)sender;
//-(void)logout;

@end
