//
// Created by David Jafari on 2/13/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LineItem;


@interface CIPriceOptionTableViewCell : UITableViewCell <UITextFieldDelegate>

-(void)prepareForDisplay:(LineItem *)lineItem at:(NSIndexPath *)indexPath;

@end