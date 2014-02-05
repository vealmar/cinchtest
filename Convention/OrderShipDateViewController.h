//
//  OrderShipDateViewController.h
//  Convention
//
//  Created by septerr on 2/5/14.
//  Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CKCalendarView.h"

@interface OrderShipDateViewController : UIViewController <CKCalendarDelegate>
@property(strong, nonatomic) NSDate *selectedDate;

- (id)initWithDateDoneBlock:(void (^)(NSDate *))doneBlock cancelBlock:(void (^)())cancelBlock;
@end
