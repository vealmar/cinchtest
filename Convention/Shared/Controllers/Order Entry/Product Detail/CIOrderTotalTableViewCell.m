//
// Created by David Jafari on 2/15/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIOrderTotalTableViewCell.h"
#import "View+MASAdditions.h"
#import "Order.h"
#import "ThemeUtil.h"
#import "NumberUtil.h"
#import "LineItem+Extensions.h"
#import "NotificationConstants.h"
#import "Underscore.h"

@interface CIOrderTotalTableViewCell ()

@property UIView *lineTotalBackgroundView;
@property UILabel *lineTotalLabel;

@property NSArray *selectedLines;

@end

@implementation CIOrderTotalTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.lineTotalBackgroundView = [[UIView alloc] init];
        self.lineTotalBackgroundView.layer.cornerRadius = 3;
        self.lineTotalBackgroundView.layer.borderColor = [ThemeUtil noteColor].CGColor;
        self.lineTotalBackgroundView.layer.borderWidth = 0.1F;
        [self addSubview:self.lineTotalBackgroundView];

        self.lineTotalLabel = [[UILabel alloc] init];
        self.lineTotalLabel.font = [UIFont systemFontOfSize:13.0f];
        self.lineTotalLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:self.lineTotalLabel];

        [self updateTotal:@0];

        [self.lineTotalBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView.mas_right).offset(-15);
            make.left.greaterThanOrEqualTo(self.lineTotalLabel.mas_left).offset(3);
            make.centerY.equalTo(self.mas_centerY);
            make.height.equalTo(@20);
            make.width.greaterThanOrEqualTo(@75);
        }];

        [self.lineTotalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.lineTotalBackgroundView.mas_right).offset(-5);
            make.centerY.equalTo(self.mas_centerY);
            make.height.equalTo(@20);
        }];

        [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
            make.top.equalTo(self.mas_top);
            make.bottom.equalTo(self.mas_bottom);
        }];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLineChanged:) name:LineQuantityChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLineChanged:) name:LinePriceChangedNotification object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)onLineChanged:(NSNotification *)notification {
    if (notification.object && [notification.object isKindOfClass:[LineItem class]]) {
        LineItem *notifiedLine = (LineItem *) notification.object;
        BOOL matches = Underscore.array(self.selectedLines).any(^BOOL(LineItem *line) {
            return [notifiedLine isEqual:line];
        });
        if (matches) {
            [self recalculateTotal];
        }
    }
}

-(void)prepareForDisplay:(NSArray *)selectedLines {
    self.selectedLines = selectedLines;
    [self recalculateTotal];
}

-(void)recalculateTotal {
    double total = 0.0;
    for (LineItem *line in self.selectedLines) {
        total += line.subtotal;
    }
    [self updateTotal:@(total)];
}

-(void)updateTotal:(NSNumber *)total {
    self.lineTotalLabel.text = [NumberUtil formatDollarAmount:total];
    if (total.doubleValue > 0) {
        self.lineTotalBackgroundView.layer.borderColor = [UIColor clearColor].CGColor;
        self.lineTotalBackgroundView.backgroundColor = [ThemeUtil orangeColor];
        self.lineTotalLabel.textColor = [UIColor whiteColor];
    } else {
        self.lineTotalBackgroundView.layer.borderColor = [ThemeUtil noteColor].CGColor;
        self.lineTotalBackgroundView.backgroundColor = [UIColor clearColor];
        self.lineTotalLabel.textColor = [ThemeUtil noteColor];
    }
}


@end