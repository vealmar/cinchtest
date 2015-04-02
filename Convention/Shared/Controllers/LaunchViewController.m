//
//  LaunchViewController.m
//  Convention
//
//  Created by septerr on 8/10/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "LaunchViewController.h"
#import "config.h"
#import "SettingsManager.h"
#import "CILoginViewController.h"
#import "Configurations.h"
#import "CinchJSONAPIClient.h"
#import "MBProgressHUD.h"
#import "NilUtil.h"


@interface LaunchViewController ()
@property(weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIButton *launchButton;
@property (weak, nonatomic) IBOutlet UIView *launchBox;
@property(weak) MBProgressHUD *hud;
@end

@implementation LaunchViewController{
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSString *code = [NilUtil objectOrEmptyString:[[SettingsManager sharedManager] getCode]];
    if ([self.codeTextField.text length] == 0) {
        code = [code stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (code.length > 0) {
            self.codeTextField.text = code;
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.codeTextField) {
        [self.codeTextField resignFirstResponder];
        [self launch];
    }
    return YES;
}

- (IBAction)launchPressed:(UIButton *)sender {
    [self launch];
}

- (void)launch{
    NSString *code = self.codeTextField.text ? [self.codeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : nil;
    if ([code length] > 0) {//length can handle nil
        [self loadConfigurationsByHostCode:code];
    } else {
        [self shakeView:self.codeTextField iterations:10 direction:1];
    }
}

- (void)loadConfigurationsByHostCode:(NSString *)code {
    if ([[[SettingsManager sharedManager] getServerUrl] length] > 0) {
        [[CinchJSONAPIClient sharedInstance] reload]; //In case user changed the url in settings and came back to the launch screen. Reload the api client so it will use the correct url.
        NSString *configUrl = [NSString stringWithFormat:kConfigsByCodeUrl, code];
        [[CinchJSONAPIClient sharedInstance] GET:configUrl parameters:@{} success:^(NSURLSessionDataTask *task, id JSON) {
            NSLog(@"%@", JSON);
            if ([JSON valueForKey:@"host"]) {
                //Code is valid. Load configurations.
                [Configurations createInstanceFromJson:(NSDictionary *) [((NSDictionary *) JSON) valueForKey:@"configurations"]];
                [[SettingsManager sharedManager] setCode:code];
                [[SettingsManager sharedManager] setHostId:HostIdSetting];
                NSString *hostUrl = [((NSDictionary *) [JSON valueForKey:@"host"]) valueForKey:@"url"];
                if (hostUrl.length > 0 && ![hostUrl isEqualToString:[[SettingsManager sharedManager] getServerUrl]]) {
                    [[SettingsManager sharedManager] setServerUrl:hostUrl];
                }
                if ([JSON valueForKey:@"show"]) {
                    [[SettingsManager sharedManager] setShowId:(NSNumber *) [((NSDictionary *) [JSON valueForKey:@"show"]) valueForKey:@"id"]];
                }
                [self hideHud];
                [self presentLoginView];
            } else {
                [self hideHud];
                [self alert:@"Error" message:[NSString stringWithFormat:@"The code '%@' is invalid.", code]];
            }
        }                                failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"%@", [error localizedDescription]);
            [self hideHud];
            [self alert:@"Error" message:@"Something went wrong while connecting with the server. Please try again. If the problem persists, contact your company or Cinch Sales."];
        }];
        [self showHud:@"Validating code"];
    } else {
        [self alert:@"Error" message:@"Server URL setting is required. Please see Cinch under Settings."];
    }
}

- (void)presentLoginView {
    CILoginViewController *loginViewController = [[CILoginViewController alloc] initWithNibName:@"CIViewController_iPad" bundle:nil];
    loginViewController.managedObjectContext = self.managedObjectContext;
    [self presentViewController:loginViewController animated:YES completion:nil];
}

- (void)shakeView:(UIView *)view iterations:(NSInteger)iterations direction:(NSInteger)direction {
    [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        view.transform = CGAffineTransformMakeTranslation((CGFloat) (10.0 * direction), 0);
    }                completion:^(BOOL finished) {
        if (finished) {
            if (iterations > 0) {
                [self shakeView:view iterations:(iterations - 1) direction:(direction * -1)];
            } else {
                view.transform = CGAffineTransformIdentity;
            }
        }
    }];
}

- (void)showHud:(NSString *)message {
    if (self.hud == nil) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.removeFromSuperViewOnHide = YES;
    }
    self.hud.labelText = message;
    [self.hud show:YES];
}

- (void)hideHud {
    if (self.hud != nil) {
        [self.hud hide:YES];
    }
}

- (void)alert:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    //make sure the text field and launch button are not covered by the keyboard by making sure the launch button is visible.
    NSDictionary* info = [notification userInfo];
    NSValue *kbFrame = info[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    CGFloat keyboardHeight = MIN(keyboardFrame.size.width, keyboardFrame.size.height);
    CGPoint buttonOrigin = CGPointMake(self.launchButton.frame.origin.x + self.launchBox.frame.origin.x, self.launchButton.frame.origin.y + self.launchBox.frame.origin.y);//since the button is embedded in Launch View, add Launch View's x and y to get the origin w.r.t. self.view
    CGRect visibleRect = self.view.frame;
    visibleRect.size.height -= keyboardHeight;
    if (!CGRectContainsPoint(visibleRect, buttonOrigin)){
        CGPoint scrollPoint = CGPointMake(0.0, buttonOrigin.y - visibleRect.size.height + self.launchButton.frame.size.height);
        [(UIScrollView *)self.view setContentOffset:scrollPoint animated:YES];
    }

}
- (void)keyboardDidHide:(NSNotification *)notification {
    [(UIScrollView *)self.view setContentOffset:CGPointZero animated:YES];
}
@end
