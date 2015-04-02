//
// Created by David Jafari on 2/13/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CIPriceOptionTableViewCell.h"
#import "LineItem.h"
#import "ThemeUtil.h"
#import "Configurations.h"
#import "NumberUtil.h"
#import "Product+Extensions.h"
#import "LineItem+Extensions.h"
#import "View+MASAdditions.h"

@interface CIPriceOptionTableViewCell()

@property NSString *priceTier;
@property int priceTierIndex;
@property UITextField *customPriceInputView;
@property (weak) LineItem *lineItem;

@end

@implementation CIPriceOptionTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.textColor = [ThemeUtil offBlackColor];
        self.detailTextLabel.textColor = [ThemeUtil noteColor];
        self.detailTextLabel.font = [UIFont regularFontOfSize:14.0F];

        self.customPriceInputView = [[UITextField alloc] init];
        self.customPriceInputView.textAlignment = NSTextAlignmentRight;
        self.customPriceInputView.font = [UIFont systemFontOfSize:14.0f];
        self.customPriceInputView.borderStyle = UITextBorderStyleRoundedRect;
        self.customPriceInputView.layer.borderColor = [UIColor blackColor].CGColor  ;
        self.customPriceInputView.backgroundColor = [UIColor whiteColor];
        self.customPriceInputView.textColor = [UIColor blackColor];
        self.customPriceInputView.text = @"0.00";
        self.customPriceInputView.delegate = self;
        self.customPriceInputView.keyboardType = UIKeyboardTypeNumberPad;
        self.customPriceInputView.textColor = self.textLabel.textColor;
        self.customPriceInputView.hidden = YES;
        [self.contentView addSubview:self.customPriceInputView];

        [self.customPriceInputView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.contentView.mas_right).offset(-15);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.height.equalTo(@20);
            make.width.equalTo(@75);
        }];

    }

    return self;
}

-(void)prepareForDisplay:(LineItem *)lineItem at:(NSIndexPath *)indexPath {
    self.lineItem = lineItem;
    
    Configurations *configurations = [Configurations instance];
    NSNumber *currentPrice = lineItem.price;

    if (lineItem.isWriteIn || indexPath.row >= configurations.priceTiersAvailable) {
        self.priceTier = @"Custom";
        self.textLabel.text = self.priceTier;
        self.detailTextLabel.text = [NumberUtil formatDollarAmount:currentPrice];

        // if prices at different tiers are the same, we have no way of distinguishing right now
//        if (![lineItem.product.prices containsObject:currentPrice]) {
//            [self setSelected:YES animated:NO];
//        }
    } else {
        NSNumber *productPrice = [lineItem.product priceAtTier:indexPath.row];

        self.priceTier = [configurations priceTierLabelAt:indexPath.row];
        self.priceTierIndex = indexPath.row;
        self.textLabel.text = self.priceTier;
        self.detailTextLabel.text = [NumberUtil formatDollarAmount:productPrice];

        // if prices at different tiers are the same, we have no way of distinguishing right now
//        if ([currentPrice isEqualToNumber:productPrice]) {
//            [self setSelected:YES animated:NO];
//        }
    }
}


-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    if (selected) {
        self.textLabel.font = [UIFont boldFontOfSize:14.0];
        self.textLabel.text = [self.priceTier uppercaseString];
        self.accessoryType = UITableViewCellAccessoryCheckmark;
        
        if (![[self currentPrice] isEqualToNumber:self.lineItem.price]) {
            self.lineItem.price = [self.lineItem.product priceAtTier:self.priceTierIndex];
        }
        if ([self isCustomPriceTier]) {
            self.customPriceInputView.hidden = NO;
            [self.customPriceInputView becomeFirstResponder];
        }
    } else {
        self.textLabel.font = [UIFont regularFontOfSize:14.0];
        self.textLabel.text = self.priceTier;
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

-(NSNumber *)currentPrice {
    if ([self isCustomPriceTier]) {
        return [NumberUtil convertStringToDollars:self.customPriceInputView.text];
    } else {
        return [self.lineItem.product priceAtTier:self.priceTierIndex];
    }
}

-(BOOL)isCustomPriceTier {
    return [@"Custom" isEqualToString:self.priceTier];
}

#pragma mark- UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {

    if ([textField.text isEqualToString:@"0"]) {
        textField.text = @"";
    }

    if (textField.text.length > 0) {
        UITextRange *textRange = [textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument];
        [textField setSelectedTextRange:textRange];
    }

}


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.customPriceInputView && self.lineItem) {
        self.customPriceInputView.text = [NumberUtil formatDollarAmountWithoutSymbol:self.lineItem.price];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.customPriceInputView && self.lineItem) {
        NSNumber *price = [NumberUtil convertStringToDollars:textField.text];
        self.detailTextLabel.text = [NumberUtil formatDollarAmount:price];
        self.lineItem.price = price;
        self.customPriceInputView.hidden = YES;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (!string.length)
        return YES;

    if (textField == self.customPriceInputView) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSString *expression = @"^\\-?([0-9]+)?(\\.([0-9]{1,2})?)?$";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:newString
                                                            options:0
                                                              range:NSMakeRange(0, [newString length])];
        if (numberOfMatches == 0)
            return NO;
    }
    return YES;
}


@end