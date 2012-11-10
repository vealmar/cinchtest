//
//  CIPrintViewController.m
//  Convention
//
//  Created by Matthew Clark on 8/1/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CIPrintViewController.h"
#import "config.h"
#import "MBProgressHUD.h"
#import "ASIFormDataRequest.h"
#import "JSONKit.h"
#import "SettingsManager.h"

@interface CIPrintViewController ()

@end

@implementation CIPrintViewController
@synthesize isle;
@synthesize booth;
@synthesize notesLbl;
@synthesize notes;
@synthesize PrintHeader;
@synthesize lblorder;
@synthesize orderID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setPrintHeader:nil];
    [self setIsle:nil];
    [self setNotes:nil];
    [self setNotesLbl:nil];
    [self setBooth:nil];
    [self setLblorder:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)viewWillAppear:(BOOL)animated{
    
    self.PrintHeader.font = [UIFont fontWithName:kFontName size:32.f];
    self.PrintHeader.textColor = [UIColor whiteColor];
    self.notesLbl.font = [UIFont fontWithName:kFontName size:16.f];
    self.notesLbl.textColor = [UIColor whiteColor];
    
    self.isle.font = [UIFont fontWithName:kFontName size:24.f];
    self.booth.font = [UIFont fontWithName:kFontName size:24.f];
    self.lblorder.text = self.orderID;
}

- (IBAction)cancel:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)submit:(id)sender {
    __block MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Logging in...";
    [hud show:YES];
    
//    [isle becomeFirstResponder];
//    [isle resignFirstResponder];
    
    __block ASIFormDataRequest* request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kDBREPORTPRINTS]];
    
    [request setPostValue:self.isle.text forKey:kReportPrintIsle];
    [request setPostValue:self.booth.text forKey:kReportPrintBooth];
    [request setPostValue:self.notes.text forKey:kReportPrintNotes];
    [request setPostValue:self.orderID forKey:kReportPrintOrderId];
    
    [request setCompletionBlock:^{
        //DLog(@"good:cookies%@, headers:%@, string:%@", [request responseCookies], [request responseHeaders], [request responseString]);
        dispatch_async(dispatch_get_main_queue(), ^{
            if([[[request responseHeaders] objectForKey:@"Content-Type"] isEqualToString:@"application/json; charset=utf-8"])
            {
                //DLog(@"Got JSON. Response %@",[request responseStatusMessage]);
                NSDictionary* temp = [[request responseString] objectFromJSONString];
                DLog(@"JSON:%@",temp);
                if ([temp objectForKey:@"created_at"]) {
                    DLog(@"good stuff... look up^");
                    [hud hide:NO];
                    [self dismissModalViewControllerAnimated:YES];
                    return;
                }
            }
            else
            {
                DLog(@"got error response:%@",request.responseString);
                [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Something very bad happened... you should probably tell someone >.>" delegate:self cancelButtonTitle:@"I'll go find someone" otherButtonTitles: nil] show];
            }
            [hud hide:YES];
        });//main_thread
        
    }];//completion block
    
    [request setFailedBlock:^{
        DLog(@"error:%@",[request error]);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (request.responseString) {
                DLog(@"ERROR:%@",[[request.responseString objectFromJSONString] objectForKey:kError]);
                [hud hide:YES]; 
            }
            else {
                if ([[request error] code]==1) {
                    DLog(@"There seems to be an issue connecting to our servers. Please double check you have an internet connection and try again!");
                }
                else{
                    DLog(@"srsly error:%@",[[request error] description]);
                }
                [hud hide:YES]; 
            }
            DLog(@"returned:%@",request.responseString);
        });
    }];
    
    [request startAsynchronous];
}
@end
