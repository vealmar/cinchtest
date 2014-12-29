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
}


- (void)updateRowHighlight:(NSIndexPath *)indexPath {
    self.backgroundColor = indexPath.row % 2 == 1 ? [ThemeUtil tableAltRowColor] : [UIColor whiteColor];
}



@end
