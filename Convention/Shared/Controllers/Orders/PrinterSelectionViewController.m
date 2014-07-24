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
{
    NSInteger selectedPrinter;
    UIBarButtonItem *btnDone;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if (self.availablePrinters.count > 0) {
            selectedPrinter = 0;//by default select first printer
        }
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
//    if(self.availablePrinters.count > 0){
//        selectedPrinter = 0;//by default select first printer
//    }else
    selectedPrinter = -1; //the pop is called only when printers are available, so this should never happen
    self.contentSizeForViewInPopover = self.view.frame.size;
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    btnDone = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(selectPrinter:)];
    btnDone.enabled = self.availablePrinters.count > 0;
    NSArray *items = [NSArray arrayWithObjects:flex, btnDone, nil];
    self.navigationController.toolbarHidden = NO;
    self.toolbarItems = items;
}


-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_availablePrinters count];
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_availablePrinters objectAtIndex:(NSUInteger) row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    selectedPrinter = row;
}


-(IBAction)selectPrinter:(id)sender {
    if (self.delegate && selectedPrinter >= 0) {
        [self.delegate setSelectedPrinter:[_availablePrinters objectAtIndex:(NSUInteger) selectedPrinter]];
    }
}

@end
