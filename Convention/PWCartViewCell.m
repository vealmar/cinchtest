//
// Created by septerr on 9/2/13.
// Copyright (c) 2013 Convention Innovations. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "PWCartViewCell.h"
#import "ProductCellDelegate.h"
#import "NumberUtil.h"
#import "Product.h"
#import "NilUtil.h"


@implementation PWCartViewCell {
    NSString *oldVoucher;
}
@synthesize numShipDates;
@synthesize qtyLbl;
@synthesize voucher;
@synthesize priceLbl;
@synthesize descr;
@synthesize shipDate1;
@synthesize shipDate2;
@synthesize CaseQty;
@synthesize qtyBtn;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        oldVoucher = @"";
    }
    return self;
}

- (void)initializeWith:(BOOL)multiStore showPrice:(BOOL)showPrice product:(Product *)product tag:(NSInteger)tag
              quantity:(NSString *)quantity
                 price:(NSNumber *)price
               voucher:(NSNumber *)voucherPrice
             shipDates:(int)numOfShipDates
   productCellDelegate:(id <ProductCellDelegate>)productCellDelegate {
    self.InvtID.text = product.invtid;
    self.descr.text = product.descr;
    if (product.shipdate1) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        self.shipDate1.text = [df stringFromDate:product.shipdate1];
    } else {
        self.shipDate1.text = @"";
    }
    if (product.shipdate2) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        self.shipDate2.text = [df stringFromDate:product.shipdate2];
    } else {
        self.shipDate2.text = @"";
    }
    self.numShipDates.text = [NSString stringWithFormat:@"%d", numOfShipDates];
    self.CaseQty.text = [NilUtil objectOrDefaultString:product.caseqty defaultObject:@""];

    self.qtyLbl.text = quantity;
    self.qtyLbl.hidden = multiStore;
    self.qtyBtn.hidden = !multiStore;

    self.voucher.text = voucherPrice ? [NumberUtil formatDollarAmount:voucherPrice] : @"0.00"; //todo: is the check needed?

    if (showPrice) {
        self.priceLbl.text = [NumberUtil formatDollarAmount:price];
    }
    self.delegate = productCellDelegate;
    self.tag = tag;
}


- (IBAction)qtyTouch:(id)sender {
    if (self.delegate) {
        [self.delegate QtyTouchForIndex:self.tag];
    }
}

- (IBAction)voucherDidChange:(id)sender {
    if ([oldVoucher isEqualToString:self.voucher.text]) {
        return;
    }
    double dprice = [self.voucher.text doubleValue];
    oldVoucher = self.voucher.text;
    if (self.delegate) {
        [self.delegate VoucherChange:dprice forIndex:self.tag];
    }
}
@end