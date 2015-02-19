//
// Created by David Jafari on 1/26/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIOrderDetailTableViewController.h"
#import "CITableViewColumns.h"
#import "ShowConfigurations.h"
#import "CITableViewColumn.h"
#import "LineItem.h"
#import "LineItem+Extensions.h"
#import "Order.h"
#import "OrderSubtotalsByDate.h"
#import "NumberUtil.h"
#import "OrderTotals.h"
#import "Order+Extensions.h"

//@todo set header styles?

@interface CIOrderDetailTableViewController ()

@property NSArray *currentLineItems; //NSArray[LineItem]
@property NSMutableArray *subtotalLines;

@end

@implementation CIOrderDetailTableViewController

@synthesize currentOrder = _currentOrder;

static NSString *SUBTOTAL_CELL_REUSE_KEY = @"SUBTOTAL_CELL_REUSE_KEY";

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.subtotalLines = [NSMutableArray array];
        self.currentLineItems = [NSArray array];
        self.tableView.separatorColor = [UIColor colorWithRed:0.808 green:0.808 blue:0.827 alpha:1];
    }

    return self;
}

- (void)setCurrentOrder:(Order *)currentOrder {
    _currentOrder = currentOrder;
    if (currentOrder) {
        NSArray *lineItemsArray = _currentOrder.lineItems.allObjects;
        self.currentLineItems = [lineItemsArray sortedArrayUsingDescriptors:@[
                [[NSSortDescriptor alloc] initWithKey:@"category" ascending:NO],
                [[NSSortDescriptor alloc] initWithKey:@"product.sequence" ascending:YES],
                [[NSSortDescriptor alloc] initWithKey:@"product.invtid" ascending:YES]
        ]];
    } else {
        self.currentLineItems = nil;
    }

    [self calculateSubtotalLines];
    [self.tableView reloadData];
    if (self.tableView.numberOfSections && [self.tableView numberOfRowsInSection:0]) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (Order*)currentOrder {
    return _currentOrder;
}

- (void)calculateSubtotalLines {
    [self.subtotalLines removeAllObjects];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    OrderSubtotalsByDate *shipDateSubtotals = self.currentOrder.calculateShipDateSubtotals;
    [shipDateSubtotals each:^(NSDate *shipDate, NSNumber *totalOnShipDate) {
        [self.subtotalLines addObject:@[
                [NSString stringWithFormat:@"Shipping on %@", [dateFormatter stringFromDate:shipDate]],
                [NumberUtil formatDollarAmount:totalOnShipDate]
        ]];
    }];

    OrderTotals *totals = self.currentOrder.calculateTotals;
    if (shipDateSubtotals.hasSubtotals || [totals.discountTotal doubleValue] != 0) {
        [self.subtotalLines addObject:@[@"Subtotal", [NumberUtil formatDollarAmount:totals.grossTotal]]];
    }
    if ([totals.discountTotal doubleValue] != 0) {
        [self.subtotalLines addObject:@[@"Discount", [NumberUtil formatDollarAmount:totals.discountTotal]]];
    }
    [self.subtotalLines addObject:@[@"TOTAL", [NumberUtil formatDollarAmount:totals.total]]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [self.tableView setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (CITableViewColumns *)createColumns {
    CITableViewColumns *columns = [[CITableViewColumns alloc] init];

    [columns add:ColumnTypeString titled:@"ITEM" using:@{
            ColumnOptionContentKey: @"label",
            ColumnOptionDesiredWidth: @100,
            ColumnOptionHorizontalPadding: @7,
            ColumnOptionHorizontalInset: @8,
            ColumnOptionTitleTextAttributes: @{ NSForegroundColorAttributeName: [UIColor whiteColor] }
    }];
    [columns add:ColumnTypeString titled:@"DESCRIPTION" using:@{
            ColumnOptionContentKey: @"description1",
            ColumnOptionContentKey2: @"description2",
            ColumnOptionLineBreakMode: @(NSLineBreakByTruncatingTail),
            ColumnOptionTitleTextAttributes: @{ NSForegroundColorAttributeName: [UIColor whiteColor] }
    }];

    if ([ShowConfigurations instance].isLineItemShipDatesType) {
        [columns add:ColumnTypeInt titled:@"SD" using:@{
                ColumnOptionContentKey : @"shipDatesCount",
                ColumnOptionTextAlignment : @(NSTextAlignmentRight),
                ColumnOptionDesiredWidth : @60,
                ColumnOptionHorizontalPadding : @7,
                ColumnOptionTitleTextAttributes: @{ NSForegroundColorAttributeName: [UIColor whiteColor] }
        }];
    }

    [columns add:ColumnTypeInt titled:@"SQ" using:@{
            ColumnOptionContentKey: @"totalQuantityNumber",
            ColumnOptionTextAlignment: @(NSTextAlignmentRight),
            ColumnOptionDesiredWidth: @55,
            ColumnOptionHorizontalPadding: @7,
            ColumnOptionTitleTextAttributes: @{ NSForegroundColorAttributeName: [UIColor whiteColor] }
    }];

    [columns add:ColumnTypeCurrency titled:@"PRICE" using:@{
            ColumnOptionContentKey: @"price",
            ColumnOptionTextAlignment: @(NSTextAlignmentRight),
            ColumnOptionDesiredWidth: @80,
            ColumnOptionHorizontalPadding: @7,
            ColumnOptionTitleTextAttributes: @{ NSForegroundColorAttributeName: [UIColor whiteColor] }
    }];

    [columns add:ColumnTypeCurrency titled:@"TOTAL" using:@{
            ColumnOptionContentKey: @"subtotalNumber",
            ColumnOptionTextAlignment: @(NSTextAlignmentRight),
            ColumnOptionDesiredWidth: @90,
            ColumnOptionHorizontalPadding: @7,
            ColumnOptionHorizontalInset: @0,
            ColumnOptionTitleTextAttributes: @{ NSForegroundColorAttributeName: [UIColor whiteColor] }
    }];

    return columns;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    int subtotalIndex = indexPath.row - self.currentLineItems.count - 1;
    if (indexPath.row < self.currentLineItems.count) {
        return self.currentLineItems[indexPath.row];
    } else if (subtotalIndex > 0 && subtotalIndex < self.subtotalLines.count) {
        return self.subtotalLines[subtotalIndex];
    } else {
        return nil;
    }
}

# pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int rows = self.currentOrder && self.currentLineItems ? self.currentLineItems.count : 0;
    if (rows) {
        rows += 1 + self.subtotalLines.count;
    }
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int rows = self.currentOrder && self.currentOrder.lineItems ? self.currentOrder.lineItems.count : 0;
    if (indexPath.row > rows) {
        int index = indexPath.row - rows - 1;

        UILabel *cleftLabel = nil;
        UILabel *crightLabel = nil;

        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:SUBTOTAL_CELL_REUSE_KEY];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SUBTOTAL_CELL_REUSE_KEY];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            cleftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, 482 + 89, 40)];
            cleftLabel.tag = 1001;
            cleftLabel.backgroundColor = [UIColor clearColor];
            cleftLabel.font = [UIFont regularFontOfSize:14];
            cleftLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            cleftLabel.numberOfLines = 0;
            cleftLabel.textAlignment = NSTextAlignmentRight;
            [cell.contentView addSubview:cleftLabel];

            crightLabel = [[UILabel alloc] initWithFrame:CGRectMake(577, 5, 80, 40)];
            crightLabel.tag = 1002;
            crightLabel.backgroundColor = [UIColor clearColor];
            crightLabel.font = [UIFont semiboldFontOfSize:14];
            crightLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
            crightLabel.numberOfLines = 0;
            crightLabel.textAlignment = NSTextAlignmentRight;
            crightLabel.numberOfLines = 1;
            crightLabel.adjustsFontSizeToFitWidth = YES;
            [cell.contentView addSubview:crightLabel];
        } else {
            cleftLabel = (UILabel*)[cell.contentView viewWithTag:1001];
            crightLabel = (UILabel*)[cell.contentView viewWithTag:1002];
        }

        if (index >= 0) {
            NSArray *subtotalLine = self.subtotalLines[index];
            cleftLabel.text = subtotalLine[0];
            crightLabel.text = subtotalLine[1];
        } else {
            cleftLabel.text = @"";
            crightLabel.text = @"";
        }

        return cell;
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

# pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    int rowCount = self.currentOrder && self.currentLineItems ? self.currentLineItems.count : 0;
    if (indexPath.row > rowCount) {
        cell.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1];
    } else if (self.currentLineItems && indexPath.row < self.currentLineItems.count && ((LineItem *) self.currentLineItems[indexPath.row]).isDiscount) {
        cell.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:224.0f/255.0f alpha:1];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

@end