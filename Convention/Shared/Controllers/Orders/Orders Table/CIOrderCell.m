//
//  CIOrderCell.m
//  Convention
//

#import "CIOrderCell.h"
#import "ThemeUtil.h"
#import "Order.h"
#import "Order+Extensions.h"
#import "NumberUtil.h"
#import "ShowConfigurations.h"
#import "OrderTotals.h"

@interface CIOrderCell ()

@property UIColor *savedStatusColor;
@property UIColor *savedRowStripeColor;
@property UIView *bar;
@property BOOL activeOrder;
@property BOOL initialized;

@end

@implementation CIOrderCell
@synthesize Customer;
@synthesize auth;
@synthesize numItems;
@synthesize total;
@synthesize vouchers;
@synthesize vouchersLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)updateRowHighlight:(NSIndexPath *)indexPath {
    if (self.activeOrder) {
        [self styleAsActive];
    } else {
        self.savedRowStripeColor = self.backgroundColor = indexPath.row % 2 == 1 ? [ThemeUtil tableAltRowColor] : [UIColor whiteColor];
    }
}

- (void)setActive:(BOOL)activeOrder {
    if (activeOrder) {
        [self styleAsActive];
    } else {
        [self styleAsInactive];
    }

    self.activeOrder = activeOrder;
}

- (void)prepareForDisplay:(Order *)order setActive:(BOOL)activeOrder {
    
    if (!self.initialized) {
        self.initialized = YES;
        self.activeOrder = NO;
        
        self.bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 114)];
        self.bar.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.bar.backgroundColor = [ThemeUtil orangeColor];
        
        self.bar.hidden = YES;
        [self.contentView addSubview:self.bar];
    }
    
    self.Customer.text = order.customerName;
    
    if (order.authorizedBy != nil) {
        self.auth.text = order.authorizedBy;
        self.Customer.center = CGPointMake(self.Customer.center.x, self.contentView.center.y - 8);
        self.auth.center = CGPointMake(self.auth.center.x, self.contentView.center.y + 14);
    } else {
        self.Customer.center = CGPointMake(self.Customer.center.x, self.contentView.center.y);
        self.auth.text = @"";
    }
    
    self.numItems.text = [NSString stringWithFormat:@"%d Items", order.lineItems.count];
    
    self.total.text = @"Calculating...";
    __weak CIOrderCell *weakSelf = self;
    [order calculateTotals:^(OrderTotals *totals, NSManagedObjectID *totalledOrderId) {
        if (weakSelf && [order.objectID isEqual:totalledOrderId])
            self.total.text = [NumberUtil formatDollarAmount:totals.total];
    }];
    
    self.tag = [order.orderId intValue];
    
    self.orderStatus.font = [UIFont semiboldFontOfSize:12.0];
    if (order.status != nil) {
        self.orderStatus.text = [order.status capitalizedString];
        if (order.isPartial || order.isPending) {
            self.orderStatus.backgroundColor = [ThemeUtil darkBlueColor];
        } else if (order.isSubmitted) {
            self.orderStatus.backgroundColor = [ThemeUtil orangeColor];
        } else if (order.isComplete) {
            self.orderStatus.backgroundColor = [ThemeUtil greenColor];
        }
    } else {
        self.orderStatus.text = @"Unknown";
        self.orderStatus.backgroundColor = [UIColor blackColor];
    }
    self.savedStatusColor = self.orderStatus.backgroundColor;
    
    self.orderStatus.attributedText = [[NSAttributedString alloc] initWithString:self.orderStatus.text attributes: @{ NSKernAttributeName : @(-0.5f) }];
    self.orderStatus.layer.cornerRadius = 3.0f;
    
    if (order.orderId != nil)
        self.orderId.text = [NSString stringWithFormat:@"Order #%@", [order.orderId stringValue]];
    else
        self.orderId.text = @"";
    
    if (![ShowConfigurations instance].vouchers) {
        self.vouchersLabel.hidden = YES;
        self.vouchers.hidden = YES;
    }
    
    [self setActive:activeOrder];
}

- (void)styleAsActive {
    for (UILabel *l in self.contentView.subviews) {
        if ([l isKindOfClass:[UILabel class]]) {
            l.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        }
    }
    
    CGRect orderIdFrame = CGRectMake(12.0f, 9.0f, 106.0f, 20.0f);
    CGRect customerFrame = CGRectMake(12.0f, 27.0f, 297.0f, 34.0f);
    CGRect authFrame = CGRectMake(12.0f, 56.0f, 308.0f, 21.0f);
    CGRect totalFrame = CGRectMake(12.0f, 84.0f, 141.0f, 21.0f);

    self.orderId.frame = CGRectMake(orderIdFrame.origin.x + 10.0f, orderIdFrame.origin.y, orderIdFrame.size.width, orderIdFrame.size.height);
    self.Customer.frame = CGRectMake(customerFrame.origin.x + 10.0f, customerFrame.origin.y, customerFrame.size.width, customerFrame.size.height);
    self.auth.frame = CGRectMake(authFrame.origin.x + 10.0f, authFrame.origin.y, authFrame.size.width, authFrame.size.height);
    self.total.frame = CGRectMake(totalFrame.origin.x + 10.0f, totalFrame.origin.y, totalFrame.size.width, totalFrame.size.height);
    
    self.orderStatus.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.orderStatus.backgroundColor = [UIColor colorWithRed:0.161 green:0.173 blue:0.173 alpha:1];
    self.bar.hidden = NO;
    self.contentView.backgroundColor = [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1];
}

- (void)styleAsInactive {
    for (UILabel *l in self.contentView.subviews) {
        if ([l isKindOfClass:[UILabel class]]) {
            l.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
        }
    }
    
    CGRect orderIdFrame = CGRectMake(12.0f, 9.0f, 106.0f, 20.0f);
    CGRect customerFrame = CGRectMake(12.0f, 27.0f, 297.0f, 34.0f);
    CGRect authFrame = CGRectMake(12.0f, 56.0f, 308.0f, 21.0f);
    CGRect totalFrame = CGRectMake(12.0f, 84.0f, 141.0f, 21.0f);
    
    self.orderId.frame = orderIdFrame;
    self.Customer.frame = customerFrame;
    self.auth.frame = authFrame;
    self.total.frame = totalFrame;
    
    self.orderStatus.textColor = [UIColor whiteColor];
    self.orderStatus.backgroundColor = self.savedStatusColor;
    self.bar.hidden = YES;
    self.contentView.backgroundColor = self.savedRowStripeColor ? self.savedRowStripeColor : [UIColor whiteColor];
}


@end
