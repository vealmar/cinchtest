//
// Created by David Jafari on 3/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//
// Sections:
// 0 - Product Info
// 1 - Calendar for Ship Date Selection
// 2 - Ship Date x Quantity Entry
// 3 - Price Level Selection

#import "CKCalendarView.h"
#import "CIProductDetailTableViewController.h"
#import "NilUtil.h"
#import "DateRange.h"
#import "Configurations.h"
#import "Order.h"
#import "LineItem.h"
#import "NotificationConstants.h"
#import "CIShipDateTableViewCell.h"
#import "ThemeUtil.h"
#import "LineItem+Extensions.h"
#import "Product.h"
#import "CurrentSession.h"
#import "CIProductInfoTableViewCell.h"
#import "CIPriceOptionTableViewCell.h"
#import "CIOrderTotalTableViewCell.h"

@interface CIProductDetailTableViewController ()

@property UITableViewCell *calendarCell;
@property CKCalendarView *calendarView;
@property NSMutableArray *selectedShipDates;
@property DateRange *orderShipDates;

@property UIColor *dateSelectedBackgroundColor;
@property UIColor *dateSelectedTextColor;
@property UIColor *dateSelectableBackgroundColor;
@property UIColor *dateSelectableTextColor;

@property BOOL first;

@property NSMutableArray *selectedLineItems;
@property LineItem *currentLineItem;

@end

@implementation CIProductDetailTableViewController

static NSString *productInfoCellIdentifier = @"CIProductInfoTableViewCell";
static NSString *dateCellIdentifier = @"CIShipDateTableViewCell";
static NSString *orderTotalCellIdentifier = @"CIOrderTotalTableViewCell";
static NSString *priceOptionCellIdentifier = @"CIPriceOptionTableViewCell";

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.first = NO;
        self.selectedLineItems = [NSMutableArray array];
        self.selectedShipDates = [NSMutableArray array];
        self.orderShipDates = [Configurations instance].orderShipDates;

        self.dateSelectedBackgroundColor = [UIColor colorWithRed:30/255.0f green:240/255.0f blue:0/255.0f alpha:1];
        self.dateSelectedTextColor = [UIColor whiteColor];
        self.dateSelectableBackgroundColor = [UIColor colorWithRed:0/255.0f green:120/255.0f blue:255/255.0f alpha:1];
        self.dateSelectableTextColor = [UIColor whiteColor];

        self.tableView.allowsSelection = YES;
        self.tableView.allowsMultipleSelection = NO;
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.separatorColor = [UIColor colorWithRed:0.808 green:0.808 blue:0.827 alpha:1];
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0F;
        self.clearsSelectionOnViewWillAppear = NO;

        [self.tableView registerClass:[CIPriceOptionTableViewCell class] forCellReuseIdentifier:priceOptionCellIdentifier];
        [self.tableView registerClass:[CIShipDateTableViewCell class] forCellReuseIdentifier:dateCellIdentifier];
        [self.tableView registerClass:[CIOrderTotalTableViewCell class] forCellReuseIdentifier:orderTotalCellIdentifier];
        [self.tableView registerClass:[CIProductInfoTableViewCell class] forCellReuseIdentifier:productInfoCellIdentifier];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartSelection:) name:LineSelectionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartSelection:) name:LineDeselectionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLineTabbed:) name:LineTabbedNotification object:nil];
    }
    return self;
}

- (void)prepareForDisplay:(Order *)workingOrder lineItem:(LineItem *)workingLineItem {
    self.workingOrder = workingOrder;
    self.currentLineItem = workingLineItem;

    Product *product = self.currentLineItem.product;
    if (!product) {
        [[CurrentSession mainQueueContext] refreshObject:self.currentLineItem mergeChanges:YES];
    }

    [self.tableView reloadData];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    if (!self.first) {
        self.first = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.hidden = NO;

    if ([Configurations instance].isLineItemShipDatesType) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CIShipDateTableViewCell *nextCell = (CIShipDateTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
            if (nextCell) {
                [nextCell.quantityField becomeFirstResponder];
            }
        });
    }
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

    if ([Configurations instance].isLineItemShipDatesType) {
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
    [NSIndexPath indexPathForItem:0 inSection:1];
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
        if (nil != self.workingOrder && [Configurations instance].isOrderShipDatesType) {
            self.workingOrder.shipDates = [NSArray arrayWithArray:self.selectedShipDates];
        } else if ([Configurations instance].isLineItemShipDatesType && ![self.selectedShipDates containsObject:date]) {
            [self.selectedLineItems enumerateObjectsUsingBlock:^(LineItem *lineItem, NSUInteger idx, BOOL *stop) {
                [lineItem setQuantity:0 forShipDate:date];
            }];
        }
    }
}

- (void)setCurrentLineItem:(LineItem *)lineItem {
    _currentLineItem = lineItem;
    [self.tableView reloadSections:(lineItem.isWriteIn ? [NSIndexSet indexSetWithIndex:1] : [NSIndexSet indexSetWithIndex:0]) withRowAnimation:UITableViewRowAnimationNone];
}

- (void)setWorkingOrder:(Order *)newWorkingOrder {
    _workingOrder = newWorkingOrder;
    if (nil != _workingOrder && [Configurations instance].isLineItemShipDatesType) {
        self.selectedShipDates = [NSMutableArray array];
        if (_workingOrder.shipDates) [self.selectedShipDates addObjectsFromArray:_workingOrder.shipDates];
        [self.calendarView reloadDates:self.selectedShipDates];
        [self reloadSelectedDatesSection];
    }
}

- (void)reloadSelectedDatesSection {
    [self.selectedShipDates sortUsingDescriptors:@[ [[NSSortDescriptor alloc] initWithKey:@"timeIntervalSince1970" ascending:YES] ]];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
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


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 3) {
        return indexPath;
    } else {
        return nil;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && editingStyle == UITableViewCellEditingStyleDelete) {
        NSDate *date = self.selectedShipDates[(NSUInteger) indexPath.row];
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
            return 44.0F;
        }
        case 3: {
            return 44.0F;
        }
        default: {
            return 0;
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (2 == section || 3 == section) {
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(10.0F,0,200.0F,[self tableView:tableView heightForHeaderInSection:section])];

        NSString *sectionTitle = [NilUtil objectOrEmptyString:[self tableView:tableView titleForHeaderInSection:section]];

        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(10, 0, self.tableView.bounds.size.width - 10, 44.0F);
        label.textColor = [ThemeUtil noteColor];
        label.font = [UIFont semiboldFontOfSize:14.0f];
        label.text = [sectionTitle uppercaseString];

        [headerView addSubview:label];

        return headerView;
    } else {
        return nil;
    }

    return nil;
}

#pragma mark TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
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
            if ([Configurations instance].isLineItemShipDatesType) {
                if ([self.selectedShipDates count] > 0) {
                    return [self.selectedShipDates count] + 1; // add 1 for order totals row
                } else {
                    return 0;
                }
            } else {
                return 1;
            }
        }
        case 3: {
            if (self.currentLineItem.isWriteIn) {
                return 1;
            } else {
                return [Configurations instance].priceTiersAvailable + 1;
            }
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
            return @"Quantity";
        }
        case 3: {
            return @"Pricing";
        }
        default: {
            return nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
//            return [self tableView:self.tableView cellForRowAtIndexPath:indexPath].contentView.frame.size.height;
//            return self.lastProductInfoHeight == 0 ? 120.0F : self.lastProductInfoHeight;
            return UITableViewAutomaticDimension;
        }
        case 1: {
            return 0; //self.calendarView != nil ? self.calendarView.frame.size.height : 300;
        }
        case 2: {
            return 48.0F;
        }
        case 3: {
            return 48.0F;
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
            CIProductInfoTableViewCell *priceOptionCell = (CIProductInfoTableViewCell *) [self.tableView dequeueReusableCellWithIdentifier:productInfoCellIdentifier forIndexPath:indexPath];
            cell = priceOptionCell;
            [priceOptionCell prepareForDisplay:self.currentLineItem];
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
            if (![Configurations instance].isLineItemShipDatesType || indexPath.row < self.selectedShipDates.count) {
                CIShipDateTableViewCell *shipDateTableViewCell = (CIShipDateTableViewCell *) [self.tableView dequeueReusableCellWithIdentifier:dateCellIdentifier forIndexPath:indexPath];
                cell = shipDateTableViewCell;
                NSDate *selectedDate = [self.selectedShipDates count] == 0 ? nil : self.selectedShipDates[(NSUInteger) indexPath.row];
                [shipDateTableViewCell prepareForDisplay:selectedDate selectedLineItems:self.selectedLineItems];

                __weak typeof(shipDateTableViewCell) weakCell = shipDateTableViewCell;
                __weak typeof(self) weakSelf = self;
                [shipDateTableViewCell.quantityField setBk_didBeginEditingBlock:^(UITextField *field) {
                    NSIndexPath *cellIndexPath = [weakSelf.tableView indexPathForCell:weakCell];
                    // we need to scroll up because any cells that are not visible won't be eligible for "next cell" tabbing
                    [weakSelf.tableView scrollToRowAtIndexPath:cellIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                }];
            } else {
                CIOrderTotalTableViewCell *orderTotalTableViewCell = (CIOrderTotalTableViewCell *) [self.tableView dequeueReusableCellWithIdentifier:orderTotalCellIdentifier forIndexPath:indexPath];
                cell = orderTotalTableViewCell;
                [orderTotalTableViewCell prepareForDisplay:self.selectedLineItems];
            }

            break;
        }
        case 3: {
            CIPriceOptionTableViewCell *priceOptionCell = (CIPriceOptionTableViewCell *) [self.tableView dequeueReusableCellWithIdentifier:priceOptionCellIdentifier forIndexPath:indexPath];
            cell = priceOptionCell;
            [((CIPriceOptionTableViewCell *) cell) prepareForDisplay:self.currentLineItem at:indexPath];

            break;
        }
        default: {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            break;
        }
    }

    return cell;
}

- (void)onLineTabbed:(NSNotification *)notification {
    CIShipDateTableViewCell *currentCell = (CIShipDateTableViewCell *) notification.object;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:currentCell];
    UITableViewCell *nextCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
    if (nextCell && [nextCell isKindOfClass:[CIShipDateTableViewCell class]]) {
        [((CIShipDateTableViewCell *) nextCell).quantityField becomeFirstResponder];
    } else {
        [currentCell.quantityField resignFirstResponder];
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