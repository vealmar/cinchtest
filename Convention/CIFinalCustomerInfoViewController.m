//
//  CIFinalCustomerInfoViewController.m
//  Convention
//
//  Created by Matthew Clark on 4/25/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CIFinalCustomerInfoViewController.h"
#import "Macros.h"
#import "config.h"

@interface CIFinalCustomerInfoViewController ()

@end

@implementation CIFinalCustomerInfoViewController
@synthesize shippingNotes;
@synthesize Notes;
@synthesize Authorizer;
@synthesize scroll;
@synthesize sendEmail;
@synthesize email;
@synthesize delegate;
@synthesize tableData;
@synthesize filteredtableData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
//        self.tableData = [NSArray array];
        //DLog(@"CI init'd");
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[self.scroll addSubview:self.custView];
    //for testing
    //WARNING!!!
    //self.Authorizer.text = @"testing";
    // Do any additional setup after loading the view from its nib.
}

-(void) setCustomerData:(NSArray *)customerData
{
    DLog(@"Load customer data");
}

- (IBAction)back:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
    DLog(@"see me?");
//    if (self.delegate) {
//        [self.delegate Cancel:nil];
//    }
}

- (void)viewDidUnload
{
    [self setShippingNotes:nil];
    [self setNotes:nil];
    [self setAuthorizer:nil];
    [self setScroll:nil];
    [self setSendEmail:nil];
    [self setEmail:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (IBAction)submit:(id)sender {
    if (!IS_EMPTY_STRING(self.Authorizer.text)) {
        if (self.delegate) {
            NSMutableDictionary* dict = [[self.delegate getCustomerInfo] mutableCopy];
            DLog(@"customer data:%@",dict);
            if (dict == nil) {
                return;
            }
            
            NSString* semail = @"";
            NSString* sdEmail = @"0";
            if (self.sendEmail.on) {
                if (IS_POPULATED_STRING(self.email.text)) {
                    BOOL stricterFilter = YES; 
                    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
                    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
                    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
                    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
                    // check that our NSRange object is not equal to range of NSNotFound
                    if (![emailTest evaluateWithObject:self.email.text]) {
                        //if so let the user know and cancel
                        [[[UIAlertView alloc] initWithTitle:@"Oops!" message:@"It looks like your email isn't a valid email! Please correct it and try again!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                        
                        return;
                    }else{
                        semail = self.email.text;
                        sdEmail = @"1";
                    }
                }
                else {
                    UIAlertView* alert =[[UIAlertView alloc] initWithTitle:@"Missing Receipt Email!" message:@"You have selected to send an email receipt, but not provided an email." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [alert show];
                    return;
                }
            }
            [dict setObject:self.shippingNotes.text forKey:kShipNotes];
            [dict setObject:self.Notes.text forKey:kNotes ]; 
            [dict setObject:self.Authorizer.text forKey:kAuthorizedBy];
            [dict setObject:sdEmail forKey:kSendEmail];  
            [dict setObject:semail forKey:kEmail];
            DLog(@"info to send:%@",dict);
            [self.delegate setCustomerInfo:[dict copy]];
            [self.delegate submit:nil];
            [self dismissModalViewControllerAnimated:NO];
        }
    }
    else{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Required Fields Missing!" message:@"Please finish filling out all required fields before submitting!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
    
    CGRect rect = self.scroll.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += kOFFSET_FOR_KEYBOARD+40;//was -
        //rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y =0;//-= (kOFFSET_FOR_KEYBOARD);//was +
        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.scroll.contentOffset = rect.origin;
    
    [UIView commitAnimations];
}
-(void)setViewMovedUpDouble:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
    
    CGRect rect = self.scroll.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard 
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += (kOFFSET_FOR_KEYBOARD+40)*2;//was -
        //rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y = 0;//-= (kOFFSET_FOR_KEYBOARD-7);//was +
        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.scroll.contentOffset = rect.origin;
    
    [UIView commitAnimations];
}
-(void)textViewDidBeginEditing:(UITextView *)sender
{
    if ([sender isEqual:self.Notes])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUp:YES];
        }
    }
    if([sender isEqual:self.shippingNotes])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUpDouble:YES];
        }
    }
}
-(void)textViewDidEndEditing:(UITextView *)sender
{
    if ([sender isEqual:self.Notes])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUp:NO];
        }
    }
    if([sender isEqual:self.shippingNotes])
    {
        //move the main view, so that the keyboard does not hide it.
        if  (self.view.frame.origin.y >= 0)
        {
            [self setViewMovedUpDouble:NO];
        }
    }
}



- (void)keyboardWillShow:(NSNotification *)notif
{
    //keyboard will be shown now. depending for which textfield is active, move up or move down the view appropriately
    
    if ([self.Notes isFirstResponder] && self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if([self.shippingNotes isFirstResponder]&&self.view.frame.origin.y >=0)
    {
        [self setViewMovedUpDouble:YES];
    }
    else if (![self.shippingNotes isFirstResponder]&&![self.Notes isFirstResponder] && self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    //for testing
//    self.Authorizer.text = @"testing";
    
    if (self.delegate) {
        NSDictionary* dict = [self.delegate getCustomerInfo];
        DLog(@"trying to load email:%@",dict);
        if ([dict objectForKey:kEmail]&&![[dict objectForKey:kEmail] isKindOfClass:[NSNull class]]) {
            self.email.text = [dict objectForKey:kEmail];
        }else {
            self.sendEmail.on = NO;
        }
    }else {
        self.sendEmail.on = NO;
    }
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification object:self.view.window]; 
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
}

@end
