//
//  FarrisItemEditCell.m
//  Convention
//
//  Created by Kerry Sanders on 1/21/13.
//  Copyright (c) 2013 MotionMobs. All rights reserved.
//

#import "FarrisItemEditCell.h"

@implementation FarrisItemEditCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
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

-(void)UpdateTotal{
    //    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    //    [nf setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    double q = [self.qty.text intValue];
    double p = [self.price.text doubleValue];
    
    DLog(@"%f*%f should be %f",q,p,(q*p));
    
    self.total.text = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:(q * p)] numberStyle:NSNumberFormatterCurrencyStyle];
}

- (IBAction)qtyChanged:(id)sender {
    [self UpdateTotal];
    if (self.delegate) {
        [self.delegate setQuantity:self.qty.text atIndex:self.tag];
        [self.delegate UpdateTotal];
        //        [self.delegate setViewMovedUpDouble:NO];
        //        [self.delegate setViewMovedUpDouble:NO];
    }
}
@end
