//
//  DayButton.h
//  DDCalendarView
//
//  Created by Damian Dawber on 28/12/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DayButtonDelegate <NSObject>
- (void)dayButtonPressed:(id)sender;
@end

@interface DayButton : UIButton {
}

@property (nonatomic, assign) id <DayButtonDelegate> delegate;
@property (nonatomic, copy) NSDate *buttonDate;
@property (nonatomic,setter = setAvalible:) BOOL avalible;

- (id)initWithFrame:(CGRect)buttonFrame;
-(void) setAvalible:(BOOL)aval;

@end
