//
//  CIProductCell.m
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIProductCell.h"
#import "StringManipulation.h"

@interface CIProductCell (){
    NSString* oldPrice;
    NSString* oldVoucher;
    NSString* originalCellValue;
}

@end

@implementation CIProductCell
@synthesize regPrc;
@synthesize quantity;
@synthesize qtyLbl;
@synthesize price;
@synthesize voucherLbl;
@synthesize voucher;
@synthesize priceLbl;
@synthesize ridx;
@synthesize InvtID;
@synthesize descr;
@synthesize PartNbr;
@synthesize Uom;
@synthesize CaseQty;
@synthesize DirShip;
@synthesize LineNbr;
@synthesize New;
@synthesize Adv;
//@synthesize cartBtn;
@synthesize qtyBtn;
@synthesize delegate;
@synthesize hyphenBetweenShipDates;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        DLog(@"is called?");
        oldPrice = @"";
        oldVoucher = @"";
    }
    return self;
}


- (IBAction)voucherDidChange:(id)sender {
    if ([oldVoucher isEqualToString:self.voucher.text]) {
        return;
    }
    double dprice = [self.voucher.text doubleValue];
    //    self.price.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:dprice] numberStyle:NSNumberFormatterCurrencyStyle];
    self.voucherLbl.text = self.voucher.text;
    oldVoucher = self.voucher.text;
    if (self.delegate) {
        [self.delegate VoucherChange:dprice forIndex:self.tag];
//        DLog(@"vframe:%@",NSStringFromCGRect(self.frame));
    }
}

- (IBAction)priceDidChange:(id)sender {
    if ([oldPrice isEqualToString:self.price.text]) {
        return;
    }
    double dprice = [self.price.text doubleValue];
//    self.price.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:dprice] numberStyle:NSNumberFormatterCurrencyStyle];
    self.priceLbl.text = self.price.text;
    oldPrice = self.price.text;
    if (self.delegate) {
        [self.delegate PriceChange:dprice forIndex:self.tag];
//        DLog(@"pframe:%@",NSStringFromCGRect(self.frame));
    }
}

- (IBAction)voucherDidEnd:(id)sender {
    DLog(@"trigger end");
    double dprice = [self.voucher.text doubleValue];
    
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    nf.formatterBehavior = NSNumberFormatterBehavior10_4;
    nf.maximumFractionDigits = 2;
    nf.minimumFractionDigits = 2;
    nf.minimumIntegerDigits = 1;
    self.voucher.text = [nf stringFromNumber:[NSNumber numberWithDouble:dprice]];
    self.voucherLbl.text = self.voucher.text;
    oldVoucher = self.voucher.text;
    if (self.delegate) {
        [self.delegate VoucherChange:dprice forIndex:self.tag];
//        DLog(@"pframe:%@",NSStringFromCGRect(self.frame));
    }
}


- (IBAction)priceDidEnd:(id)sender {
    DLog(@"trigger end");
    double dprice = [self.price.text doubleValue];
    
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    nf.formatterBehavior = NSNumberFormatterBehavior10_4;
    nf.maximumFractionDigits = 2;
    nf.minimumFractionDigits = 2;
    nf.minimumIntegerDigits = 1;
    self.price.text = [nf stringFromNumber:[NSNumber numberWithDouble:dprice]];
    self.priceLbl.text = self.price.text;
    oldPrice = self.price.text;
    if (self.delegate) {
        [self.delegate PriceChange:dprice forIndex:self.tag];
//        DLog(@"pframe:%@",NSStringFromCGRect(self.frame));
    }
}

- (IBAction)qtyDidEnd:(id)sender {
    self.qtyLbl.text = self.quantity.text;
    if (self.delegate) {
        [self.delegate QtyChange:[self.quantity.text doubleValue] forIndex:self.tag];
    }
//    DLog(@"qframe:%@",NSStringFromCGRect(self.frame));
}

- (IBAction)addToCart:(id)sender {
    if (self.delegate) {
        [self.delegate AddToCartForIndex:self.tag];
    }
}

- (IBAction)qtyTouch:(id)sender {
    if (self.delegate) {
        [self.delegate QtyTouchForIndex:self.tag];
    }
}

- (IBAction)qtyChanged:(id)sender {
    self.qtyLbl.text = self.quantity.text;
    if (self.delegate) {
        [self.delegate QtyChange:[self.quantity.text doubleValue] forIndex:self.tag];
    }
}

- (id)init
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    originalCellValue = [NSString stringWithString:textField.text];
    UITableView * tableView = (UITableView *)self.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:self];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
//    DLog(@"textFieldDidEndEditing");
//    if (self.delegate) {
////        DLog(@"end frame:%@",NSStringFromCGRect(self.frame));
//        [self.delegate textEditEndWithFrame:self.frame];
//    }
    if ([textField.text isEmpty]) {
        textField.text = originalCellValue;
    }
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
}

@end
