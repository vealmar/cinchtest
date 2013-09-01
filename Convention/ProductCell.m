//
// Created by septerr on 8/19/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ProductCell.h"
#import "config.h"
#import "JSONKit.h"


@implementation ProductCell {

}
- (void)updateCellBackground:(NSDictionary *)product item:(NSDictionary *)item multiStore:(BOOL)multiStore showShipDates:(BOOL)showShipDates {
    BOOL hasQty = NO;
    if (multiStore && item != nil && [[item objectForKey:kEditableQty] isKindOfClass:[NSString class]]
            && [[[item objectForKey:kEditableQty] objectFromJSONString] isKindOfClass:[NSDictionary class]]
            && ((NSDictionary *) [[item objectForKey:kEditableQty] objectFromJSONString]).allKeys.count > 0) {
        for (NSNumber *n in [[[item objectForKey:kEditableQty] objectFromJSONString] allObjects]) {
            if ([n intValue] > 0) {
                hasQty = YES;
                break;
            }
        }
    } else if (item != nil && [item objectForKey:kEditableQty] && [[item objectForKey:kEditableQty] isKindOfClass:[NSString class]]
            && [[item objectForKey:kEditableQty] integerValue] > 0) {
        hasQty = YES;
    } else if (item != nil && [item objectForKey:kEditableQty] && [[item objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]
            && [[item objectForKey:kEditableQty] intValue] > 0) {
        hasQty = YES;
    } else {
        self.backgroundView = nil;
    }
    BOOL hasShipDates = NO;
    NSArray *shipDates = [item objectForKey:kLineItemShipDates];
    if (shipDates != nil && [shipDates count] > 0) {
        hasShipDates = YES;
    }
    NSNumber *zero = [NSNumber numberWithInt:0];
    BOOL isVoucher = [[product objectForKey:kProductIdx] isEqualToNumber:zero]
            && [[product objectForKey:kProductInvtid] isEqualToString:[zero stringValue]];
    if (!isVoucher) {
        if (hasQty && (hasShipDates || (showShipDates == NO))) {
            UIView *view = [[UIView alloc] initWithFrame:self.frame];
            view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
            self.backgroundView = view;
        } else if (hasQty ^ hasShipDates) {
            UIView *view = [[UIView alloc] initWithFrame:self.frame];
            view.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
            self.backgroundView = view;
        }
    }
}
@end