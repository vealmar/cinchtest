//
//  CIViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "config.h"
#import "JSONKit.h"
#import "Macros.h"
#import "CIOrderViewController.h"
#import "MBProgressHUD.h"
#import "SettingsManager.h"

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
	self.email.text = [[SettingsManager sharedManager] lookupSettingByString:@"username"];
    self.password.text = [[SettingsManager sharedManager] lookupSettingByString:@"password"];
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
    
    DLog(@"%@,%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]);
    
    self.lblVersion.text = [NSString stringWithFormat:@"CI %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    
//    DLog(@"fonts:%@ %@ %@",[UIFont fontWithName:kFontName size:14.f],[UIFont fontWithName:@"bebas" size:14.f],[UIFont fontWithName:@"Bebas" size:14.f]);
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (UIInterfaceOrientationIsLandscape(interfaceOrientation));
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == self.email) {
        [theTextField resignFirstResponder];
		[self.password becomeFirstResponder];
    } else if (theTextField == self.password) {
        [self login:nil];
    }
    return YES;
}


-(void)logout
{
    if (!masterVender) {
        NSString* url = kDBLOGOUT;
        if (authToken) {
            url = [NSString stringWithFormat:@"%@?%@=%@",kDBLOGOUT,kAuthToken,authToken];
        }
        
        DLog(@"Signout url:%@",url);
        
        __block ASIHTTPRequest* signout = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
        [signout setRequestMethod:@"DELETE"];
        
        [signout setCompletionBlock:^{
            //DLog(@"Signout:%@",[signout responseString]);
        }];
        
        [signout setFailedBlock:^{
           // DLog(@"Signout Error:%@",[signout error]);
        }];
        
        [signout startAsynchronous];
    }
    else {
        
        NSString* url = kDBMasterLOGOUT;
        if (authToken) {
            url = [NSString stringWithFormat:@"%@?%@=%@",kDBMasterLOGOUT,kAuthToken,authToken];
        }
        
        DLog(@"Signout url:%@",url);
        
        __block ASIHTTPRequest* signout = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
        [signout setRequestMethod:@"DELETE"];
        
        [signout setCompletionBlock:^{
            //DLog(@"Signout:%@",[signout responseString]);
        }];
        
        [signout setFailedBlock:^{
            //DLog(@"Signout Error:%@",[signout error]);
        }];
        
        [signout startAsynchronous];
    }
}

- (IBAction)login:(id)sender {
    
    NSString* Email = [email text];
    NSString* Password = [password text];
    
    if (!Email) Email = @"";
    if (!Password) Password = @"";
    
    MBProgressHUD* __weak loginHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    loginHud.labelText = @"Logging in...";
    [loginHud show:YES];
    
    [email becomeFirstResponder];
    [email resignFirstResponder];
    
    DLog(@"Login URL:%@",kDBLOGIN);
    
    ASIFormDataRequest* __weak request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kDBLOGIN]];
    
    [request setPostValue:Email forKey:kEmailKey];
    [request setPostValue:Password forKey:kPasswordKey];
    
//    [request setNumberOfTimesToRetryOnTimeout:3];
    
    [request setCompletionBlock:^{
        //DLog(@"good:cookies%@, headers:%@, string:%@", [request responseCookies], [request responseHeaders], [request responseString]);
        dispatch_async(dispatch_get_main_queue(), ^{
            if([[[request responseHeaders] objectForKey:@"Content-Type"] isEqualToString:@"application/json; charset=utf-8"])
            {
                //DLog(@"Got JSON. Response %@",[request responseStatusMessage]);
                NSDictionary* temp = [[request responseString] objectFromJSONString];
                DLog(@"JSON:%@",temp);
                if ([[temp objectForKey:kResponse] isEqualToString:kOK]) {
                    authToken = [temp objectForKey:kAuthToken];
                    [venderInfo addObject:temp];
                    if ([temp objectForKey:kVendorGroupID]&&[[temp objectForKey:kVendorGroupID] objectForKey:@"id"]) {
                        vendorGroup = [[[temp objectForKey:kVendorGroupID] objectForKey:@"id"] stringValue]; 
                    }
                    DLog(@"Response OK:%@ w/ vendorinfo:%@ and VGID:%@",authToken,venderInfo,vendorGroup);
                    
                    CIOrderViewController *masterViewController = [[CIOrderViewController alloc] initWithNibName:@"CIOrderViewController" bundle:nil];
                    masterViewController.authToken = authToken;
                    
                    //ol.title = [venderInfo objectForKey:kName];
                    masterViewController.venderInfo = [venderInfo copy];
                    
                    masterViewController.vendorGroup = vendorGroup;
                    masterViewController.managedObjectContext = self.managedObjectContext;
                    
                    [self presentViewController:masterViewController animated:YES completion:nil];
                    //[self.view addSubview:splitViewController.view];
                    //[self logout];
                    self.password.text = @"";
                }
            }
            else
            {
                DLog(@"Got JSON. Response %@, full:%@",[request responseStatusMessage], request.responseString);
                [self logout];
            }
            [loginHud hide:YES]; 
        });//main_thread
        
    }];//completion block
    
    [request setFailedBlock:^{
        //DLog(@"error:%@",[request error]);
        if (request.responseStatusCode == 0) {
            //loginHud.labelText = @"An unknown error occurred. Please try login again.";
            [loginHud hide:YES];
            
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"An unknown error occurred. Please try login again."
                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (request.responseString) {
                    DLog(@"returned:%@",request.responseString);
                    self.error.text = [[request.responseString objectFromJSONString] objectForKey:kError];
                    //                __block ASIFormDataRequest* mvrequest = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kDBMasterLOGIN]];
                    //
                    //                [mvrequest setPostValue:Email forKey:kEmailMasterKey];
                    //                [mvrequest setPostValue:Password forKey:kPasswordMasterKey];
                    //
                    //                [mvrequest setCompletionBlock:^{
                    //                    //DLog(@"good:cookies%@, headers:%@, string:%@", [request responseCookies], [request responseHeaders], [request responseString]);
                    //                    dispatch_async(dispatch_get_main_queue(), ^{
                    //                        if([[[mvrequest responseHeaders] objectForKey:@"Content-Type"] isEqualToString:@"application/json; charset=utf-8"])
                    //                        {
                    //                            //DLog(@"Got JSON. Response %@",[request responseStatusMessage]);
                    //                            NSDictionary* temp = [[mvrequest responseString] objectFromJSONString];
                    //                            DLog(@"JSON:%@",temp);
                    //                            if ([[temp objectForKey:kResponse] isEqualToString:kOK]) {
                    //                                authToken = [temp objectForKey:kAuthToken];
                    //                                //[venderInfo addObject:temp];
                    //                                masterVender = YES;
                    //
                    //                                CIOrderViewController *masterViewController = [[CIOrderViewController alloc] initWithNibName:@"CIOrderViewController" bundle:nil];
                    //                                masterViewController.authToken = authToken;
                    //                                masterViewController.masterVender = masterVender;
                    //
                    //                                //ol.title = [venderInfo objectForKey:kName];
                    //                                //masterViewController.venderInfo = [venderInfo copy];
                    //
                    //
                    //
                    //                                [self presentModalViewController:masterViewController animated:YES];
                    //                                //[self.view addSubview:splitViewController.view];
                    //                                //[self logout];
                    //                                self.password.text = @"";
                    //                            }
                    //                        }
                    //                        [loginHud hide:YES];
                    //                    });
                    //                }];
                    //
                    //                [mvrequest setFailedBlock:^{
                    //                    DLog(@"error:%@",[mvrequest error]);
                    //                    dispatch_async(dispatch_get_main_queue(), ^{
                    //                        if (mvrequest.responseString) {
                    //                            self.error.text = [[mvrequest.responseString objectFromJSONString] objectForKey:kError];                        }
                    //                        else {
                    //                            self.error.text = [[mvrequest error] description];
                    //                        }
                    //                        DLog(@"returned:%@",mvrequest.responseString);
                    [loginHud hide:YES]; 
                    //                    });
                    //                }];
                    //                
                    //                [mvrequest startAsynchronous];
                }
                else {
                    if ([[request error] code]==1||[[request error] code]==2) {
                        self.error.text = @"There seems to be an issue connecting to our servers. Please double check you have the correct connection and try again!"; 
                    }
                    else{
                        self.error.text = [[request error] description];
                    }
                    [loginHud hide:YES]; 
                }
            });
        }
    }];
    
    [request startAsynchronous];
                       

}

- (IBAction)dismissKB:(id)sender {
    [email becomeFirstResponder];
    [email resignFirstResponder];
}
@end
