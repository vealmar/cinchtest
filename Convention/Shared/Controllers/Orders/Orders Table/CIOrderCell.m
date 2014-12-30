//
//  CIOrderCell.m
//  Convention
//

#import "CIOrderCell.h"
#import "ThemeUtil.h"

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
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    BOOL wasSelected = self.selected;

    [super setSelected:selected animated:animated];

    CGRect orderIdFrame = CGRectMake(12.0f, 9.0f, 106.0f, 20.0f);
    CGRect customerFrame = CGRectMake(12.0f, 27.0f, 297.0f, 34.0f);
    CGRect authFrame = CGRectMake(12.0f, 56.0f, 308.0f, 21.0f);
    CGRect totalFrame = CGRectMake(12.0f, 84.0f, 141.0f, 21.0f);

    if (selected) {
        for (UILabel *l in self.contentView.subviews) {
            if ([l isKindOfClass:[UILabel class]]) {
                l.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
            }
        }

        if (!wasSelected) {
            self.orderId.frame = CGRectMake(orderIdFrame.origin.x + 10.0f, orderIdFrame.origin.y, orderIdFrame.size.width, orderIdFrame.size.height);
            self.Customer.frame = CGRectMake(customerFrame.origin.x + 10.0f, customerFrame.origin.y, customerFrame.size.width, customerFrame.size.height);
            self.auth.frame = CGRectMake(authFrame.origin.x + 10.0f, authFrame.origin.y, authFrame.size.width, authFrame.size.height);
            self.total.frame = CGRectMake(totalFrame.origin.x + 10.0f, totalFrame.origin.y, totalFrame.size.width, totalFrame.size.height);
        }

        self.orderStatus.backgroundColor = [UIColor colorWithRed:0.161 green:0.173 blue:0.173 alpha:1];
    } else {
        for (UILabel *l in self.contentView.subviews) {
            if ([l isKindOfClass:[UILabel class]]) {
                l.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
            }
        }

        if (wasSelected) {
            self.orderId.frame = orderIdFrame;
            self.Customer.frame = customerFrame;
            self.auth.frame = authFrame;
            self.total.frame = totalFrame;
        }

        if (!wasSelected) {
            self.savedStatusColor = self.orderStatus.backgroundColor;
        }
        self.orderStatus.backgroundColor = self.savedStatusColor;
    }

    self.orderStatus.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
}


- (void)updateRowHighlight:(NSIndexPath *)indexPath {
    self.backgroundColor = indexPath.row % 2 == 1 ? [ThemeUtil tableAltRowColor] : [UIColor whiteColor];
}



@end
