//
//  CICalendarViewController.h
//  Convention
//
//  Created by Matthew Clark on 8/17/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDCalendarView.h"

@interface CICalendarViewController : UIViewController <DDCalendarViewDelegate>
@property (strong, nonatomic) IBOutlet DDCalendarView *calendarView;
@property (copy,nonatomic) void(^doneTouched)(NSArray*);
@property (copy,nonatomic) void(^cancelTouched)();
@property (copy,nonatomic) void(^afterLoad)();
@property (unsafe_unretained, nonatomic) IBOutlet UIView *placeholder;
@property (nonatomic,strong)NSDate* startDate;
@property (nonatomic,strong)NSCalendar* calendar;
- (IBAction)Cancel:(id)sender;
- (IBAction)Done:(id)sender;

@end
