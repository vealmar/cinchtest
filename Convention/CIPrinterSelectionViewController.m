//
//  CIPrinterSelectionViewController.m
//  Convention
//
//  Created by Kerry Sanders on 12/8/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CIPrinterSelectionViewController.h"

@interface CIPrinterSelectionViewController ()

@end

@implementation CIPrinterSelectionViewController
{
    NSInteger selectedPrinter;
}
@synthesize availablePrinters = _availablePrinters;
@synthesize printerPicker = _printerPicker;
@synthesize btnDone;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
//    [self.navigationController setTitle:@"Available Printers"];
    selectedPrinter = -1;
    self.btnDone.enabled = NO;
    self.contentSizeForViewInPopover = self.view.frame.size;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_availablePrinters count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_availablePrinters objectAtIndex:row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
//    if (self.delegate) {
//        [self.delegate setSelectedPrinter:[_availablePrinters objectAtIndex:row]];
//    }
    selectedPrinter = row;
    self.btnDone.enabled = YES;
}

- (IBAction)selectPrinter:(id)sender {
    if (self.delegate) {
        [self.delegate setSelectedPrinter:[_availablePrinters objectAtIndex:selectedPrinter]];
    }
}
@end