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
#import "Order.h"
#import "NilUtil.h"
#import "Cart+Extensions.h"


@implementation CIProductViewControllerHelper {

}

- (int)getQuantity:(NSString *)quantity {
    if ([[quantity stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] startsWith:@"{"]) {
        int qty = 0;
        NSDictionary *quantitiesByStore = [quantity objectFromJSONString];
        for (NSString *storeId in [quantitiesByStore allKeys]) {
            qty += [[quantitiesByStore objectForKey:storeId] intValue];
        }
        return qty;
    }
    else {
        return [quantity intValue];
    }
}

- (BOOL)itemHasQuantity:(BOOL)multiStore quantity:(NSString *)quantity {
    NSInteger num = 0;
    if (!multiStore) {
        num = [quantity integerValue];
    } else {
        NSMutableDictionary *qty = [quantity objectFromJSONString];
        for (NSString *n in qty.allKeys) {
            int j = [[qty objectForKey:n] intValue];
            if (j > num) {
                num = j;
                if (num > 0) {
                    break;
                }
            }
        }
    }
    return num > 0;
}

- (BOOL)itemHasQuantity:(NSString *)quantity {
    if (quantity) {
        BOOL isMultiSTore = ([[quantity stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] startsWith:@"{"]);
        return [self itemHasQuantity:isMultiSTore quantity:quantity];
    } else
        return NO;
}

- (BOOL)itemIsVoucher:(NSDictionary *)product {
    int idx = [[product objectForKey:kProductIdx] intValue];
    NSString *invtId = [product objectForKey:kProductInvtid];
    return idx == 0 && ([invtId isEmpty] || [invtId isEqualToString:@"0"]);
}

- (void)updateCellBackground:(UITableViewCell *)cell product:(NSDictionary *)product
                        cart:(Cart *)cart {
    if ([ShowConfigurations instance].shipDates) {
        BOOL hasQty = [self itemHasQuantity:cart.editableQty];
        BOOL hasShipDates = cart.shipdates && cart.shipdates.count > 0;
        BOOL isVoucher = [self itemIsVoucher:product];
        if (!isVoucher) {
            if (hasQty) {
                if (hasShipDates) {
                    cell.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
                } else {
                    cell.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
                }
            } else {
                cell.backgroundColor = [UIColor whiteColor];
            }
        } else {
            if (hasQty) {
                cell.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
            } else {
                cell.backgroundColor = [UIColor whiteColor];
            }
        }
    } else {
        BOOL hasQty = [self itemHasQuantity:cart.editableQty];
        if (hasQty) {
            cell.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (UITableViewCell *)dequeueReusableProductCell:(UITableView *)table {
    NSString *CellIdentifier = [kShowCorp isEqualToString:kPigglyWiggly] ? @"PWProductCell" : @"FarrisProductCell";
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
    return cell;
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

- (NSDictionary *)prepareJsonRequestParameterFromOrder:(Order *)coreDataOrder {
    NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:coreDataOrder.carts.count];
    for (Cart *cart in coreDataOrder.carts) {
        BOOL hasQuantity = [self itemHasQuantity:cart.editableQty];
        NSDictionary *proDict;
        if (hasQuantity) { //only include items that have non-zero quantity specified
            proDict = [NSDictionary dictionaryWithObjectsAndKeys:[cart.orderLineItem_id intValue] == 0 ? [NSNull null] : cart.orderLineItem_id, kID,
                                                                 cart.cartId, kLineItemProductID,
                                                                 [NilUtil objectOrNNull:cart.editableQty], kLineItemQuantity,
                                                                 @([cart.editablePrice intValue] / 100.0), kLineItemPrice,
                                                                 @([cart.editableVoucher intValue] / 100.0), kLineItemVoucherPrice,
                                                                 [ShowConfigurations instance].shipDates ? cart.shipDatesAsStringArray : @[], kLineItemShipDates,

                                                                 nil];
        } else if ([cart.orderLineItem_id intValue] != 0) { //if quantity is 0 and item exists on server, tell server to destroy it. if it does not exist on server, don't include it.
            proDict = [NSDictionary dictionaryWithObjectsAndKeys:cart.orderLineItem_id, kID, @(1), @"_destroy", nil];
        }
        if (proDict) [arr addObject:(id) proDict];
    }
    NSMutableDictionary *newOrder = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NilUtil objectOrNNull:coreDataOrder.customer_id], kOrderCustomerID,
                                                                                      [NilUtil objectOrNNull:coreDataOrder.notes], kNotes,
                                                                                      [NilUtil objectOrNNull:coreDataOrder.ship_notes], kShipNotes,
                                                                                      [NilUtil objectOrNNull:coreDataOrder.authorized], kAuthorizedBy,
                                                                                      [coreDataOrder.ship_flag boolValue] ? @"TRUE" : @"FALSE", kShipFlag,
                                                                                      [NilUtil objectOrNNull:coreDataOrder.status], kOrderStatus,
                                                                                      arr, kOrderItems,
                                                                                      [coreDataOrder.print boolValue] ? @"TRUE" : @"FALSE", kOrderPrint,
                                                                                      [NilUtil objectOrNNull:coreDataOrder.printer], kOrderPrinter , nil];
    return [NSDictionary dictionaryWithObjectsAndKeys:newOrder, kOrder, nil];
}


@end