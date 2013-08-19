//
// Created by septerr on 8/19/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface ProductCell :  UITableViewCell <UITextFieldDelegate>
- (void) updateCellBackground: (NSDictionary *)product item:(NSDictionary *)item multiStore:(BOOL)multiStore showShipDates:(BOOL)showShipDates;
@end