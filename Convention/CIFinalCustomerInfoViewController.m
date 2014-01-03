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
#import "SettingsManager.h"
#import "Order.h"

@interface CIFinalCustomerInfoViewController () {
    SetupInfo *authorizedBy;
    SetupInfo *shipFlag;
    NSManagedObjectContext *context;
    CGRect originalBounds;
    __weak IBOutlet UILabel *contactBeforeShippingLabel;
    __weak IBOutlet MICheckBox *contactBeforeShipping;
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    context = ((CIAppDelegate *) [[UIApplication sharedApplication] delegate]).managedObjectContext;
    [self defaultAuthorizedbyText];
    [self defaultShippingFields];
    self.Notes.text = self.order && self.order.notes ? self.order.notes : @"";
    self.shippingNotes.text = self.order && self.order.ship_notes ? self.order.ship_notes : @"";
}

- (void)defaultAuthorizedbyText {
    NSDictionary *subs = [NSDictionary dictionaryWithObject:@"authorizedBy" forKey:@"ITEMNAME"];
    CIAppDelegate *appDelegate = (CIAppDelegate *) [[UIApplication sharedApplication] delegate];
    NSManagedObjectModel *model = appDelegate.managedObjectModel;
    NSFetchRequest *req = [model fetchRequestFromTemplateWithName:@"getSetupItem" substitutionVariables:subs];
    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:req error:&error];
    if (!error && results != nil && [results count] > 0) {
        authorizedBy = [results objectAtIndex:0];
    }
    Authorizer.text = self.order && self.order.authorized ? self.order.authorized
            : authorizedBy ? authorizedBy.value : @"";
}

- (void)defaultShippingFields {
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        contactBeforeShippingLabel.hidden = YES;
        contactBeforeShipping.hidden = YES;
    } else {
        NSDictionary *subs = [NSDictionary dictionaryWithObject:@"ship_flag" forKey:@"ITEMNAME"];
        CIAppDelegate *appDelegate = (CIAppDelegate *) [[UIApplication sharedApplication] delegate];
        NSManagedObjectModel *model = appDelegate.managedObjectModel;
        NSFetchRequest *req = [model fetchRequestFromTemplateWithName:@"getSetupItem" substitutionVariables:subs];
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:req error:&error];
        if (!error && results != nil && [results count] > 0) {
            shipFlag = [results objectAtIndex:0];
        }
        [contactBeforeShipping updateCheckBox:self.order && [self.order.ship_flag boolValue] ? YES
                : shipFlag ? [shipFlag.value isEqualToString:@"YES"] : NO];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    originalBounds = self.view.bounds;
}

- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)submit:(id)sender {
    if (!IS_EMPTY_STRING(self.Authorizer.text)) {
        if (![self.Authorizer.text isEqualToString:authorizedBy.value]) {//SG: If the value specified for Authorized By last time is not same as the value specified this time, update the value in setupinfo.
            if (authorizedBy != nil) {
                authorizedBy.value = self.Authorizer.text;
            } else {
                SetupInfo *setup = (SetupInfo *) [[CoreDataUtil sharedManager] createNewEntity:@"SetupInfo"];
                setup.item = @"authorizedBy";
                setup.value = self.Authorizer.text;
            }
            NSError *error;
            [context save:&error];
        }

        if (![kShowCorp isEqualToString:kPigglyWiggly]) {//Farris
            NSError *error;
            if (shipFlag == nil) {   //SG: If the value specified for Contact Before Shipping last time is not same as the value specified this time, update the value in setupinfo.
                SetupInfo *setup = (SetupInfo *) [[CoreDataUtil sharedManager] createNewEntity:@"SetupInfo"];
                setup.item = @"ship_flag";
                setup.value = contactBeforeShipping.isChecked ? @"YES" : @"NO";
                [context save:&error];
            } else if ((contactBeforeShipping.isChecked && [shipFlag.value isEqualToString:@"NO"])
                    || (!contactBeforeShipping.isChecked && [shipFlag.value isEqualToString:@"YES"])) {
                shipFlag.value = contactBeforeShipping.isChecked ? @"YES" : @"NO";
                [context save:&error];
            }
        }

        if (self.delegate) {
            NSMutableDictionary *dict = [[self.delegate getCustomerInfo] mutableCopy];
            if (dict == nil) {
                return;
            }

            [dict setObject:self.shippingNotes.text forKey:kShipNotes];
            [dict setObject:self.Notes.text forKey:kNotes ];
            [dict setObject:self.Authorizer.text forKey:kAuthorizedBy];

            if (![kShowCorp isEqualToString:kPigglyWiggly]) {
                [dict setObject:(contactBeforeShipping.isChecked ? @"true" : @"false") forKey:kShipFlag];
            }
            [self.delegate setAuthorizedByInfo:[dict copy]];
            [self.delegate submit:nil];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authorized By Required!" message:@"Please fill out Authorized By field before submitting!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)setViewMovedUp:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view

    CGRect rect = self.view.bounds;
    if (movedUp) {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += kOFFSET_FOR_KEYBOARD + 40;
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

- (void)setViewMovedUpDouble:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view

    CGRect rect = self.view.bounds;
    if (movedUp) {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y += kOFFSET_FOR_KEYBOARD + 70;//was -
        //rect.size.height += kOFFSET_FOR_KEYBOARD;
        self.view.bounds = rect;
    }
    else {
        // revert back to the normal state.
        //rect.origin.y = 0;//-= (kOFFSET_FOR_KEYBOARD-7);//was +
        //rect.size.height -= kOFFSET_FOR_KEYBOARD;
        self.view.bounds = originalBounds;
    }

    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
//    [textView resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
}

- (void)textViewDidBeginEditing:(UITextView *)sender {
    if ([sender isEqual:self.shippingNotes]) {
        //move the main view, so that the keyboard does not hide it.
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUp:YES];
        }
    }
    if ([sender isEqual:self.Notes]) {
        //move the main view, so that the keyboard does not hide it.
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUpDouble:YES];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)sender {
    if ([sender isEqual:self.shippingNotes]) {
        //move the main view, so that the keyboard does not hide it.
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUp:NO];
        }
    }
    if ([sender isEqual:self.Notes]) {
        //move the main view, so that the keyboard does not hide it.
        if (self.view.frame.origin.y >= 0) {
            [self setViewMovedUpDouble:NO];
        }
    }
}

@end
