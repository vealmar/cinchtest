//
//  PWProductCell.m
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "PWProductCell.h"
#import "StringManipulation.h"
#import "config.h"

@interface PWProductCell (){
    NSString* oldPrice;
    NSString* oldVoucher;
    NSString* originalCellValue;
}

@end

@implementation PWProductCell
@synthesize quantity;
@synthesize qtyLbl;
@synthesize price;
@synthesize voucherLbl;
@synthesize voucher;
@synthesize priceLbl;
@synthesize InvtID;
@synthesize descr;
@synthesize shipDate1, shipDate2;
@synthesize CaseQty;
@synthesize qtyBtn;
@synthesize delegate;
@synthesize numShipDates;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        oldPrice = @"";
        oldVoucher = @"";
    }
    return self;
}

- (void) initializeWith:(NSDictionary *)customer multiStore:(BOOL)multiStore showPrice:(BOOL)showPrice product:(NSDictionary *)product
                 item:(NSDictionary *)item checkmarked:(BOOL)checkmarked tag:(NSInteger) tag
  ProductCellDelegate:(id <ProductCellDelegate>)productCellDelegate{
    self.InvtID.text = [product objectForKey:@"invtid"];
    self.descr.text = [product objectForKey:@"descr"];
    if ([product objectForKey:kProductShipDate1] != nil && ![[product objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]){
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        NSDate* date = [df dateFromString:[product objectForKey:kProductShipDate1]];
        [df setDateFormat:@"yyyy-MM-dd"];
        self.shipDate1.text = [df stringFromDate:date];
    }else {
        self.shipDate1.text = @"";
    }
    if ([product objectForKey:kProductShipDate2] != nil && ![[product objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]){
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        NSDate* date = [df dateFromString:[product objectForKey:kProductShipDate2]];
        [df setDateFormat:@"yyyy-MM-dd"];
        self.shipDate2.text = [df stringFromDate:date];
    }else {
        self.shipDate2.text = @"";
    }

    self.numShipDates.text = ([[item objectForKey:kOrderItemShipDates] isKindOfClass:[NSArray class]]
            ? [NSString stringWithFormat:@"%d",((NSArray*)[item objectForKey:kOrderItemShipDates]).count]:@"0");
    if (!multiStore && item != nil && [item objectForKey:kEditableQty] != nil) {
        self.quantity.text = [[item objectForKey:kEditableQty] stringValue];
    }
    else
        self.quantity.text = @"0";

    if ([product objectForKey:@"caseqty"] != nil && ![[product objectForKey:@"caseqty"] isKindOfClass:[NSNull class]])
        self.CaseQty.text = [product objectForKey:@"caseqty"];
    else
        self.CaseQty.text = @"";
    if ([[customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray*)[customer objectForKey:kStores]) count] > 0) {
        self.qtyBtn.hidden = NO;
        self.qtyLbl.hidden = YES;
        self.quantity.hidden = YES;
    }
    if (item != nil && [item objectForKey:kEditableVoucher] != nil) {
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        nf.formatterBehavior = NSNumberFormatterBehavior10_4;
        nf.maximumFractionDigits = 2;
        nf.minimumFractionDigits = 2;
        nf.minimumIntegerDigits = 1;

        self.voucher.text = [nf stringFromNumber:[item objectForKey:kEditableVoucher]];
        self.voucherLbl.text = self.voucher.text;
        self.voucher.hidden = YES;//PW changes!
    }else if ([product objectForKey:kProductVoucher] != nil){
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        nf.formatterBehavior = NSNumberFormatterBehavior10_4;
        nf.maximumFractionDigits = 2;
        nf.minimumFractionDigits = 2;
        nf.minimumIntegerDigits = 1;

        self.voucher.text = [nf stringFromNumber:[NSNumber numberWithDouble:[[product objectForKey:kProductVoucher] doubleValue]]];
        self.voucherLbl.text = self.voucher.text;
        self.voucher.hidden = YES;//PW changes!
    }else{
        self.voucher.text = @"0.00";
        self.voucherLbl.text = self.voucher.text;
        self.voucher.hidden = YES;//PW changes!
    }

    if (showPrice && item != nil && [item objectForKey:kEditablePrice] != nil) {
        //            self.price.text = [[self.productPrices objectForKey:[product objectForKey:@"id"]] stringValue];
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        nf.formatterBehavior = NSNumberFormatterBehavior10_4;
        nf.maximumFractionDigits = 2;
        nf.minimumFractionDigits = 2;
        nf.minimumIntegerDigits = 1;

        self.price.text = [nf stringFromNumber:[item objectForKey:kEditablePrice]];
        self.priceLbl.text = self.price.text;
        self.price.hidden = YES;
}  else if ([product objectForKey:kProductShowPrice] != nil) {
        NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
        nf.formatterBehavior = NSNumberFormatterBehavior10_4;
        nf.maximumFractionDigits = 2;
        nf.minimumFractionDigits = 2;
        nf.minimumIntegerDigits = 1;

        self.price.text = [nf stringFromNumber:[NSNumber numberWithDouble:[[product objectForKey:kProductShowPrice] doubleValue]]];
        self.priceLbl.text = self.price.text;
        self.price.hidden = YES;//PW changes!
    }else{
        self.price.text = @"0.00";
        self.priceLbl.text = self.price.text;
        self.price.hidden = YES;//PW changes!
    }
    self.accessoryType = checkmarked? UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
    self.delegate = productCellDelegate;
    self.tag = tag;
}

- (IBAction)voucherDidChange:(id)sender {
    if ([oldVoucher isEqualToString:self.voucher.text]) {
        return;
    }
    double dprice = [self.voucher.text doubleValue];
    self.voucherLbl.text = self.voucher.text;
    oldVoucher = self.voucher.text;
    if (self.delegate) {
        [self.delegate VoucherChange:dprice forIndex:self.tag];
    }
}

- (IBAction)priceDidChange:(id)sender {
    if ([oldPrice isEqualToString:self.price.text]) {
        return;
    }
    double dprice = [self.price.text doubleValue];
    self.priceLbl.text = self.price.text;
    oldPrice = self.price.text;
    if (self.delegate) {
        [self.delegate PriceChange:dprice forIndex:self.tag];
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
    }
}

- (IBAction)qtyDidEnd:(id)sender {
    self.qtyLbl.text = self.quantity.text;
    if (self.delegate) {
        [self.delegate QtyChange:[self.quantity.text doubleValue] forIndex:self.tag];
    }
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
    if ([textField.text isEmpty]) {
        textField.text = originalCellValue;
    }
    if ([textField isFirstResponder])
        [textField resignFirstResponder];
}

@end
