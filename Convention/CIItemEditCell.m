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
//@synthesize lblQuantity;
@synthesize voucher;
//@synthesize lblPrice;
@synthesize qty;
@synthesize price;
@synthesize btnShipdates;
@synthesize total;
@synthesize delegate;
@synthesize qtyBtn;
@synthesize priceLbl;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
//        self.desc.font = [UIFont fontWithName:kFontName size:14.f];
//        self.lblQuantity.font = [UIFont fontWithName:kFontName size:14.f];
//        self.lblPrice.font = [UIFont fontWithName:kFontName size:14.f];
//        self.total.font = [UIFont fontWithName:kFontName size:14.f];
//        self.qty.font = [UIFont fontWithName:kFontName size:14.f];
//        self.price.font = [UIFont fontWithName:kFontName size:14.f];
//        self.priceLbl.font = [UIFont fontWithName:kFontName size:14.f];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)UpdateTotal {
//    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
//    [nf setNumberStyle:NSNumberFormatterCurrencyStyle];

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
//    [self UpdateTotal];
    if (self.delegate) {
        [self.delegate setVoucher:self.voucher.text atIndex:self.tag];
        [self.delegate UpdateTotal];
//        [self.delegate setViewMovedUpDouble:NO];
//        [self.delegate setViewMovedUpDouble:NO];
    }
}

- (IBAction)qtyEdit:(id)sender {
    [self UpdateTotal];
    if (self.delegate) {
        [self.delegate setQuantity:self.qty.text atIndex:self.tag];
        [self.delegate UpdateTotal];
//        [self.delegate setViewMovedUpDouble:NO];
//        [self.delegate setViewMovedUpDouble:NO];
    }
}

- (IBAction)priceEdit:(id)sender {
    self.priceLbl.text = self.price.text;
    [self UpdateTotal];
    if (self.delegate) {
        [self.delegate setPrice:self.price.text atIndex:self.tag];
        [self.delegate UpdateTotal];
//        [self.delegate setViewMovedUpDouble:NO];
//        [self.delegate setViewMovedUpDouble:NO];
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
//    if (self.delegate)
//        [self.delegate setActiveField:nil];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.delegate) {
        [self.delegate setActiveField:textField];
        [self.delegate setSelectedRow:self.tag];
    }


//    if (self.delegate)
//        [self.delegate setViewMovedUpDouble:YES];
}

- (void)setDescription:(NSString *)desc1 withSubtext:(NSString *)desc2 {
    if (desc2 == [NSNull null]) {
        self.desc.hidden = FALSE;
        self.desc1.hidden = TRUE;
        self.desc2.hidden = TRUE;
        self.desc.text = desc1;
    } else {
        self.desc.hidden = TRUE;
        self.desc1.hidden = FALSE;
        self.desc2.hidden = FALSE;
        self.desc1.text = desc1;
        self.desc2.text = desc2;
    }

}

@end
