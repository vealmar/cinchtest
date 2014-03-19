//
// Created by David Jafari on 3/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CKCalendarView.h"
#import "CIShipDatesViewController.h"
#import "ECSlidingViewController.h"
#import "DateUtil.h"
#import "config.h"
#import "NilUtil.h"
#import "DateRange.h"
#import "ShowConfigurations.h"
#import "Order.h"

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

@end

@implementation CIShipDatesViewController

static NSString *dateCellIdentifier = @"CISelectedShipDateCell";

- (id)initWithWorkingOrder:(Order *)workingOrder {
    self = [super init];
    if (self) {
        self.workingOrder = workingOrder;
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
        if (nil != self.workingOrder) self.workingOrder.ship_dates = [NSArray arrayWithArray:self.selectedShipDates];
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
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
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
    if (section == 0) {
        return 1;
    } else {
        return [self.selectedShipDates count] > 0 ? [self.selectedShipDates count] : 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Calendar";
    } else {
        return @"Ship Dates";
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return self.calendarView != nil ? self.calendarView.frame.size.height : 300;
    } else {
        return 40;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        if (nil == self.calendarCell) {
            self.calendarCell = [self createCalendarCell];
        }
        cell = self.calendarCell;
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:dateCellIdentifier];
        if (nil == cell) {
            cell = [self createShipDateCell];
            cell.textLabel.font = [UIFont fontWithName:kFontName size:14.0f];
        }
        NSString *label = [self.selectedShipDates count] == 0 ? @"No dates selected, ship immediately." : [DateUtil convertDateToMmddyyyy:[self.selectedShipDates objectAtIndex:indexPath.row]];
        cell.textLabel.text = label;
    }

    return cell;
}

- (UITableViewCell *)createShipDateCell {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 40)];
    cell.backgroundColor = self.tableBackgroundColor;
    cell.textLabel.textColor = self.tableTextColor;
    return cell;
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