//
//  PrinterSelectionViewController.m
//  Convention
//
//  Created by Kerry Sanders on 12/9/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "PrinterSelectionViewController.h"

@interface PrinterSelectionViewController ()

@end

@implementation PrinterSelectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    //    [self.navigationController setTitle:@"Available Printers"];
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
    if (self.delegate) {
        [self.delegate setSelectedPrinter:[_availablePrinters objectAtIndex:row]];
    }
}
@end
