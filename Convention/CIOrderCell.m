//
//  CIOrderCell.m
//  Convention
//
//  Created by Matthew Clark on 12/9/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIOrderCell.h"
#import "config.h"

@implementation CIOrderCell
@synthesize Customer;
@synthesize auth;
@synthesize numItems;
@synthesize total;
@synthesize vouchers;
@synthesize lblSC;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.Customer.font = [UIFont fontWithName:kFontName size:17.f];
        self.auth.font = [UIFont fontWithName:kFontName size:14.f];
        self.numItems.font = [UIFont fontWithName:kFontName size:13.f];
        self.total.font = [UIFont fontWithName:kFontName size:13.f];
        self.vouchers.font = [UIFont fontWithName:kFontName size:13.f];
        self.lblSC.font = [UIFont fontWithName:kFontName size:14.f];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
