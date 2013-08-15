//
//  CIViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIViewController.h"
#import "config.h"
#import "JSONKit.h"
#import "Macros.h"
#import "CIOrderViewController.h"
#import "MBProgressHUD.h"
#import "SettingsManager.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "ShowConfigurations.h"

@implementation CIViewController {
    CGRect originalBounds;
    __weak IBOutlet UIImageView *loginBg;
}
@synthesize email;
@synthesize password;
@synthesize error;
@synthesize authToken;
@synthesize vendorInfo;
@synthesize vendorGroup;
@synthesize lblVersion;
@synthesize managedObjectContext;
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    loginBg.image = [[ShowConfigurations instance] loginScreen];
    originalBounds = self.view.bounds;
    authToken = nil;
    self.vendorInfo =nil;
}

- (void)viewDidUnload
{
    [self setEmail:nil];
    [self setPassword:nil];
    [self setVendorInfo:nil];
    [self setError:nil];
    [self setLblVersion:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.email.font = [UIFont fontWithName:kFontName size:14.f];
    self.password.font = [UIFont fontWithName:kFontName size:14.f];
    self.lblVersion.font = [UIFont fontWithName:kFontName size:14.f];
	
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	
	self.email.text = [[SettingsManager sharedManager] lookupSettingByString:@"username"];
    self.password.text = [[SettingsManager sharedManager] lookupSettingByString:@"password"];

    DLog(@"%@,%@",version, build);
    
    self.lblVersion.text = [NSString stringWithFormat:@"CI %@.%@", version, build];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    [super viewWillAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
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
    
    NSString* Email = (email.text) ? email.text : @"";
    NSString* Password = (password.text) ? password.text : @"";
    
    MBProgressHUD* __weak loginHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    loginHud.labelText = @"Logging in...";
    [loginHud show:YES];
    
    DLog(@"Login URL:%@",kDBLOGIN);
    
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kDBLOGIN]];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:Email, kEmailKey, Password, kPasswordKey, nil];
    NSMutableURLRequest *request = [client requestWithMethod:@"POST" path:nil parameters:params];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
         success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
             
             if (JSON && [[JSON objectForKey:kResponse] isEqualToString:kOK]) {
                 authToken = [JSON objectForKey:kAuthToken];
                 vendorInfo = [NSDictionary dictionaryWithDictionary:JSON];
                 DLog(@"Login JSON: %@", JSON);
                 
                 if ([JSON objectForKey:kID]) {
                     vendorGroup = [[JSON objectForKey:kID] stringValue];
                 }

                 UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CIOrderViewController" bundle:nil];
                 CIOrderViewController *masterViewController = [storyboard instantiateInitialViewController];
                 masterViewController.authToken = authToken;
                 masterViewController.vendorInfo = [vendorInfo copy];
                 masterViewController.vendorGroup = vendorGroup;
                 masterViewController.managedObjectContext = self.managedObjectContext;
                 
                 NSDictionary *shows = [JSON objectForKey:@"shows"];
                 if (shows != nil) {
                     NSDictionary *features = [shows objectForKey:@"features"];
                     masterViewController.allowPrinting = [[features objectForKey:@"printing"] intValue];
                     masterViewController.showShipDates = [[features objectForKey:@"shipdates"] intValue];
                 }
                 
                 [self presentViewController:masterViewController animated:YES completion:nil];
                 
                 [[SettingsManager sharedManager] saveSetting:@"username" value:email.text];
                 [[SettingsManager sharedManager] saveSetting:@"password" value:password.text];
             }
             
             [loginHud hide:YES];
             
         } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *requestError, id JSON) {
             
             if (JSON) {
                 
                 self.error.text = [JSON objectForKey:@"error"];
                 [loginHud hide:YES];
                 
             } else if (requestError) {
                 [loginHud hide:YES];
                 [[[UIAlertView alloc] initWithTitle:@"Error" message:[requestError localizedDescription]
                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
             } else {
                 [loginHud hide:YES];
                 [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An unknown error occurred. Please try login again."
                                            delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
             }
         }];
    
    [op start];
}

- (void) keyboardWillShow:(NSNotification*)notification {
    if (self.view.bounds.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.bounds.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)keyboardWillHide:(NSNotification *)notification {
    if (self.view.bounds.origin.y < 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.bounds.origin.y >= 0)
    {
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
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.bounds;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += kOFFSET_FOR_KEYBOARD + 15;
        //rect.size.height -= keyboardOffset; // kOFFSET_FOR_KEYBOARD;
        self.view.bounds = rect;
    }
    else
    {
        // revert back to the normal state.
        //rect.origin.y = 0; //-= keyboardOffset; // kOFFSET_FOR_KEYBOARD;
        //rect.size.height += keyboardOffset; // kOFFSET_FOR_KEYBOARD;
        //rect = originalBounds;
        
        self.view.bounds = originalBounds;
    }
    
    [UIView commitAnimations];
}

@end
