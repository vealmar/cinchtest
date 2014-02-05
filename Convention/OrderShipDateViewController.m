//
//  OrderShipDateViewController.m
//  Convention
//
//  Created by septerr on 2/5/14.
//  Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import "OrderShipDateViewController.h"

@interface OrderShipDateViewController ()
@property(copy, nonatomic) void(^doneBlock)(NSDate *);
@property(copy, nonatomic) void(^cancelBlock)();
@property(weak, nonatomic) IBOutlet CKCalendarView *calendar;
@end

@implementation OrderShipDateViewController
- (id)initWithDelegate:(id <OrderShipDateViewControllerDelegate>)delegate {
    self = [super initWithNibName:@"OrderShipDateViewController" bundle:nil];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.calendar.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.calendar selectDate:self.selectedDate makeVisible:YES];
}


- (void)calendar:(CKCalendarView *)calendar didSelectDate:(NSDate *)date {
    self.selectedDate = date;
}

- (void)calendar:(CKCalendarView *)calendar didDeselectDate:(NSDate *)date {
    self.selectedDate = nil;
}

- (IBAction)cancelTouched:(id)sender {
    [self.delegate orderShipDateViewControllerCancelled];
}

- (IBAction)saveTouched:(id)sender {
    [self.delegate shipDateSelected:self.selectedDate];
}


@end
