//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "MenuViewCell.h"
#import "ThemeUtil.h"
#import "UIView+Boost.h"

@interface MenuViewCell()

@property UILabel* labelIcon;
@property UILabel* label;
@property UIView* highlightCell;

@end

@implementation MenuViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MenuViewCell"];
    if (self) {
        self.backgroundView = nil;
        self.selected = NO;

        self.labelIcon = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, 20, 44)];
        self.labelIcon.font = [UIFont iconAltFontOfSize:14];
        self.labelIcon.textColor = [UIColor colorWithRed:0.576 green:0.592 blue:0.600 alpha:1];
        [self addSubview:self.labelIcon];

        self.label = [[UILabel alloc] initWithFrame:CGRectMake(18 + 25, 0, 200, 44)];
        self.label.font = [UIFont lightFontOfSize:16];
        self.label.textColor = [UIColor whiteColor];
        [self addSubview:self.label];

        self.highlightCell = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 44)];
        self.highlightCell.backgroundColor = [ThemeUtil orangeColor];
        self.highlightCell.visible = NO;
        [self addSubview:self.highlightCell];

        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) [self selectCell];
    else [self unselectCell];
}

-(void)selectCell {
    self.highlightCell.visible = YES;
    self.labelIcon.textColor = [UIColor whiteColor];
    self.backgroundColor = [ThemeUtil blackColor];
}

-(void)unselectCell {
    self.highlightCell.visible = NO;
    self.labelIcon.textColor = [UIColor colorWithRed:0.576 green:0.592 blue:0.600 alpha:1];
    self.backgroundColor = [UIColor clearColor];
}

-(void)prepareForDisplay:(MenuLink)menuLink {
    self.menuLink = menuLink;
    MenuLinkMetadata *metadata = [[MenuLinkMetadataProvider instance] metadataFor:self.menuLink];
    self.labelIcon.text = metadata.iconCharacter;
    self.label.attributedText = metadata.menuTitle;
}

@end