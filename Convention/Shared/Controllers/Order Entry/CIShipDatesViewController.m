//
// Created by David Jafari on 3/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import <JSONKit/JSONKit.h>
#import "CKCalendarView.h"
#import "CIShipDatesViewController.h"
#import "ECSlidingViewController.h"
#import "config.h"
#import "NilUtil.h"
#import "DateRange.h"
#import "ShowConfigurations.h"
#import "Order.h"
#import "LineItem.h"
#import "NotificationConstants.h"
#import "CIShipDateTableViewCell.h"
#import "ThemeUtil.h"
#import "LineItem+Extensions.h"
#import "Product.h"
#import "NumberUtil.h"
#import "DateUtil.h"

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
@property BOOL first;

@property NSMutableArray *selectedLineItems;

@end

@implementation CIShipDatesViewController

static NSString *dateCellIdentifier = @"CISelectedShipDateCell";

- (id)initWithWorkingOrder:(Order *)workingOrder {
    self = [super init];
    if (self) {
        self.first = NO;
        self.workingOrder = workingOrder;
        self.selectedLineItems = [NSMutableArray array];
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

//        self.originalFrame = CGRectZero; //placeholder nil

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartSelection:) name:LineSelectionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartSelection:) name:LineDeselectionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLineTabbed:) name:LineTabbedNotification object:nil];
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self.tableView superview].backgroundColor = self.tableBackgroundColor;
    self.originalFrame = self.tableView.frame = CGRectMake(1024.0f - 320.0f,
                                     0,
                                     320.0f,
                                     724.0f);
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [self.tableView setSeparatorColor:[UIColor colorWithWhite:1.0 alpha:0.2]];
    if (!self.first) {
        [self observeKeyboard];
        self.first = YES;
    }
//    [self observeKeyboard];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.hidden = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CIShipDateTableViewCell *nextCell = (CIShipDateTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
        if (nextCell) {
            [nextCell.quantityField becomeFirstResponder];
        }
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.view.hidden = YES;
}

- (void)dealloc {
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onCartSelection:(NSNotification *)notification {
    LineItem *lineItem = (LineItem *) notification.object;
    if (notification.name == LineSelectionNotification) {
        [self.selectedLineItems addObject:lineItem];
    } else if (notification.name == LineDeselectionNotification) {
        [self.selectedLineItems removeObject:lineItem];
    }

    if ([ShowConfigurations instance].isLineItemShipDatesType) {
        if (self.selectedLineItems.count == 0) {
            [self.selectedShipDates.copy enumerateObjectsUsingBlock:^(id date, NSUInteger idx, BOOL *stop) {
                [self toggleDateSelection:date];
            }];
        }
        if (self.selectedLineItems.count == 1) {
            // add in all fixed dates, even if they arent currently assigned quantities
            NSArray *lineShipDates = ((LineItem *) self.selectedLineItems.firstObject).shipDates.array;
            NSMutableSet *shipDates = [NSMutableSet set];
            if (lineShipDates) [shipDates addObjectsFromArray:lineShipDates];
            [shipDates addObjectsFromArray:self.orderShipDates.fixedDates];
            [shipDates.allObjects enumerateObjectsUsingBlock:^(id date, NSUInteger idx, BOOL *stop) {
                [self toggleDateSelection:date];
            }];
        }
    }

//    [self.tableView reloadData];
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
            self.workingOrder.shipDates = [NSArray arrayWithArray:self.selectedShipDates];
        } else if ([ShowConfigurations instance].isLineItemShipDatesType && ![self.selectedShipDates containsObject:date]) {
            [self.selectedLineItems enumerateObjectsUsingBlock:^(LineItem *lineItem, NSUInteger idx, BOOL *stop) {
                [lineItem setQuantity:0 forShipDate:date];
            }];
        }
    }
}

- (void)setWorkingOrder:(Order *)newWorkingOrder {
    _workingOrder = newWorkingOrder;
    if (nil != _workingOrder) {
        self.selectedShipDates = [NSMutableArray arrayWithArray:_workingOrder.shipDates];
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

// @todo added for ellett will revisit
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            return 0;
        }
        case 1: {
            return 0; // @"Calendar" @todo make this configurable - hiding the calendar
        }
        case 2: {
            return 35.0f;
        }
        default: {
            return 0;
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (2 == section) {
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
    } else {
        return nil;
    }
}

#pragma mark TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            return 1;
        }
        case 1: {
            return 0; // 1;
        }
        case 2: {
            return [self.selectedShipDates count] > 0 ? [self.selectedShipDates count] : 1;
        }
        case 3: {
            return 0;
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
            return nil; // @"Calendar";
        }
        case 2: {
            return @"Ship Dates";
        }
        case 3: {
            return nil;
        }
        default: {
            return nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            Product *product = self.workingLineItem.product;
            BOOL descr2Visible = product.descr2 && product.descr2.length > 0;
            return 70.0f + //top
                    (descr2Visible ? 65.0f : 35.0f) + //mid
                    49.0f + //bottom
                    25.0f; //margin
        }
        case 1: {
            return 0; //self.calendarView != nil ? self.calendarView.frame.size.height : 300;
        }
        case 2: {
            return 40;
        }
        case 3: {
            return 600.0f;
        }
        default: {
            return 40.0f;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    switch (indexPath.section) {
        case 0: {
            Product *product = self.workingLineItem.product;

            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"headerCell"];
            cell.contentView.backgroundColor = tableView.backgroundColor;
            cell.backgroundColor = tableView.backgroundColor;

            UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(4, 9, 300, 180)];
            backgroundView.backgroundColor = [UIColor whiteColor];
            backgroundView.layer.cornerRadius = 5.0f;
            backgroundView.layer.masksToBounds = YES;

            UIView *shadowView = [[UIView alloc] initWithFrame:CGRectMake(4, 9, 300, 180)];
            shadowView.layer.cornerRadius = 5.0f;
            shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
            shadowView.layer.shadowOffset = CGSizeMake(0, 1.0f);
            shadowView.layer.shadowRadius = 5;
            shadowView.layer.shadowOpacity = 0.6;

            ////////////////////////////////////////////////////////////////////////////////////////////////////////
            UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, backgroundView.bounds.size.width, 70)];
            topView.backgroundColor = [UIColor colorWithRed:0.290 green:0.224 blue:0.169 alpha:1];
            [backgroundView addSubview:topView];

            UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
            iconView.contentMode = UIViewContentModeCenter;
            iconView.image = [UIImage imageNamed:@"ico-cell-header-icon"];
            [topView addSubview:iconView];

            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 7, 190, 35)];
            titleLabel.font = [UIFont boldFontOfSize:20];
            titleLabel.textAlignment = NSTextAlignmentRight;
            titleLabel.textColor = [UIColor orangeColor];
            titleLabel.text = product.invtid;
            [topView addSubview:titleLabel];

            UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 29, 190, 35)];
            subtitleLabel.font = [UIFont regularFontOfSize:14];
            subtitleLabel.textAlignment = NSTextAlignmentRight;
            subtitleLabel.textColor = [UIColor whiteColor];
            subtitleLabel.text = @"Product";
            [topView addSubview:subtitleLabel];

            ////////////////////////////////////////////////////////////////////////////////////////////////////////
            BOOL descr2Visible = product.descr2 && product.descr2.length > 0;
            
            UIView *middleView = [[UIView alloc] initWithFrame:CGRectMake(0, topView.bounds.size.height, backgroundView.bounds.size.width, (descr2Visible ? 65 : 35))];
            middleView.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1];
            [backgroundView addSubview:middleView];

            UILabel *line1 = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, 290, 25)];
            line1.font = [UIFont regularFontOfSize:12];
            line1.textAlignment = NSTextAlignmentLeft;
            line1.textColor = [UIColor blackColor];
            line1.text = product.descr;
            [middleView addSubview:line1];

            if (descr2Visible || product.partnbr) {
                UILabel *line2 = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, 290, 25)];
                line2.font = [UIFont regularFontOfSize:12];
                line2.textAlignment = NSTextAlignmentLeft;
                line2.textColor = [UIColor blackColor];
                line2.text = [NSString stringWithFormat:@"%@ %@",
                              (descr2Visible ? product.descr2 : @""),
                              (product.partnbr ? [NSString stringWithFormat:@"MFG NO: %@", product.partnbr] : @"") ];
                [middleView addSubview:line2];
            }

            ////////////////////////////////////////////////////////////////////////////////////////////////////////
            UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, topView.bounds.size.height + middleView.bounds.size.height, backgroundView.bounds.size.width, 46)];
            bottomView.backgroundColor = [UIColor colorWithWhite:0.976 alpha:1.000];
            [backgroundView addSubview:bottomView];

            UILabel *p1line1 = [[UILabel alloc] initWithFrame:CGRectMake(9, -1, 150, 35)];
            p1line1.font = [UIFont boldFontOfSize:18];
            p1line1.textAlignment = NSTextAlignmentLeft;
            p1line1.textColor = [ThemeUtil blackColor];
            p1line1.text = [NumberUtil formatDollarAmount:product.showprc];
            [bottomView addSubview:p1line1];

            UILabel *p1line2 = [[UILabel alloc] initWithFrame:CGRectMake(10, 16, 150, 35)];
            p1line2.font = [UIFont regularFontOfSize:11];
            p1line2.textAlignment = NSTextAlignmentLeft;
            p1line2.textColor = [ThemeUtil noteColor];
            p1line2.text = [ShowConfigurations instance].price1Label;
            [bottomView addSubview:p1line2];

            UILabel *p2line1 = [[UILabel alloc] initWithFrame:CGRectMake(151, -1, 140, 35)];
            p2line1.font = [UIFont regularFontOfSize:18];
            p2line1.textAlignment = NSTextAlignmentRight;
            p2line1.textColor = [ThemeUtil blackColor];
            p2line1.text = [NumberUtil formatDollarAmount:product.regprc];
            [bottomView addSubview:p2line1];

            UILabel *p2line2 = [[UILabel alloc] initWithFrame:CGRectMake(150, 16, 140, 35)];
            p2line2.font = [UIFont regularFontOfSize:11];
            p2line2.textAlignment = NSTextAlignmentRight;
            p2line2.textColor = [ThemeUtil noteColor];
            p2line2.text = [ShowConfigurations instance].price2Label;
            [bottomView addSubview:p2line2];


            backgroundView.frame = CGRectMake(4, 9, 300, topView.frame.size.height + middleView.frame.size.height + bottomView.frame.size.height);
            shadowView.frame = CGRectMake(4, 9, 300, topView.frame.size.height + middleView.frame.size.height + bottomView.frame.size.height);

            [shadowView addSubview:backgroundView];
            [cell.contentView addSubview:shadowView];

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
            if (nil == self.calendarCell) {
                self.calendarCell = [self createCalendarCell];
            }
            cell = self.calendarCell;
            break;
        }
        case 2: {
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
    CIShipDateTableViewCell *cell = [[CIShipDateTableViewCell alloc] initOn:shipDate for:self.selectedLineItems usingQuantityField:useQuantityField];

    if (useQuantityField) {
        __weak typeof(cell) weakCell = cell;
        __weak NSDate *weakShipDate = shipDate;
        [cell.quantityField setBk_didBeginEditingBlock:^(UITextField *field) {
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:weakCell];

            // we need to scroll up because any cells that are not visible won't be elgible for "next cell" tabbing
            [self.tableView scrollToRowAtIndexPath:cellIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];

            UITextRange *textRange = [field textRangeFromPosition:field.beginningOfDocument toPosition:field.endOfDocument];
            [field setSelectedTextRange:textRange];

            Underscore.array([self.tableView indexPathsForVisibleRows]).each(^(NSIndexPath *indexPath) {
                if (indexPath.section == 2 && cellIndexPath.section == indexPath.section && cellIndexPath.row != indexPath.row) {
//                    CIShipDateTableViewCell *nextCell = (CIShipDateTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//                    if (nextCell.quantityField.canResignFirstResponder) {
//                        [nextCell.quantityField resignFirstResponder];
//                    }
                }
            });
        }];

        [cell.quantityField setBk_didEndEditingBlock:^(UITextField *field) {
            [self calculateLineTotal:weakCell on:weakShipDate];
        }];
        [self calculateLineTotal:cell on:shipDate];

    }

    return cell;
}

- (void)onLineTabbed:(NSNotification *)notification {
    CIShipDateTableViewCell *currentCell = (CIShipDateTableViewCell *) notification.object;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:currentCell];
    CIShipDateTableViewCell *nextCell = (CIShipDateTableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
    if (nextCell) {
        [nextCell.quantityField becomeFirstResponder];
    } else {
        [currentCell.quantityField resignFirstResponder];
    }
}

- (void)calculateLineTotal:(CIShipDateTableViewCell *)cell on:(NSDate *)shipDate{
    NSArray *fixedShipDates = [ShowConfigurations instance].orderShipDates.fixedDates;
    NSNumber *price = self.workingLineItem.price;
    if ([ShowConfigurations instance].atOncePricing && fixedShipDates.count > 0) {
        if ([((NSDate *) fixedShipDates.firstObject) isEqualToDate:shipDate]) {
            price = self.workingLineItem.product.showprc;
        } else {
            price = self.workingLineItem.product.regprc;
        }
    }

    int quantity = [cell.quantityField.text intValue];
    double total = quantity * [price doubleValue];
    cell.lineTotalLabel.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:total]];

    if (quantity > 0) {
        cell.lineTotalBackgroundView.backgroundColor = [ThemeUtil orangeColor];
    } else {
        cell.lineTotalBackgroundView.backgroundColor = [ThemeUtil blackColor];
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

#pragma mark Keyboard Adjustments

- (void)observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

// The callback for frame-changing of keyboard
- (void)keyboardWillShow:(NSNotification *)notification {
    float keyboardHeight = 352.0f; // keyboard frame
    float availableHeight = 724.0f; // available height ( - nav bar)

    float resizeHeight = availableHeight - keyboardHeight - 1.0f;
    if (self.tableView.frame.size.height == 724.0f) {
        self.tableView.frame = self.tableView.frame = CGRectMake(1024.0f - 320.0f,
                                                                 0,
                                                                 320.0f,
                                                                 resizeHeight);
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (self.tableView.frame.size.height != 724.0f) {
        self.tableView.frame = self.tableView.frame = CGRectMake(1024.0f - 320.0f,
                                                                 0,
                                                                 320.0f,
                                                                 724.0f);
    }
}

@end