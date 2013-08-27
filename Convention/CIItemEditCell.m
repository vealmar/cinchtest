//
//  CIItemEditCell.m
//  Convention
//
//  Created by Matthew Clark on 12/9/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIItemEditCell.h"
#import "JSONKit.h"

@implementation CIItemEditCell
@synthesize desc;
@synthesize desc1;
@synthesize desc2;
@synthesize voucher;
@synthesize qty;
@synthesize price;
@synthesize btnShipdates;
@synthesize total;
@synthesize delegate;
@synthesize qtyBtn;
@synthesize priceLbl;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)UpdateTotal {
    __autoreleasing NSError *err = nil;
    NSMutableDictionary *dict = [self.qty.text objectFromJSONStringWithParseOptions:JKParseOptionNone error:&err];

    double q = 0;
    if (err) {
        q = [self.qty.text doubleValue];
    } else {
        for (NSString *key in dict.allKeys) {
            q += [[dict objectForKey:key] doubleValue];
        }
    }

    double p = [self.priceLbl.text doubleValue];

    self.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:(q * p)] numberStyle:NSNumberFormatterCurrencyStyle];
}

- (IBAction)voucherEdit:(id)sender {
    if (self.delegate) {
        [self.delegate setVoucher:self.voucher.text atIndex:self.tag];
        [self.delegate UpdateTotal];
    }
}

- (IBAction)qtyEdit:(id)sender {
    [self UpdateTotal];
    if (self.delegate) {
        [self.delegate setQuantity:self.qty.text atIndex:self.tag];
        [self.delegate UpdateTotal];
    }
}

- (IBAction)priceEdit:(id)sender {
    self.priceLbl.text = self.price.text;
    [self UpdateTotal];
    if (self.delegate) {
        [self.delegate setPrice:self.price.text atIndex:self.tag];
        [self.delegate UpdateTotal];
    }
}

- (IBAction)qtyTouch:(id)sender {
    if (self.delegate) {
        [self.delegate QtyTouchForIndex:self.tag];
    }
}

- (IBAction)shipdates:(id)sender {
    if (self.delegate) {
        [self.delegate ShipDatesTouchForIndex:self.tag];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.delegate) {
        [self.delegate setActiveField:textField];
        [self.delegate setSelectedRow:self.tag];
    }
}

- (void)setDescription:(NSString *)description1 withSubtext:(NSString *)description2 {
    if (description2 == nil) {
        self.desc.hidden = FALSE;
        self.desc1.hidden = TRUE;
        self.desc2.hidden = TRUE;
        self.desc.text = description1;
    } else {
        self.desc.hidden = TRUE;
        self.desc1.hidden = FALSE;
        self.desc2.hidden = FALSE;
        self.desc1.text = description1;
        self.desc2.text = description2;
    }

}

@end
