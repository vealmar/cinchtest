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

@implementation CIViewController
@synthesize email;
@synthesize password;
@synthesize error;
@synthesize authToken;
@synthesize venderInfo;
@synthesize masterVender;
@synthesize vendorGroup;
@synthesize lblVersion;
@synthesize managedObjectContext;

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        masterVender = NO;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    authToken = nil;
    
    //for testing
 
//    
//    self.email.text = @"afc-mer58982";
//    self.password.text = @"2210";
    
//    self.email.text = @"afc-agr00601";
//    self.password.text = @"9695";
    
    //show 1 testing
//    self.email.text = @"AFC-MER58982";
//    self.password.text = @"2210";
    
    //show 2 testing
//    self.email.text = @"afc-acm00351";
//    self.password.text = @"2984";

    //PW local testing
//    self.email.text = @"pw-500";
//    self.password.text = @"82879";
    
    //email testing
//    self.email.text = @"v1";
//    self.password.text = @"testing";
    
    self.venderInfo =nil;
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setEmail:nil];
    [self setPassword:nil];
    [self setVenderInfo:nil];
    [self setError:nil];
    [self setLblVersion:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
    
//    DLog(@"fonts:%@ %@ %@",[UIFont fontWithName:kFontName size:14.f],[UIFont fontWithName:@"bebas" size:14.f],[UIFont fontWithName:@"Bebas" size:14.f]);
    
    [super viewWillAppear:animated];
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
                 [venderInfo addObject:JSON];
                 NSDictionary *venderGroupId = [JSON objectForKey:kVendorGroupID];
                 if (venderGroupId && [venderGroupId objectForKey:kID]) {
                     vendorGroup = [[venderGroupId objectForKey:kID] stringValue];
                 }
                 
                 CIOrderViewController *masterViewController = [[CIOrderViewController alloc] initWithNibName:@"CIOrderViewController" bundle:nil];
                 masterViewController.authToken = authToken;
                 masterViewController.venderInfo = [venderInfo copy];
                 masterViewController.vendorGroup = vendorGroup;
                 masterViewController.managedObjectContext = self.managedObjectContext;
                 
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

- (IBAction)dismissKB:(id)sender {
    if ([self.email isFirstResponder]) {
        [self.email resignFirstResponder];
    }
    else if ([self.password isFirstResponder]) {
        [self.password resignFirstResponder];
    }
}
@end
