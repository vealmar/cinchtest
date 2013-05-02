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
#import "CoreDataUtil.h"
#import "CIAppDelegate.h"
#import "SetupInfo.h"

@interface CIFinalCustomerInfoViewController () {
    SetupInfo *authorizedBy;
    SetupInfo *shipFlag;
    BOOL contactFirst;
    NSManagedObjectContext *context;
}

@end

@implementation CIFinalCustomerInfoViewController
@synthesize shippingNotes;
@synthesize Notes;
@synthesize Authorizer;
@synthesize scroll;
@synthesize delegate;
@synthesize tableData;
@synthesize filteredtableData;
@synthesize contactBeforeShipping;

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

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSDictionary *subs = [NSDictionary dictionaryWithObject:@"authorizedBy" forKey:@"ITEMNAME"];
    
    CIAppDelegate *appDelegate = (CIAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectModel *model = appDelegate.managedObjectModel;
    NSFetchRequest *req = [model fetchRequestFromTemplateWithName:@"getSetupItem" substitutionVariables:subs];
    NSError *error = nil;
    
    context = appDelegate.managedObjectContext;
    NSArray *results = [context executeFetchRequest:req error:&error];
    if (!error && results != nil && [results count] > 0) {
        authorizedBy = [results objectAtIndex:0];
        Authorizer.text = authorizedBy.value;
    }
    
    subs = [NSDictionary dictionaryWithObject:@"ship_flag" forKey:@"ITEMNAME"];
    req = [model fetchRequestFromTemplateWithName:@"getSetupItem" substitutionVariables:subs];
    results = [context executeFetchRequest:req error:&error];
    if (!error && results != nil && [results count] > 0) {
        shipFlag = [results objectAtIndex:0];
        contactFirst = [shipFlag.value isEqualToString:@"YES"];
        [contactBeforeShipping updateCheckBox:contactFirst];
    }
}

-(void) setCustomerData:(NSArray *)customerData
{
    DLog(@"Load customer data");
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)submit:(id)sender {
    if (!IS_EMPTY_STRING(self.Authorizer.text)) {
        
        if (![self.Authorizer.text isEqualToString:authorizedBy.value]) {
            if (authorizedBy != nil) {
                authorizedBy.value = self.Authorizer.text;
            } else {
                SetupInfo *setup = (SetupInfo *)[[CoreDataUtil sharedManager] createNewEntity:@"SetupInfo"];
                setup.item = @"authorizedBy";
                setup.value = self.Authorizer.text;
            }
            
            NSError *error;
            [context save:&error];
        }
        
        
        if (shipFlag == nil || contactBeforeShipping.isChecked != contactFirst) {
            if (shipFlag != nil) {
                shipFlag.value = contactBeforeShipping.isChecked ? @"YES" : @"NO";
            } else {
                SetupInfo *setup = (SetupInfo *)[[CoreDataUtil sharedManager] createNewEntity:@"SetupInfo"];
                setup.item = @"ship_flag";
                setup.value = contactBeforeShipping.isChecked ? @"YES" : @"NO";
            }
            
            NSError *error;
            [context save:&error];
        }

        if (self.delegate) {
            NSMutableDictionary* dict = [[self.delegate getCustomerInfo] mutableCopy];
            DLog(@"customer data:%@",dict);
            if (dict == nil) {
                return;
            }
            
            [dict setObject:self.shippingNotes.text forKey:kShipNotes];
            [dict setObject:self.Notes.text forKey:kNotes ];
            [dict setObject:self.Authorizer.text forKey:kAuthorizedBy];
            
            NSString *isChecked = self.contactBeforeShipping.isChecked ? @"YES" : @"NO";
            [dict setObject:isChecked forKey:kShipFlag];
            DLog(@"info to send:%@",dict);
            [self.delegate setCustomerInfo:[dict copy]];
            [self.delegate submit:nil];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }
    else{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Required Fields Missing!" message:@"Please finish filling out all required fields before submitting!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

////method to move the view up/down whenever the keyboard is shown/dismissed
//-(void)setViewMovedUp:(BOOL)movedUp
//{
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
//    
//    CGRect rect = self.scroll.frame;
//    if (movedUp)
//    {
//        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
//        // 2. increase the size of the view so that the area behind the keyboard is covered up.
//        rect.origin.y += kOFFSET_FOR_KEYBOARD+40;//was -
//        //rect.size.height += kOFFSET_FOR_KEYBOARD;
//    }
//    else
//    {
//        // revert back to the normal state.
//        rect.origin.y =0;//-= (kOFFSET_FOR_KEYBOARD);//was +
//        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
//    }
//    self.scroll.contentOffset = rect.origin;
//    
//    [UIView commitAnimations];
//}

//-(void)setViewMovedUpDouble:(BOOL)movedUp
//{
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationDuration:0.5]; // if you want to slide up the view
//    
//    CGRect rect = self.scroll.frame;
//    if (movedUp)
//    {
//        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
//        // 2. increase the size of the view so that the area behind the keyboard is covered up.
//        rect.origin.y += (kOFFSET_FOR_KEYBOARD+40)*2;//was -
//        //rect.size.height += kOFFSET_FOR_KEYBOARD;
//    }
//    else
//    {
//        // revert back to the normal state.
//        rect.origin.y = 0;//-= (kOFFSET_FOR_KEYBOARD-7);//was +
//        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
//    }
//    self.scroll.contentOffset = rect.origin;
//    
//    [UIView commitAnimations];
//}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
//    [textView resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
}

//-(void)textViewDidBeginEditing:(UITextView *)sender
//{
//    if ([sender isEqual:self.Notes])
//    {
//        //move the main view, so that the keyboard does not hide it.
//        if  (self.view.frame.origin.y >= 0)
//        {
//            [self setViewMovedUp:YES];
//        }
//    }
//    if([sender isEqual:self.shippingNotes])
//    {
//        //move the main view, so that the keyboard does not hide it.
//        if  (self.view.frame.origin.y >= 0)
//        {
//            [self setViewMovedUpDouble:YES];
//        }
//    }
//}

//-(void)textViewDidEndEditing:(UITextView *)sender
//{
//    if ([sender isEqual:self.Notes])
//    {
//        //move the main view, so that the keyboard does not hide it.
//        if  (self.view.frame.origin.y >= 0)
//        {
//            [self setViewMovedUp:NO];
//        }
//    }
//    if([sender isEqual:self.shippingNotes])
//    {
//        //move the main view, so that the keyboard does not hide it.
//        if  (self.view.frame.origin.y >= 0)
//        {
//            [self setViewMovedUpDouble:NO];
//        }
//    }
//}

//- (void)keyboardWillShow:(NSNotification *)notif
//{
//    //keyboard will be shown now. depending for which textfield is active, move up or move down the view appropriately
//    
//    if ([self.Notes isFirstResponder] && self.view.frame.origin.y >= 0)
//    {
//        [self setViewMovedUp:YES];
//    }
//    else if([self.shippingNotes isFirstResponder]&&self.view.frame.origin.y >=0)
//    {
//        [self setViewMovedUpDouble:YES];
//    }
//    else if (![self.shippingNotes isFirstResponder]&&![self.Notes isFirstResponder] && self.view.frame.origin.y < 0)
//    {
//        [self setViewMovedUp:NO];
//    }
//}

@end
