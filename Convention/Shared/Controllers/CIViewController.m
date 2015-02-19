//
//  CIViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIViewController.h"
#import "config.h"
#import "CIOrderViewController.h"
#import "MBProgressHUD.h"
#import "SettingsManager.h"
#import "ShowConfigurations.h"
#import "Customer.h"
#import "CoreDataUtil.h"
#import "NilUtil.h"
#import "Vendor.h"
#import "Bulletin.h"
#import "CoreDataManager.h"
#import "CinchJSONAPIClient.h"
#import "JSONResponseSerializerWithErrorData.h"
#import "CIAppDelegate.h"
#import "MenuViewController.h"
#import "CurrentSession.h"
#import "NotificationConstants.h"
#import "VendorDataLoader.h"
#import "ThemeUtil.h"
#import "CISelectVendorViewController.h"


@implementation CIViewController {
    CGRect originalBounds;
    __weak IBOutlet UIImageView *loginBg;
    NSArray *vendorsData;
    NSDictionary *bulletins;
}
@synthesize email;
@synthesize password;
@synthesize error;
@synthesize authToken;
@synthesize userInfo;
@synthesize lblVersion;
@synthesize managedObjectContext;
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    loginBg.image = [[ShowConfigurations instance] loginScreen];
    originalBounds = self.view.bounds;
    authToken = nil;
    self.userInfo = nil;

    self.error.layer.cornerRadius = 5.0f;
    self.error.font = [UIFont semiboldFontOfSize:16.0];
    self.error.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
    self.error.hidden = YES;
}

- (void)viewDidUnload {
    [self setEmail:nil];
    [self setPassword:nil];
    [self setUserInfo:nil];
    [self setError:nil];
    [self setLblVersion:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    self.email.font = [UIFont fontWithName:kFontName size:14.f];
    self.password.font = [UIFont fontWithName:kFontName size:14.f];
    self.lblVersion.font = [UIFont fontWithName:kFontName size:14.f];

    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];

    self.email.text = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsUsernameKey];
    self.password.text = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsPasswordKey];

    self.lblVersion.text = [NSString stringWithFormat:@"CI %@.%@", version, build];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (UIInterfaceOrientationIsLandscape(interfaceOrientation));
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.email) {
        [theTextField resignFirstResponder];
        [self.password becomeFirstResponder];
    } else if (theTextField == self.password) {
        [self.password resignFirstResponder];
        [self login:nil];
    }
    return YES;
}

- (IBAction)login:(id)sender {
    [sender setSelected:YES];

    NSString *Email = (email.text) ? email.text : @"";
    NSString *Password = (password.text) ? password.text : @"";

    MBProgressHUD *__weak loginHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    loginHud.labelText = @"Logging In";
    loginHud.removeFromSuperViewOnHide = YES;
    [loginHud show:NO];

    [[CinchJSONAPIClient sharedInstance] POST:kDBLOGIN parameters:@{ kEmailKey: Email, kPasswordKey: Password } success:^(NSURLSessionDataTask *task, id JSON) {
        [loginHud hide:NO];
        self.error.hidden = YES;
        if (JSON && [[JSON objectForKey:kResponse] isEqualToString:kOK]) {
            authToken = [JSON objectForKey:kAuthToken];
            userInfo = [NSDictionary dictionaryWithDictionary:JSON];
            [CurrentSession instance].authToken = authToken;
            [CurrentSession instance].userInfo = userInfo;

            __weak CIViewController *weakSelf = self;

            [VendorDataLoader load:@[ @(VendorDataTypeCustomers), @(VendorDataTypeVendors) ] inView:self.view onComplete:^{
                if ([CurrentSession instance].hasAdminAccess) {
                    CISelectVendorViewController *ci = [[CISelectVendorViewController alloc] initWithNibName:@"CICustomerInfoViewController" bundle:nil];
                    ci.onComplete = ^{
                        [weakSelf presentOrderViewController];
                    };
                    [weakSelf presentViewController:ci animated:YES completion:nil];
                } else {
                    [VendorDataLoader load:@[@(VendorDataTypeBulletins), @(VendorDataTypeProducts)] inView:self.view onComplete:^{
                        [[CurrentSession mainQueueContext] performBlock:^{
//                            [[CurrentSession instance] dispatchSessionDidChange]; 1
                            [weakSelf presentOrderViewController];
                        }];
                    }];
                }
            }];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *apiError) {
        id JSON = apiError.userInfo[JSONResponseSerializerWithErrorDataKey];
        if (JSON) {
            self.error.text = [JSON objectForKey:@"error"];
            self.error.hidden = NO;
            [loginHud hide:NO];
        } else if (apiError) {
            [loginHud hide:NO];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[apiError localizedDescription]
                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            [loginHud hide:NO];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An unknown error occurred. Please try login again."
                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
}

- (void)presentOrderViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CIOrderViewController" bundle:nil];
    CIOrderViewController *masterViewController = [storyboard instantiateInitialViewController];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:masterViewController];

    CIAppDelegate *appDelegate = (CIAppDelegate*)[UIApplication sharedApplication].delegate;
    appDelegate.slideMenu = [APLSlideMenuViewController new];
    appDelegate.slideMenu.view.frame = [UIApplication sharedApplication].keyWindow.bounds;
    appDelegate.slideMenu.menuWidth = 280;
    appDelegate.slideMenu.contentViewController = nav;

    MenuViewController *menuController = [MenuViewController new];
    menuController.orderViewController = masterViewController;
    appDelegate.slideMenu.leftMenuViewController = menuController;

    nav.view.layer.shadowColor = [UIColor blackColor].CGColor;
    nav.view.layer.shadowOffset = CGSizeMake(3, 3);
    nav.view.layer.shadowRadius = 3;
    nav.view.layer.shadowOpacity = 0.5;
    nav.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:nav.view.bounds].CGPath;

    [self presentViewController:appDelegate.slideMenu animated:YES completion:nil];

    [[NSUserDefaults standardUserDefaults] setObject:self.email.text forKey:kSettingsUsernameKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.password.text forKey:kSettingsPasswordKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        static UIViewController *c;
//        //    c = [[CIFinalCustomerInfoViewController alloc] init];
//        c = [[CIFinalCustomerFormViewController alloc] init];
//
//        c.modalPresentationStyle = UIModalPresentationFormSheet;
//        c.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
////        [masterViewController presentViewController:c animated:YES completion:nil];
////    c.view.superview.bounds = CGRectMake(0, 0, 200, 200);
////    c.view.superview.center = CGPointMake(roundf(self.view.center.x), roundf(self.view.center.y));
//        return;
//    });
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (self.view.bounds.origin.y >= 0) {
        [self setViewMovedUp:YES];
    }
    else if (self.view.bounds.origin.y < 0) {
        [self setViewMovedUp:NO];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (self.view.bounds.origin.y < 0) {
        [self setViewMovedUp:YES];
    }
    else if (self.view.bounds.origin.y >= 0) {
        [self setViewMovedUp:NO];
    }
}

- (IBAction)dismissKB:(id)sender {
    if ([self.email isFirstResponder]) {
        [self.email resignFirstResponder];
    }
    else if ([self.password isFirstResponder]) {
        [self.password resignFirstResponder];
    }
}

//method to move the view up/down whenever the keyboard is shown/dismissed
- (void)setViewMovedUp:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view

    CGRect rect = self.view.bounds;
    if (movedUp) {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += kOFFSET_FOR_KEYBOARD + 15;
        //rect.size.height -= keyboardOffset; // kOFFSET_FOR_KEYBOARD;
        self.view.bounds = rect;
    }
    else {
        // revert back to the normal state.
        //rect.origin.y = 0; //-= keyboardOffset; // kOFFSET_FOR_KEYBOARD;
        //rect.size.height += keyboardOffset; // kOFFSET_FOR_KEYBOARD;
        //rect = originalBounds;

        self.view.bounds = originalBounds;
    }

    [UIView commitAnimations];
}

@end
