//
// Created by David Jafari on 3/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CKCalendarView.h"
#import "CIShipDatesViewController.h"
#import "ECSlidingViewController.h"
#import "DateUtil.h"
#import "config.h"
#import "NilUtil.h"
#import "DateRange.h"
#import "ShowConfigurations.h"
#import "Order.h"
#import "Cart+Extensions.h"
#import "NotificationConstants.h"
#import "UIView+Boost.h"
#import "CIShipDateTableViewCell.h"
#import "NSArray+Boost.h"

@interface CIShipDatesViewController()

@property ECSlidingViewController *slidingViewController;
@property UITableViewCell *calendarCell;
@property CKCalendarView *calendarView;
@property NSMutableArray *selectedShipDates;
@property DateRange *orderShipDates;

@property UIColor *tableBackgroundColor;
@property UIColor *tableTextColor;
@property UIColor *dateSelectedBackgroundColor;
@property UIColor *dateSelectedTextColor;
@property UIColor *dateSelectableBackgroundColor;
@property UIColor *dateSelectableTextColor;

@property CGRect originalFrame;

@property NSMutableArray *selectedCarts;

@end

@implementation CIShipDatesViewController

static NSString *dateCellIdentifier = @"CISelectedShipDateCell";

- (id)initWithWorkingOrder:(Order *)workingOrder {
    self = [super init];
    if (self) {
        self.workingOrder = workingOrder;
        self.selectedCarts = [NSMutableArray array];
        self.selectedShipDates = [NSMutableArray array];
        self.orderShipDates = [ShowConfigurations instance].orderShipDates;

        self.tableBackgroundColor = [UIColor colorWithRed:57/255.0f green:59/255.0f blue:64/255.0f alpha:1];
        self.tableTextColor = [UIColor whiteColor];
        self.dateSelectedBackgroundColor = [UIColor colorWithRed:30/255.0f green:240/255.0f blue:0/255.0f alpha:1];
        self.dateSelectedTextColor = [UIColor whiteColor];
        self.dateSelectableBackgroundColor = [UIColor colorWithRed:0/255.0f green:120/255.0f blue:255/255.0f alpha:1];
        self.dateSelectableTextColor = [UIColor whiteColor];

        self.tableView.backgroundColor = self.tableBackgroundColor;
        self.tableView.allowsSelection = NO;

        self.originalFrame = CGRectZero; //placeholder nil

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartSelection:) name:CartSelectionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartSelection:) name:CartDeselectionNotification object:nil];
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    if (CGRectEqualToRect(self.originalFrame, CGRectZero)) {
        self.originalFrame = self.tableView.frame;
        [self.tableView superview].backgroundColor = self.tableBackgroundColor;
    }
    self.tableView.frame = CGRectMake(self.originalFrame.origin.x + 10.0f,
            self.originalFrame.origin.y,
            self.originalFrame.size.width - 10.0f,
            self.originalFrame.size.height);
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1.0 alpha:0.2]];
}

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onCartSelection:(NSNotification *)notification {
    Cart *cart = (Cart *) notification.object;
    if (notification.name == CartSelectionNotification) {
        [self.selectedCarts addObject:cart];
    } else if (notification.name == CartDeselectionNotification) {
        [self.selectedCarts removeObject:cart];
    }

    if ([ShowConfigurations instance].isLineItemShipDatesType) {
        if (self.selectedCarts.count == 0) {
            [self.selectedShipDates.copy enumerateObjectsUsingBlock:^(id date, NSUInteger idx, BOOL *stop) {
                [self toggleDateSelection:date];
            }];
        }
        if (self.selectedCarts.count == 1) {
            // add in all fixed dates, even if they arent currently assigned quantities
            NSArray *cartShipDates = ((Cart *) self.selectedCarts.firstObject).shipdates;
            NSMutableSet *shipDates = [NSMutableSet set];
            if (cartShipDates) [shipDates addObjectsFromArray:[[cartShipDates valueForKey:@"shipdate"] allObjects]];
            [shipDates addObjectsFromArray:self.orderShipDates.fixedDates];
            [shipDates.allObjects enumerateObjectsUsingBlock:^(id date, NSUInteger idx, BOOL *stop) {
                [self toggleDateSelection:date];
            }];
        }
    }

    [self.tableView reloadData];
}

#pragma mark CKCalendarDelegate

// The CKCalendarView assumes one date will be selected whereas we are selecting many. We handle the
// selection manually through the delegate methods to allow this to happen.

- (void)calendar:(CKCalendarView *)calendar didLayoutInRect:(CGRect)frame {
    NSIndexPath *calendarPath = [NSIndexPath indexPathForItem:0 inSection:0];
    if (self.calendarCell.frame.size.height != frame.size.height) {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

- (void)calendar:(CKCalendarView *)calendar didSelectDate:(NSDate *)date {
    [self toggleDateSelection:date];
}

// this gets called when the currently selected date is deselected
- (BOOL)calendar:(CKCalendarView *)calendar willDeselectDate:(NSDate *)date {
    [self toggleDateSelection:date];
    return NO;
}


- (void)calendar:(CKCalendarView *)calendar didDeselectDate:(NSDate *)date {
    [self toggleDateSelection:date];
}

- (void)toggleDateSelection:(NSDate *)date {
    if (nil != date && (self.orderShipDates == nil || [self.orderShipDates covers:date])) {
        if (![self.selectedShipDates containsObject:date]) {
            [self.selectedShipDates addObject:date];
            [self reloadSelectedDatesSection];
        } else {
            [self.selectedShipDates removeObject:date];
            [self reloadSelectedDatesSection];
        }
        [self.calendarView reloadDates:@[date]];
        if (nil != self.workingOrder && [ShowConfigurations instance].isOrderShipDatesType) {
            self.workingOrder.ship_dates = [NSArray arrayWithArray:self.selectedShipDates];
        } else if ([ShowConfigurations instance].isLineItemShipDatesType && ![self.selectedShipDates containsObject:date]) {
            [self.selectedCarts enumerateObjectsUsingBlock:^(Cart *cart, NSUInteger idx, BOOL *stop) {
                [cart setQuantity:0 forShipDate:date];
            }];
        }
    }
}

- (void)setWorkingOrder:(Order *)newWorkingOrder {
    _workingOrder = newWorkingOrder;
    if (nil != _workingOrder) {
        self.selectedShipDates = [NSMutableArray arrayWithArray:_workingOrder.ship_dates];
        [self.calendarView reloadDates:self.selectedShipDates];
        [self reloadSelectedDatesSection];
    }

}

- (void)reloadSelectedDatesSection {
    [self.selectedShipDates sortUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"timeIntervalSince1970" ascending:YES] ]];

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.tableView.numberOfSections - 1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)calendar:(CKCalendarView *)calendar configureDateItem:(CKDateItem *)dateItem forDate:(NSDate *)date {
    if ([self.selectedShipDates containsObject:date]) {
        dateItem.selectedBackgroundColor = self.dateSelectedBackgroundColor;
        dateItem.backgroundColor = self.dateSelectedBackgroundColor;
        dateItem.selectedTextColor = self.dateSelectedTextColor;
        dateItem.textColor = self.dateSelectedTextColor;
    } else if (self.orderShipDates != nil && [self.orderShipDates covers:date]) {
        dateItem.selectedBackgroundColor = self.dateSelectableBackgroundColor;
        dateItem.backgroundColor = self.dateSelectableBackgroundColor;
        dateItem.selectedTextColor = self.dateSelectableTextColor;
        dateItem.textColor = self.dateSelectableTextColor;
    } else {
        dateItem.selectedBackgroundColor = dateItem.backgroundColor;
        dateItem.selectedTextColor = dateItem.textColor;
    }
}

#pragma mark TableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;

    if (indexPath.section == 1 && [self.selectedShipDates count] > 0) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && editingStyle == UITableViewCellEditingStyleDelete) {
        NSDate *date = [self.selectedShipDates objectAtIndex:indexPath.row];
        [self toggleDateSelection:date];
        [self.calendarView selectDate:date makeVisible:false];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0f;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 30)];
    [headerView setBackgroundColor:[UIColor colorWithRed:57/255.0f green:59/255.0f blue:64/255.0f alpha:1]];

    NSString *sectionTitle = [NilUtil objectOrEmptyString:[self tableView:tableView titleForHeaderInSection:section]];

    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(6, 2, self.tableView.bounds.size.width - 6, 25);
    label.backgroundColor = self.tableBackgroundColor;
    label.textColor = self.tableTextColor;
    label.font = [UIFont fontWithName:kFontName size:14.0f];
    label.text = sectionTitle;

    [headerView addSubview:label];

    return headerView;
}

#pragma mark TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            return 1;
        }
        case 1: {
//            return 1;
//        }
//        case 2: {
            return [self.selectedShipDates count] > 0 ? [self.selectedShipDates count] : 1;
        }
        default: {
            return 0;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            return nil;
        }
        case 1: {
//            return @"Calendar";
//        }
//        case 2: {
            return @"Ship Dates";
        }
        default: {
            return nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            return 240;
        }
        case 1: {
//            return self.calendarView != nil ? self.calendarView.frame.size.height : 300;
//        }
//        case 2: {
            return 40;
        }
        default: {
            return 40;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    switch (indexPath.section) {
        case 0: {
            Product *product = self.workingCart.product;

            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"headerCell"];
            cell.contentView.backgroundColor = tableView.backgroundColor;
            cell.backgroundColor = tableView.backgroundColor;

            UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(7, 27, 300, 200)];
            backgroundView.backgroundColor = [UIColor whiteColor];
            backgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
            backgroundView.layer.shadowOffset = CGSizeMake(0, 0);
            backgroundView.layer.shadowRadius = 5;
            backgroundView.layer.shadowOpacity = 0.5;
            [cell.contentView addSubview:backgroundView];

            ////////////////////////////////////////////////////////////////////////////////////////////////////////
            UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, backgroundView.bounds.size.width, 70)];
            topView.backgroundColor = [UIColor colorWithRed:0.290 green:0.224 blue:0.169 alpha:1];
            [backgroundView addSubview:topView];

            UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
            iconView.contentMode = UIViewContentModeCenter;
            iconView.image = [UIImage imageNamed:@"ico-cell-header-icon"];
            [topView addSubview:iconView];

            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 0 + 5, 190, 35)];
            titleLabel.font = [UIFont boldSystemFontOfSize:20];
            titleLabel.textAlignment = NSTextAlignmentRight;
            titleLabel.textColor = [UIColor colorWithRed:0.808 green:0.518 blue:0.169 alpha:1];
            titleLabel.text = product.invtid;
            [topView addSubview:titleLabel];

            UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 35 - 5, 190, 35)];
            subtitleLabel.font = [UIFont regularFontOfSize:15];
            subtitleLabel.textAlignment = NSTextAlignmentRight;
            subtitleLabel.textColor = [UIColor whiteColor];
            subtitleLabel.text = @"Product";
            [topView addSubview:subtitleLabel];

            ////////////////////////////////////////////////////////////////////////////////////////////////////////
            UIView *middleView = [[UIView alloc] initWithFrame:CGRectMake(0, topView.bounds.size.height, backgroundView.bounds.size.width, 65)];
            middleView.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1];
            [backgroundView addSubview:middleView];

            UILabel *line1 = [[UILabel alloc] initWithFrame:CGRectMake(10, 0 + 5, 290, 30)];
            line1.font = [UIFont regularFontOfSize:15];
            line1.textAlignment = NSTextAlignmentLeft;
            line1.textColor = [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1];
            line1.text = product.descr;
            [middleView addSubview:line1];

            UILabel *line2 = [[UILabel alloc] initWithFrame:CGRectMake(10, 30 - 0, 290, 30)];
            line2.font = [UIFont regularFontOfSize:15];
            line2.textAlignment = NSTextAlignmentLeft;
            line2.textColor = [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1];
            line2.text = product.descr2;
            [middleView addSubview:line2];

            ////////////////////////////////////////////////////////////////////////////////////////////////////////
            UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, topView.bounds.size.height + middleView.bounds.size.height, backgroundView.bounds.size.width, 65)];
            bottomView.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1];
            [backgroundView addSubview:bottomView];

            NSNumberFormatter *formatter = [NSNumberFormatter new];
            [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];

            UILabel *p1line1 = [[UILabel alloc] initWithFrame:CGRectMake(10, 0 + 5, 150, 35)];
            p1line1.font = [UIFont boldSystemFontOfSize:18];
            p1line1.textAlignment = NSTextAlignmentLeft;
            p1line1.textColor = [UIColor colorWithRed:0.135 green:0.147 blue:0.151 alpha:1];
            p1line1.text = [formatter stringFromNumber:@([product.showprc intValue] / 100.0)];
            [bottomView addSubview:p1line1];

            UILabel *p1line2 = [[UILabel alloc] initWithFrame:CGRectMake(10, 30 - 0, 150, 35)];
            p1line2.font = [UIFont regularFontOfSize:13];
            p1line2.textAlignment = NSTextAlignmentLeft;
            p1line2.textColor = [UIColor colorWithRed:0.335 green:0.347 blue:0.351 alpha:1];
            p1line2.text = @"Show";
            [bottomView addSubview:p1line2];

            UILabel *p2line1 = [[UILabel alloc] initWithFrame:CGRectMake(150, 0 + 5, 140, 35)];
            p2line1.font = [UIFont regularFontOfSize:18];
            p2line1.textAlignment = NSTextAlignmentRight;
            p2line1.textColor = [UIColor colorWithRed:0.135 green:0.147 blue:0.151 alpha:1];
            p2line1.text = [formatter stringFromNumber:@([product.regprc intValue] / 100.0)];
            [bottomView addSubview:p2line1];

            UILabel *p2line2 = [[UILabel alloc] initWithFrame:CGRectMake(150, 30 - 0, 140, 35)];
            p2line2.font = [UIFont regularFontOfSize:13];
            p2line2.textAlignment = NSTextAlignmentRight;
            p2line2.textColor = [UIColor colorWithRed:0.335 green:0.347 blue:0.351 alpha:1];
            p2line2.text = @"Regular";
            [bottomView addSubview:p2line2];



//            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
//            cell.contentView.backgroundColor = tableView.backgroundColor;
//
//            UILabel *label = [[UILabel alloc] init];
//            label.frame = CGRectInset(cell.frame, 5, 5);
//            label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//            label.backgroundColor = tableView.backgroundColor;
//            label.textColor = self.tableTextColor;
//            label.font = [UIFont fontWithName:kFontName size:14.0f];
//            label.text = self.workingCart.product.descr;
//            [cell.contentView addSubview:label];

            break;
        }
        case 1: {
//            if (nil == self.calendarCell) {
//                self.calendarCell = [self createCalendarCell];
//            }
//            cell = self.calendarCell;
//            break;
//        }
//        case 2: {
            cell = [self.tableView dequeueReusableCellWithIdentifier:dateCellIdentifier];
            NSDate *selectedDate = [self.selectedShipDates count] == 0 ? nil : [self.selectedShipDates objectAtIndex:indexPath.row];
            if (nil == cell) {
                cell = [self createShipDateCellOn:selectedDate];
            }
            break;
        }
        default: {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            break;
        }
    }

    return cell;
}

- (UITableViewCell *)createShipDateCellOn:(NSDate *)shipDate {
    BOOL useQuantityField = [ShowConfigurations instance].isLineItemShipDatesType && [self.selectedShipDates count] != 0;
    CIShipDateTableViewCell *cell = [[CIShipDateTableViewCell alloc] initOn:shipDate for:self.selectedCarts usingQuantityField:useQuantityField];

    if (useQuantityField) {
        UISwipeGestureRecognizer *swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(decrementQuantity:)];
        swipeLeftGesture.numberOfTouchesRequired = 1;
        swipeLeftGesture.cancelsTouchesInView = NO;
        swipeLeftGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell.contentView addGestureRecognizer:swipeLeftGesture];

        UISwipeGestureRecognizer *swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(incrementQuantity:)];
        swipeRightGesture.numberOfTouchesRequired = 1;
        swipeRightGesture.cancelsTouchesInView = NO;
        swipeRightGesture.direction = UISwipeGestureRecognizerDirectionRight;
        [cell.contentView addGestureRecognizer:swipeRightGesture];

        cell.contentView.userInteractionEnabled = YES;

        __weak typeof(cell) weakCell = cell;
        [cell setResignedFirstResponderBlock:^(CIShipDateTableViewCell *c) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:weakCell];
            NSLog(@"%d %d", indexPath.section, indexPath.row);

            int quantity = [weakCell.quantityField.text intValue];
            float price = 0;
            if (indexPath.row == 0) {
                price = [self.workingCart.product.showprc intValue] / 100.0;
            } else {
                price = [self.workingCart.product.regprc intValue] / 100.0;
            }
            float total = quantity * price;

            NSNumberFormatter *formatter = [NSNumberFormatter new];
            [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];

            weakCell.lineTotalLabel.text = [formatter stringFromNumber:@(total)];

            if (quantity > 0) {
                weakCell.lineTotalBackgroundView.backgroundColor = [UIColor colorWithRed:0.794 green:0.469 blue:0.088 alpha:1];
            } else {
                weakCell.lineTotalBackgroundView.backgroundColor = [UIColor colorWithRed:0.161 green:0.169 blue:0.169 alpha:1];
            }

            CIShipDateTableViewCell *nextCell = (CIShipDateTableViewCell(*))[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section]];
            if (nextCell) {
                [nextCell.quantityField becomeFirstResponder];
            }
        }];
    }

    return cell;
}

- (void)incrementQuantity:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CIShipDateTableViewCell *cell = recognizer.view.superview.superview;
        cell.quantity += 1;
    }
}

- (void)decrementQuantity:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CIShipDateTableViewCell *cell = recognizer.view.superview.superview;
        cell.quantity -= 1;
    }
}

- (UITableViewCell *)createCalendarCell {
    UITableViewCell *cell = [[UITableViewCell alloc] init];

    self.calendarView = [[CKCalendarView alloc] init];
    self.calendarView.layer.cornerRadius = 0.0f;

    [cell.contentView addSubview:self.calendarView];
    self.calendarView.delegate = self;

    return cell;
}

@end