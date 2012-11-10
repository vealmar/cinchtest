//
//  DDCalendarView.m
//  DDCalendarView
//
//  Created by Damian Dawber on 28/12/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DDCalendarView.h"

@implementation DDCalendarView
@synthesize delegate,selectedDates,avalibleDates;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
	if (self) {
        
		//Initialise vars
        calendarFontName = @"AmericanTypewriter";
		calendarWidth = frame.size.width;
		calendarHeight = frame.size.height;
		cellWidth = frame.size.width / 7.0f;
		cellHeight = frame.size.height / 8.0f;
		
		//View properties
		UIColor *bgPatternImage = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"square-paper.png"]];
		self.backgroundColor = bgPatternImage;
		
		//Set up the calendar header
		UIButton *prevBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		[prevBtn setImage:[UIImage imageNamed:@"left-arrow.png"] forState:UIControlStateNormal];
		prevBtn.frame = CGRectMake(0, 0, cellWidth, cellHeight);
		[prevBtn addTarget:self action:@selector(prevBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
		
		UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		[nextBtn setImage:[UIImage imageNamed:@"right-arrow.png"] forState:UIControlStateNormal];
		nextBtn.frame = CGRectMake(calendarWidth - cellWidth, 0, cellWidth, cellHeight);
		[nextBtn addTarget:self action:@selector(nextBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
		
		CGRect monthLabelFrame = CGRectMake(cellWidth, 0, calendarWidth - 2*cellWidth, cellHeight);
		monthLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
		monthLabel.font = [UIFont fontWithName:calendarFontName size:24];
		monthLabel.textAlignment = NSTextAlignmentCenter;
		monthLabel.backgroundColor = [UIColor clearColor];
		monthLabel.textColor = [UIColor blackColor];
		
		//Add the calendar header to view
		[self addSubview: prevBtn];
		[self addSubview: nextBtn];
		[self addSubview: monthLabel];
		
		//Add the day labels to the view
		char *days[7] = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
		for(int i = 0; i < 7; i++) {
			CGRect dayLabelFrame = CGRectMake(i*cellWidth, cellHeight, cellWidth, cellHeight);
			UILabel *dayLabel = [[UILabel alloc] initWithFrame:dayLabelFrame];
			dayLabel.text = [NSString stringWithFormat:@"%s", days[i]];
			dayLabel.textAlignment = NSTextAlignmentCenter;
			dayLabel.backgroundColor = [UIColor clearColor];
			dayLabel.font = [UIFont fontWithName:calendarFontName size:22];
			dayLabel.textColor = [UIColor darkGrayColor];
			
			[self addSubview:dayLabel];
		}
		
		[self drawDayButtons];
		
		//Set the current month and year and update the calendar
		calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		
		NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
		NSDateComponents *dateParts = [calendar components:unitFlags fromDate:[NSDate date]];
		currentMonth = [dateParts month];
		currentYear = [dateParts year];
		
		[self updateCalendarForMonth:currentMonth forYear:currentYear];
		
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame fontName:(NSString *)fontName delegate:(id)theDelegate {
    self = [super initWithFrame:frame];
	if (self) {
		self.delegate = theDelegate;
		
        
		//Initialise vars
        calendarFontName = fontName;
		calendarWidth = frame.size.width;
		calendarHeight = frame.size.height;
		cellWidth = frame.size.width / 7.0f;
		cellHeight = frame.size.height / 8.0f;
		
		//View properties
		UIColor *bgPatternImage = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"square-paper.png"]];
		self.backgroundColor = bgPatternImage;
		
		//Set up the calendar header
		UIButton *prevBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		[prevBtn setImage:[UIImage imageNamed:@"left-arrow.png"] forState:UIControlStateNormal];
		prevBtn.frame = CGRectMake(0, 0, cellWidth, cellHeight);
		[prevBtn addTarget:self action:@selector(prevBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
		
		UIButton *nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
		[nextBtn setImage:[UIImage imageNamed:@"right-arrow.png"] forState:UIControlStateNormal];
		nextBtn.frame = CGRectMake(calendarWidth - cellWidth, 0, cellWidth, cellHeight);
		[nextBtn addTarget:self action:@selector(nextBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
		
		CGRect monthLabelFrame = CGRectMake(cellWidth, 0, calendarWidth - 2*cellWidth, cellHeight);
		monthLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
		monthLabel.font = [UIFont fontWithName:calendarFontName size:18];
		monthLabel.textAlignment = NSTextAlignmentCenter;
		monthLabel.backgroundColor = [UIColor clearColor];
		monthLabel.textColor = [UIColor blackColor];
		
		//Add the calendar header to view		
		[self addSubview: prevBtn];
		[self addSubview: nextBtn];
		[self addSubview: monthLabel];
		
		//Add the day labels to the view
		char *days[7] = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
		for(int i = 0; i < 7; i++) {
			CGRect dayLabelFrame = CGRectMake(i*cellWidth, cellHeight, cellWidth, cellHeight);
			UILabel *dayLabel = [[UILabel alloc] initWithFrame:dayLabelFrame];
			dayLabel.text = [NSString stringWithFormat:@"%s", days[i]];
			dayLabel.textAlignment = NSTextAlignmentCenter;
			dayLabel.backgroundColor = [UIColor clearColor];
			dayLabel.font = [UIFont fontWithName:calendarFontName size:22];
			dayLabel.textColor = [UIColor darkGrayColor];
			
			[self addSubview:dayLabel];
		}
		
		[self drawDayButtons];
		
		//Set the current month and year and update the calendar
		calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		
		NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
		NSDateComponents *dateParts = [calendar components:unitFlags fromDate:[NSDate date]];
		currentMonth = [dateParts month];
		currentYear = [dateParts year];
		
		[self updateCalendarForMonth:currentMonth forYear:currentYear];
		
    }
    return self;
}

- (void)drawDayButtons {
	dayButtons = [NSMutableArray arrayWithCapacity:42];
	for (int i = 0; i < 6; i++) {
		for(int j = 0; j < 7; j++) {
			CGRect buttonFrame = CGRectMake(j*cellWidth, (i+2)*cellHeight, cellWidth, cellHeight);
			DayButton *dayButton = [[DayButton alloc] initWithFrame:buttonFrame];
			dayButton.titleLabel.font = [UIFont fontWithName:calendarFontName size:22];
			dayButton.delegate = self;
			
			[dayButtons addObject:dayButton];
			
			[self addSubview:[dayButtons lastObject]];
		}
	}
}
			 
- (void)updateCalendarForMonth:(int)month forYear:(int)year {
    currentMonth = month;
    currentYear = year;
	char *months[12] = {"January", "Febrary", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"};
	monthLabel.text = [NSString stringWithFormat:@"%s %d", months[month - 1], year];
	
	//Get the first day of the month
	NSDateComponents *dateParts = [[NSDateComponents alloc] init];
	[dateParts setMonth:month];
	[dateParts setYear:year];
	[dateParts setDay:1];
	NSDate *dateOnFirst = [calendar dateFromComponents:dateParts];
	NSDateComponents *weekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:dateOnFirst];
	int weekdayOfFirst = [weekdayComponents weekday];	
	
	//Map first day of month to a week starting on Monday
	//as the weekday component defaults to 1->Sun, 2->Mon...
	if(weekdayOfFirst == 1) {
		weekdayOfFirst = 7;
	} else {
		--weekdayOfFirst;
	}

	int numDaysInMonth = [calendar rangeOfUnit:NSDayCalendarUnit 
										inUnit:NSMonthCalendarUnit 
											forDate:dateOnFirst].length;
	
	int day = 1;
	for (int i = 0; i < 6; i++) {
		for(int j = 0; j < 7; j++) {
			int buttonNumber = i * 7 + j;
			
			DayButton *button = [dayButtons objectAtIndex:buttonNumber];
			
			button.enabled = NO; //Disable buttons by default
			[button setTitle:nil forState:UIControlStateNormal]; //Set title label text to nil by default
			[button setButtonDate:nil];
            
            button.backgroundColor = [UIColor clearColor];
			
			if(buttonNumber >= (weekdayOfFirst - 1) && day <= numDaysInMonth) {
				[button setTitle:[NSString stringWithFormat:@"%d", day] 
												forState:UIControlStateNormal];
				
				NSDateComponents *dateParts = [[NSDateComponents alloc] init];
				[dateParts setMonth:month];
				[dateParts setYear:year];
				[dateParts setDay:day];
				NSDate *buttonDate = [calendar dateFromComponents:dateParts];
				[button setButtonDate:buttonDate];
                
                button.avalible = NO;
                button.selected = NO;
                if (self.selectedDates&&self.selectedDates.count>0&&[self.selectedDates containsObject:buttonDate]) {
//                    DLog(@"%@ selected",buttonDate);
                    button.selected = YES;
                }
                
                if (self.avalibleDates&&self.avalibleDates.count>0&&[self.avalibleDates containsObject:buttonDate]) {
//                    DLog(@"%@ avalible",buttonDate);
                    button.avalible = YES;
                }else{
                    button.avalible = NO;
                }
				
				button.enabled = YES;
				++day;
			}
		}
	}
}

- (void)prevBtnPressed:(id)sender {
	if(currentMonth == 1) {
		currentMonth = 12;
		--currentYear;
	} else {
		--currentMonth;
	}
	
	[self updateCalendarForMonth:currentMonth forYear:currentYear];
	
	if ([self.delegate respondsToSelector:@selector(prevButtonPressed)]) {
		[self.delegate prevButtonPressed];
	}
}

- (void)nextBtnPressed:(id)sender {
	if(currentMonth == 12) {
		currentMonth = 1;
		++currentYear;
	} else {
		++currentMonth;
	}
	
	[self updateCalendarForMonth:currentMonth forYear:currentYear];
	
	if ([self.delegate respondsToSelector:@selector(nextButtonPressed)]) {
		[self.delegate nextButtonPressed];
	}
}

- (void)dayButtonPressed:(id)sender {
    if (!self.avalibleDates) {
        self.avalibleDates = [NSMutableArray array];
    }
    if (!self.selectedDates) {
        self.selectedDates = [NSMutableArray array];
    }
	DayButton *dayButton = (DayButton *) sender;
    if (dayButton.avalible) {
        if ([self.selectedDates count]>0&&[self.selectedDates containsObject:dayButton.buttonDate]) {
            [self.selectedDates removeObject:dayButton.buttonDate];
            dayButton.selected = NO;
        }else{
            [self.selectedDates addObject:dayButton.buttonDate];
            dayButton.selected = YES;
        }
    }
	[self.delegate dayButtonPressed:dayButton];
}

- (void)dealloc {
}

- (void)openDates:(NSArray *)dates{
    if (!dates||dates.count <= 0) {
        return;
    }
    if (!self.avalibleDates) {
        self.avalibleDates = [NSMutableArray array];
    }
    if (!self.selectedDates) {
        self.selectedDates = [NSMutableArray array];
    }
    
//    self.avalibleDates = [[self.avalibleDates arrayByAddingObjectsFromArray:dates] mutableCopy];
//    DLog(@"dates:%@ aval:%@",dates, self.avalibleDates);
    
    for (NSDate* date in dates){
//        DLog(@"date:%@",date);
        NSDateComponents* comps = [calendar components:(NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit) fromDate:date];
        int month = [comps month];
        int year = [comps year];
        __block int day = [comps day];
        
        NSDateComponents *dateParts = [[NSDateComponents alloc] init];
        [dateParts setMonth:month];
        [dateParts setYear:year];
        [dateParts setDay:day];
        NSDate *newDate = [calendar dateFromComponents:dateParts];
        
        if (![self.avalibleDates containsObject:newDate]) {
            [self.avalibleDates addObject:newDate];
        }
        
        if (month == currentMonth&&year == currentYear) {
//            DLog(@"month and year good");
            [dayButtons enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                DayButton* btn = (DayButton*)obj;
                if (btn.buttonDate == nil) {
                    return;
                }
                NSDateComponents* comps = [calendar components:(NSDayCalendarUnit) fromDate:btn.buttonDate];
                if (day == [comps day]) {
//                    DLog(@"found one:%@",btn.buttonDate);
                    btn.avalible = YES;
                    *stop = YES;
                }
            }];
        }
    }
}


@end
