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
#import "JSONKit.h"
#import "SettingsManager.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"

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

-(void)viewDidDisappear:(BOOL)animated
{
    [self setPrintHeader:nil];
    [self setIsle:nil];
    [self setNotes:nil];
    [self setNotesLbl:nil];
    [self setBooth:nil];
    [self setLblorder:nil];
    [super viewDidDisappear:animated];
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
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)submit:(id)sender {
    MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Printing ...";
    [hud show:YES];

    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.isle.text, kReportPrintIsle,
                            self.booth.text, kReportPrintBooth, self.notes.text, kReportPrintNotes,
                            self.orderID, kReportPrintOrderId, nil];
    
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kDBREPORTPRINTS]];
    [client setParameterEncoding:AFJSONParameterEncoding];
    NSMutableURLRequest *request = [client requestWithMethod:@"PUT" path:nil parameters:params];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        DLog(@"JSON: %@", JSON);
        NSString *status = [JSON valueForKey:@"created_at"];
        DLog(@"status = %@", status);
        [hud hide:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

        NSString *errorMsg = [NSString stringWithFormat:@"There was an error printing the order. %@", error.localizedDescription];
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
    }];
    
    [operation start];
    
    
//    ASIFormDataRequest* __weak request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kDBREPORTPRINTS]];
//    
//    [request setPostValue:self.isle.text forKey:kReportPrintIsle];
//    [request setPostValue:self.booth.text forKey:kReportPrintBooth];
//    [request setPostValue:self.notes.text forKey:kReportPrintNotes];
//    [request setPostValue:self.orderID forKey:kReportPrintOrderId];
//    
//    [request setCompletionBlock:^{
//        //DLog(@"good:cookies%@, headers:%@, string:%@", [request responseCookies], [request responseHeaders], [request responseString]);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if([[[request responseHeaders] objectForKey:@"Content-Type"] isEqualToString:@"application/json; charset=utf-8"])
//            {
//                //DLog(@"Got JSON. Response %@",[request responseStatusMessage]);
//                NSDictionary* temp = [[request responseString] objectFromJSONString];
//                DLog(@"JSON:%@",temp);
//                if ([temp objectForKey:@"created_at"]) {
//                    DLog(@"good stuff... look up^");
//                    [hud hide:NO];
//                    [self dismissViewControllerAnimated:YES completion:nil];
//                    return;
//                }
//            }
//            else
//            {
//                DLog(@"got error response:%@",request.responseString);
//                [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Something very bad happened... you should probably tell someone >.>" delegate:self cancelButtonTitle:@"I'll go find someone" otherButtonTitles: nil] show];
//            }
//            [hud hide:YES];
//        });//main_thread
//        
//    }];//completion block
//    
//    [request setFailedBlock:^{
//        //DLog(@"error:%@",[request error]);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (request.responseString) {
//                DLog(@"ERROR:%@",[[request.responseString objectFromJSONString] objectForKey:kError]);
//                [hud hide:YES];
//            }
//            else {
//                if ([[request error] code]==1) {
//                    DLog(@"There seems to be an issue connecting to our servers. Please double check you have an internet connection and try again!");
//                }
//                else{
//                    DLog(@"srsly error:%@",[[request error] description]);
//                }
//                [hud hide:YES];
//            }
//            DLog(@"returned:%@",request.responseString);
//        });
//    }];
//    
//    [request startAsynchronous];
}
@end
