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


@implementation CIProductViewControllerHelper {

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

- (BOOL)itemIsVoucher:(NSDictionary *)product {
    int idx = [[product objectForKey:kProductIdx] intValue];
    NSString *invtId = [product objectForKey:kProductInvtid];
    return idx == 0 && ([invtId isEmpty] || [invtId isEqualToString:@"0"]);
}

- (void)updateCellBackground:(UITableViewCell *)cell product:(NSDictionary *)product
         editableItemDetails:(NSDictionary *)editableItemDetails multiStore:(BOOL)multiStore {
    if ([ShowConfigurations instance].shipDates) {
        BOOL hasQty = [self itemHasQuantity:multiStore quantity:(NSString *) [editableItemDetails objectForKey:kEditableQty]];
        if (!hasQty) {cell.backgroundView = nil;}
        NSArray *shipDates = [editableItemDetails objectForKey:kLineItemShipDates];
        BOOL hasShipDates = shipDates && [shipDates count] > 0;
        BOOL isVoucher = [self itemIsVoucher:product];
        if (!isVoucher) {
            if (hasQty && (hasShipDates || ([[ShowConfigurations instance] shipDates] == NO))) {
                UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
                cell.backgroundView = view;
            } else if (hasQty ^ hasShipDates) {
                UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                view.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
                cell.backgroundView = view;
            }
        } else {
            if (hasQty) {
                UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
                cell.backgroundView = view;
            }
        }
    } else {
        BOOL hasQty = [self itemHasQuantity:multiStore quantity:[editableItemDetails objectForKey:kEditableQty]];
        if (hasQty) {
            UIView *view = [[UIView alloc] initWithFrame:cell.frame];
            view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
            cell.backgroundView = view;
        } else {
            cell.backgroundView = nil;
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
@end