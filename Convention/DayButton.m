//
//  DayButton.m
//  DDCalendarView
//
//  Created by Damian Dawber on 28/12/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DayButton.h"


@implementation DayButton
@synthesize delegate, buttonDate, avalible;

- (id)initWithFrame:(CGRect)buttonFrame {
	self = [super initWithFrame:buttonFrame];
	
    if (self) {
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.backgroundColor = [UIColor clearColor];
        [self setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        
        [self addTarget:delegate action:@selector(dayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
	
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	UILabel *titleLabel = [self titleLabel];
	CGRect labelFrame = titleLabel.frame;
	int framePadding = 4;
	labelFrame.origin.x = self.bounds.size.width - labelFrame.size.width - framePadding;
	labelFrame.origin.y = framePadding;
	
	[self titleLabel].frame = labelFrame;
}

- (void)dealloc {
}

-(void) setAvalible:(BOOL)aval{
    if (aval) {
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor lightGrayColor];
    }else{
        [self setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor clearColor];
        self.selected = NO;
    }
    avalible = aval;
}

@end
