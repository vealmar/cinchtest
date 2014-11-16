//
// Created by David Jafari on 3/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKCalendarView.h"

@class Order;
@class Cart;

@interface CIShipDatesViewController : UITableViewController <CKCalendarDelegate, UITextFieldDelegate>

//Working copy of selected or new order
@property Order *workingOrder;
@property Cart *workingCart;

- (id)initWithWorkingOrder:(Order *)order;

@end