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
#import "CIFinalCustomerFormViewController.h"
#import "CIAppDelegate.h"
#import "MenuViewController.h"


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
@synthesize vendorInfo;
@synthesize lblVersion;
@synthesize managedObjectContext;
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    loginBg.image = [[ShowConfigurations instance] loginScreen];
    originalBounds = self.view.bounds;
    authToken = nil;
    self.vendorInfo = nil;
}

- (void)viewDidUnload {
    [self setEmail:nil];
    [self setPassword:nil];
    [self setVendorInfo:nil];
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
    loginHud.labelText = @"Logging in";
    loginHud.removeFromSuperViewOnHide = YES;
    [loginHud show:NO];

    [[CinchJSONAPIClient sharedInstance] POST:kDBLOGIN parameters:@{ kEmailKey: Email, kPasswordKey: Password } success:^(NSURLSessionDataTask *task, id JSON) {
        [loginHud hide:NO];
        if (JSON && [[JSON objectForKey:kResponse] isEqualToString:kOK]) {
            authToken = [JSON objectForKey:kAuthToken];
            vendorInfo = [NSDictionary dictionaryWithDictionary:JSON];
            [self loadCustomers];
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        id JSON = error.userInfo[JSONResponseSerializerWithErrorDataKey];
        if (JSON) {
            self.error.text = [JSON objectForKey:@"error"];
            [loginHud hide:NO];
        } else if (error) {
            [loginHud hide:NO];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription]
                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            [loginHud hide:NO];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An unknown error occurred. Please try login again."
                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
}

- (void)loadCustomers {
    MBProgressHUD *__weak hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"Loading customers";
    [hud show:NO];

    [[CinchJSONAPIClient sharedInstance] GET:kDBGETCUSTOMERS parameters:@{ kAuthToken: authToken } success:^(NSURLSessionDataTask *task, id JSON) {
        [[CoreDataUtil sharedManager] deleteAllObjects:@"Customer"];
        if (JSON && ([(NSArray *) JSON count] > 0)) {
            NSArray *customers = (NSArray *) JSON;
            for (NSDictionary *customer in customers) {
                [self.managedObjectContext insertObject:[[Customer alloc] initWithCustomerFromServer:customer context:self.managedObjectContext]];
            }
            [[CoreDataUtil sharedManager] saveObjects];
        }
        [hud hide:NO];
        [self loadProducts];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [hud hide:NO];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        NSLog(@"%@ Error loading customers: %@", [self class], [error localizedDescription]);
    }];
}

- (void)loadProducts {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"Loading products";
    [hud show:NO];

    void (^successBlock)(id) = ^(id json) {
        [hud hide:NO];
        [self loadVendors];
    };

    void (^failureBlock)() = ^() {
        [hud hide:NO];
    };

    [CoreDataManager reloadProducts:self.authToken
                      vendorGroupId:[[self.vendorInfo objectForKey:kVendorGroupID] stringValue]
               managedObjectContext:self.managedObjectContext
                          onSuccess:successBlock
                          onFailure:failureBlock];
}

- (void)loadVendors {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"Loading vendors";
    [hud show:NO];
    [[CoreDataUtil sharedManager] deleteAllObjects:@"Vendor"];
    NSNumber *vendorGroupId = (NSNumber *) [NilUtil nilOrObject:[vendorInfo objectForKey:kVendorGroupID]];
    if (vendorGroupId) {
        [[CinchJSONAPIClient sharedInstance] GET:kDBGETVENDORSWithVG parameters:@{ kAuthToken: authToken, kVendorGroupID: vendorGroupId } success:^(NSURLSessionDataTask *task, id JSON) {
            if (JSON) {
                NSArray *results = [NSArray arrayWithArray:JSON];
                NSArray *vendors = [[results objectAtIndex:0] objectForKey:@"vendors"];
                for (NSDictionary *vendor in vendors) {
                    [self.managedObjectContext insertObject:[[Vendor alloc] initWithVendorFromServer:vendor context:self.managedObjectContext]];
                }
                [[CoreDataUtil sharedManager] saveObjects];
            }
            [hud hide:NO];
            [self loadBulletins];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [hud hide:NO];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            NSLog(@"%@ Error loading vendors: %@", [self class], [error localizedDescription]);
        }];
    }
}

- (void)loadBulletins {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"Loading bulletins";
    [hud show:NO];
    [[CoreDataUtil sharedManager] deleteAllObjects:@"Bulletin"];

    [[CinchJSONAPIClient sharedInstance] GET:kDBGETBULLETINS parameters:@{ kAuthToken: authToken } success:^(NSURLSessionDataTask *task, id JSON) {
        if (JSON) {
            for (NSDictionary *bulletin in JSON) {
                [self.managedObjectContext insertObject:[[Bulletin alloc] initWithBulletinFromServer:bulletin context:self.managedObjectContext]];
            }
            [[CoreDataUtil sharedManager] saveObjects];
        }
        [hud hide:NO];
        [self presentOrderViewController];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [hud hide:NO];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        NSLog(@"%@ Error loading bulletins: %@", [self class], [error localizedDescription]);
    }];
}

- (void)presentOrderViewController {
//    static UIViewController *c;
////    c = [[CIFinalCustomerInfoViewController alloc] init];
//    c = [[CIFinalCustomerFormViewController alloc] init];
//
//    c.modalPresentationStyle = UIModalPresentationFormSheet;
//    c.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//    [self presentViewController:c animated:YES completion:nil];
////    c.view.superview.bounds = CGRectMake(0, 0, 200, 200);
////    c.view.superview.center = CGPointMake(roundf(self.view.center.x), roundf(self.view.center.y));
//    return;

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CIOrderViewController" bundle:nil];
    CIOrderViewController *masterViewController = [storyboard instantiateInitialViewController];
    masterViewController.authToken = authToken;
    masterViewController.vendorInfo = [vendorInfo copy];
    masterViewController.managedObjectContext = self.managedObjectContext;

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
