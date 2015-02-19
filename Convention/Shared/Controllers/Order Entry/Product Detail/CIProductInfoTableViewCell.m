//
// Created by David Jafari on 2/12/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIProductInfoTableViewCell.h"
#import "Product.h"
#import "ThemeUtil.h"
#import "NumberUtil.h"
#import "CITagsView.h"
#import "LayoutUtil.h"
#import "LineItem.h"
#import "View+MASAdditions.h"
#import "UIView+Boost.h"
#import "NotificationConstants.h"
#import "LineItem.h"
#import "NilUtil.h"

@interface CIProductInfoTableViewCell ()

@property UILabel *titleLabel;
@property UILabel *priceLabel;
@property UITextView *descriptionText;
@property CITagsView *tagsView;

@end

@implementation CIProductInfoTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.textColor = [ThemeUtil offBlackColor];
        titleLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.titleLabel = titleLabel;
        [self.contentView addSubview:titleLabel];

        UILabel *priceLabel = [[UILabel alloc] init];
        priceLabel.font = [UIFont boldFontOfSize:22.0F];
        priceLabel.textColor = [ThemeUtil orangeColor];
        priceLabel.textAlignment = NSTextAlignmentRight;
        priceLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.priceLabel = priceLabel;
        [self.contentView addSubview:priceLabel];

        UITextView *descriptionText = [[UITextView alloc] initWithFrame:CGRectZero textContainer:nil];
        descriptionText.font = [UIFont semiboldFontOfSize:14.0F];
        descriptionText.textColor = [ThemeUtil noteColor];
        descriptionText.editable = NO;
        descriptionText.backgroundColor = [UIColor clearColor];
        descriptionText.scrollEnabled = NO;
        descriptionText.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        descriptionText.contentInset = UIEdgeInsetsZero;
        self.descriptionText = descriptionText;
        [self.contentView addSubview:descriptionText];

        CITagsView *tagsView = [[CITagsView alloc] initWithFrame:CGRectZero];
        self.tagsView = tagsView;
        [self.contentView addSubview:self.tagsView];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPriceChanged:) name:LinePriceChangedNotification object:nil];

        [self.priceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).offset(10.0F);
            make.right.equalTo(self.contentView.mas_right).offset(-15.0F);
            make.width.equalTo(@(50)).priorityHigh();
        }];

        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top).offset(10.0F);
            make.left.equalTo(self.contentView.mas_left).offset(20.0F);
            make.right.equalTo(self.priceLabel.mas_left).offset(4.0F).priorityLow();
        }];

        [self.descriptionText mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.width.equalTo(self.contentView.mas_width);
            make.left.equalTo(self.contentView.mas_left).offset(15.0F);
            make.right.equalTo(self.contentView.mas_right).offset(-15.0F);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(0.0F);
        }];

        [self.tagsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(self.contentView.mas_width);
            make.left.equalTo(self.contentView.mas_left).offset(20.0F);
            make.top.equalTo(self.descriptionText.mas_bottom).offset(8.0F);
            make.height.equalTo(@20);
        }];

        [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
            make.top.equalTo(self.mas_top);
            make.bottom.equalTo(self.tagsView.mas_bottom);
        }];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForDisplay:(LineItem *)line {
    [self updateContent:line];
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    [super updateConstraints];
//    [self.priceLabel mas_updateConstraints:^(MASConstraintMaker *make) {
//        make.width.equalTo(@(self.priceLabel.frame.size.width)).priorityHigh;
//    }];
}

- (void)updateContent:(LineItem *)line {
    Product *product = line.product;

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@"Product " attributes:@{
            NSFontAttributeName : [UIFont regularFontOfSize:22.0F]
    }]];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:product.invtid attributes:@{
            NSFontAttributeName : [UIFont semiboldFontOfSize:22.0F]
    }]];
    self.titleLabel.attributedText = title;
    self.priceLabel.text = [NumberUtil formatDollarAmount:line.price];
    self.descriptionText.text = [NSString stringWithFormat:@"%@\n%@", [NilUtil objectOrEmptyString:product.descr],[NilUtil objectOrEmptyString:product.descr2]];
    [self.tagsView prepareForDisplay:product.tags];
    [self.tagsView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self.tagsView.tagViews.count > 0 ? @20 : @0);
    }];
}

- (void)onPriceChanged:(NSNotification *)notification {
    LineItem *line = (LineItem *) notification.object;
    self.priceLabel.text = [NumberUtil formatDollarAmount:line.price];
}

@end