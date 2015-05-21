//
//  LaunchViewController.h
//  Convention
//
//  Created by septerr on 8/10/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LaunchViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property(weak, nonatomic) IBOutlet UITextField *codeTextField;

- (IBAction)launchPressed:(UIButton *)sender;
@end
