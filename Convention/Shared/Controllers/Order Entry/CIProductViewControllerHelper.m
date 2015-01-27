//
// Created by septerr on 8/28/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "CIProductViewControllerHelper.h"
#import "config.h"
#import "JSONKit.h"
#import "StringManipulation.h"
#import "ShowConfigurations.h"
#import "SettingsManager.h"
#import "MBProgressHUD.h"
#import "Product.h"
#import "Product+Extensions.h"
#import "LineItem.h"
#import "NilUtil.h"
#import "CoreDataUtil.h"
#import "Vendor.h"
#import "AFURLConnectionOperation.h"
#import "CinchJSONAPIClient.h"
#import "Order.h"
#import "LineItem+Extensions.h"

@implementation CIProductViewControllerHelper {

}

+ (BOOL)itemIsVoucher:(Product *)product {
    int idx = [product.idx intValue];
    NSString *invtId = product.invtid;
    return idx == 0 && ([invtId isEmpty] || [invtId isEqualToString:@"0"]);
}

- (void)updateCellBackground:(UITableViewCell *)cell order:(Order *)order lineItem:(LineItem *)lineItem {
    UIColor *green = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
    UIColor *red = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
    if ([ShowConfigurations instance].shipDatesRequired) {
        if ([ShowConfigurations instance].isOrderShipDatesType) {
            if (lineItem.totalQuantity > 0) {
                if (order && order.shipDates.count > 0) cell.backgroundColor = green;
                else cell.backgroundColor = red;
            } else {
                cell.backgroundColor = [UIColor whiteColor];
            }
        } else if ([ShowConfigurations instance].isLineItemShipDatesType) {
            BOOL hasQty = lineItem.totalQuantity > 0;
            BOOL hasShipDates = lineItem.shipDates && lineItem.shipDates.count > 0;
            BOOL isVoucher = [CIProductViewControllerHelper itemIsVoucher:lineItem.product];
            if (!isVoucher) {
                if (hasQty) {
                    if (hasShipDates) {
                        cell.backgroundColor = green;
                    } else {
                        cell.backgroundColor = red;
                    }
                } else {
                    cell.backgroundColor = [UIColor whiteColor];
                }
            } else {
                if (hasQty) {
                    cell.backgroundColor = green;
                } else {
                    cell.backgroundColor = [UIColor whiteColor];
                }
            }
        }
    } else {
        BOOL hasQty = lineItem.totalQuantity > 0;
        if (hasQty) {
            cell.backgroundColor = green;
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (UITableViewCell *)dequeueReusableCartViewCell:(UITableView *)table {
    NSString *CellIdentifier = [kShowCorp isEqualToString:kPigglyWiggly] ? @"PWCartViewCell" : @"FarrisCartViewCell";
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
    return cell;
}

- (BOOL)isOrderReadyForSubmission:(Order *)order {
    //check there are items in cart
    if (order.lineItems.count == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Please add at least one product to the cart before continuing." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return NO;
    }

    BOOL hasQuantity = NO;
    for (LineItem *newLineItem in order.lineItems) {
        if (newLineItem.totalQuantity > 0) {
            hasQuantity = YES;
            break;
        }
    }

    if (!hasQuantity) {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Please add at least one product to the cart before continuing." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return NO;
    }

    //if using ship dates, all items with non-zero quantity (except vouchers) should have ship date(s)
    if ([ShowConfigurations instance].shipDatesRequired) {
        if ([[ShowConfigurations instance] isOrderShipDatesType]) {
            if (order.shipDates.count == 0) {
                [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:@"You must select at least one ship date for this order before submitting." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                return NO;
            }
        } else if ([[ShowConfigurations instance] isLineItemShipDatesType]) {
            for (LineItem *lineItem in order.lineItems) {
                Product *product = [Product findProduct:lineItem.productId];
                BOOL hasQty = lineItem.totalQuantity > 0;
                if (hasQty && !lineItem.isDiscount && ![CIProductViewControllerHelper itemIsVoucher:product]) {
                    BOOL hasShipDates = [NilUtil objectOrEmptyArray:lineItem.shipDates].count > 0;
                    if (!hasShipDates) {
                        [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:@"All items in the cart must have ship date(s) before the order can be submitted. Check cart items and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                        return NO;
                    }
                }
            }
        }
    }
    return YES;
}

- (NSArray *)sortProductsBySequenceAndInvtId:(NSArray *)productIdsOrProducts {
    NSArray *sortedArray;
    sortedArray = [productIdsOrProducts sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        Product *product1 = [a isKindOfClass:[Product class]] ? a : [Product findProduct:a];
        Product *product2 = [b isKindOfClass:[Product class]] ? b : [Product findProduct:b];

        NSNumber *firstSequence = (NSNumber *) [NilUtil nilOrObject:product1.sequence];
        NSNumber *secondSequence = (NSNumber *) [NilUtil nilOrObject:product2.sequence];

        if (firstSequence && ![firstSequence isEqualToNumber:@(0)] && secondSequence && ![secondSequence isEqualToNumber:@(0)] && ![firstSequence isEqual:secondSequence]) {
            return [firstSequence compare:secondSequence];
        } else if (![firstSequence isEqualToNumber:@(0)]) {
            return NSOrderedAscending;
        } else if (![secondSequence isEqualToNumber:@(0)]) {
            return NSOrderedDescending;
        } else {
            NSString *firstInvtid = (NSString *) [NilUtil nilOrObject:product1.invtid];
            NSString *secondInvtid = (NSString *) [NilUtil nilOrObject:product2.invtid];
            return [firstInvtid compare:secondInvtid];
        }
    }];
    return sortedArray;
}

- (NSArray *)sortDiscountsByLineItemId:(NSArray *)lineItemIds {
    NSArray *sortedArray;
    sortedArray = [lineItemIds sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *first = (NSNumber *) a;
        NSNumber *second = (NSNumber *) b;
        return [first compare:second];
    }];
    return sortedArray;
}

- (NSString *)displayNameForVendor:(NSNumber *)vendorId {
    Vendor *vendor = (Vendor *) [[CoreDataUtil sharedManager] fetchObject:@"Vendor" withPredicate:[NSPredicate predicateWithFormat:@"(vendorId == %@)", vendorId]];
    NSString *vendId = [NilUtil objectOrDefaultString:vendor.vendid defaultObject:@""];
    NSString *vendorName = [NilUtil objectOrDefaultString:vendor.name defaultObject:@""];
    return vendorName.length > 0 ? [NSString stringWithFormat:@"%@ - %@", vendId, vendorName] : vendorName;
}

@end