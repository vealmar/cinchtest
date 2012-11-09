//
//  CICalendarViewController.m
//  Convention
//
//  Created by Matthew Clark on 8/17/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CICalendarViewController.h"

@interface CICalendarViewController (){
}

@end

@implementation CICalendarViewController
@synthesize placeholder;
@synthesize calendarView,doneTouched,cancelTouched,afterLoad;
@synthesize startDate;
@synthesize calendar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        
        self.modalPresentationStyle = UIModalPresentationFormSheet;
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
    [self setCalendarView:nil];
    [self setPlaceholder:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated{
    calendarView = [[DDCalendarView alloc] initWithFrame:self.placeholder.bounds fontName:@"AmericanTypewriter" delegate:self];
    [self.placeholder addSubview:calendarView];
    calendarView.delegate = self;
    
    if (afterLoad) {
        afterLoad();
    }
    
    if (!startDate) {
        startDate = [NSDate date];
    }
    
    NSDateComponents* comps = [calendar components:(NSMonthCalendarUnit|NSYearCalendarUnit) fromDate:startDate];
    [calendarView updateCalendarForMonth:[comps month] forYear:[comps year]];
//    NSLog(@"avalible = %@",calendarView.avalibleDates);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (IBAction)Cancel:(id)sender {
    if (cancelTouched) {
        cancelTouched();
    }
}

- (IBAction)Done:(id)sender {
    if (doneTouched) {
        doneTouched(calendarView.selectedDates);
    }
}

-(void)dayButtonPressed:(DayButton *)button{
    //don't really need this...
}

-(void)setStartDate:(NSDate *)sd{
    NSDateComponents* comps = [calendar components:(NSMonthCalendarUnit|NSYearCalendarUnit) fromDate:sd];
    [calendarView updateCalendarForMonth:[comps month] forYear:[comps year]];
    startDate = sd;
}

@end
