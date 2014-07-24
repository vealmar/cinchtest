//
//  OrderShipDateViewController.h
//  Convention
//
//  Created by septerr on 2/5/14.
//  Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CKCalendarView.h"

@protocol OrderShipDateViewControllerDelegate <NSObject>
- (void)shipDateSelected:(NSDate *)date;

- (void)orderShipDateViewControllerCancelled;

@end

@interface OrderShipDateViewController : UIViewController <CKCalendarDelegate>
@property(strong, nonatomic) NSDate *selectedDate;
@property(nonatomic, assign) id <OrderShipDateViewControllerDelegate> delegate;

- (id)initWithDelegate:(id <OrderShipDateViewControllerDelegate>)delegate;
@end
