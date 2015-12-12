//
//  DDCalendarView.h
//  DDCalendarView
//
//  Created by Damian Dawber on 28/12/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DayButton.h"

@protocol DDCalendarViewDelegate <NSObject>
- (void)dayButtonPressed:(DayButton *)button;

@optional
- (void)prevButtonPressed;
- (void)nextButtonPressed;

@end

@interface DDCalendarView : UIView <DayButtonDelegate> {
	NSString *calendarFontName;
	UILabel *monthLabel;
	NSMutableArray *dayButtons;
	NSCalendar *calendar;
	float calendarWidth;
	float calendarHeight;
	float cellWidth;
	float cellHeight;
	int currentMonth;
	int currentYear;
}

@property(nonatomic, assign) id <DDCalendarViewDelegate> delegate;
@property(nonatomic, strong) NSMutableArray* selectedDates;
@property(nonatomic, strong) NSMutableArray* avalibleDates;

- (id)initWithFrame:(CGRect)frame fontName:(NSString *)fontName delegate:(id)theDelegate;
- (void)updateCalendarForMonth:(int)month forYear:(int)year;
- (void)drawDayButtons;
- (void)prevBtnPressed:(id)sender;
- (void)nextBtnPressed:(id)sender;

- (void)openDates:(NSArray*)dates;

@end
