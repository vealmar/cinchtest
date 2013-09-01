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


@implementation CIProductViewControllerHelper {

}

- (BOOL)itemHasQuantity:(BOOL)multiStore lineItem:(NSDictionary *)linetItem {
    NSInteger num = 0;
    if (!multiStore) {
        num = [[linetItem objectForKey:kEditableQty] integerValue];
    } else {
        NSMutableDictionary *qty = [[linetItem objectForKey:kEditableQty] objectFromJSONString];
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

- (NSArray *)getItemShipDatesToSendToServer:(NSDictionary *)lineItem {
    NSMutableArray *strs = [NSMutableArray array];
    NSArray *dates = [lineItem objectForKey:kLineItemShipDates];
    if ([dates count] > 0) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        for (int i = 0; i < dates.count; i++) {
            NSString *str = [df stringFromDate:[dates objectAtIndex:i]];
            [strs addObject:str];
        }
    }
    return strs;
}

- (BOOL)itemIsVoucher:(NSDictionary *)product {
    int idx = [[product objectForKey:kProductIdx] intValue];
    NSString *invtId = [product objectForKey:kProductInvtid];
    return idx == 0 && ([invtId isEmpty] || [invtId isEqualToString:@"0"]);
}
@end