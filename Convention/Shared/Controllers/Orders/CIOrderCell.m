//
//  CIOrderCell.m
//  Convention
//
//  Created by Matthew Clark on 12/9/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIOrderCell.h"
#import "config.h"


@interface CIOrderCell ()
@property (strong, nonatomic) UIColor *savedStatusColor;
@end

@implementation CIOrderCell
@synthesize Customer;
@synthesize auth;
@synthesize numItems;
@synthesize total;
@synthesize vouchers;
@synthesize vouchersLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
//        self.Customer.font = [UIFont fontWithName:kFontName size:17.f];
//        self.auth.font = [UIFont fontWithName:kFontName size:14.f];
//        self.numItems.font = [UIFont fontWithName:kFontName size:13.f];
//        self.total.font = [UIFont fontWithName:kFontName size:13.f];
//        self.vouchers.font = [UIFont fontWithName:kFontName size:13.f];
//        self.vouchersLabel.font = [UIFont fontWithName:kFontName size:14.f];
//        self.orderStatus.font = [UIFont fontWithName:kFontName size:13.f];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    UIColor *c = self.orderStatus.backgroundColor;
    BOOL wasSelected = self.selected;

    [super setSelected:selected animated:animated];

    if (selected) {
        for (UILabel *l in self.contentView.subviews) {
            if ([l isKindOfClass:[UILabel class]]) {
                l.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
            }

            if (!wasSelected) {
                if (l != self.orderStatus) {
                    l.center = CGPointMake(l.center.x + 10, l.center.y);
                }
            }
        }

        self.orderStatus.backgroundColor = [UIColor colorWithRed:0.161 green:0.173 blue:0.173 alpha:1];
    } else {
        for (UILabel *l in self.contentView.subviews) {
            if ([l isKindOfClass:[UILabel class]]) {
                l.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
            }

            if (wasSelected) {
                if (l != self.orderStatus) {
                    l.center = CGPointMake(l.center.x - 10, l.center.y);
                }
            }
        }

        if (!wasSelected) {
            self.savedStatusColor = self.orderStatus.backgroundColor;
        }
        self.orderStatus.backgroundColor = self.savedStatusColor;
    }

    self.orderStatus.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];

    // Configure the view for the selected state
}

- (UIColor*)inverseColor:(UIColor*)color
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

@end
