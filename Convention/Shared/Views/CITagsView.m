//
// Created by David Jafari on 2/13/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CITagsView.h"
#import "LayoutUtil.h"
#import "ThemeUtil.h"

static CGFloat tagMargin = 5.0;
static CGFloat tagSpacing = 5.0;
static CGFloat tagHeight = 20.0;

@interface CITagsView ()

@property NSMutableArray *mutableTagContainers;

@end

@implementation CITagsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.mutableTagContainers = [NSMutableArray array];
        self.tagViews = [NSArray array];
    }
    return self;
}

- (void)prepareForDisplay:(NSString *)tagString {
    // clear existing tags
    for (UIView *view in self.mutableTagContainers) {
        [view removeFromSuperview];
    }
    [self.mutableTagContainers removeAllObjects];

    NSArray *tags = tagString ? [[tagString stringByReplacingOccurrencesOfString:@", " withString:@","] componentsSeparatedByString:@","] : @[ ];
    float startingX = 0.0;
    float maxWidth = self.frame.size.width > 0 ? self.frame.size.width / MAX(tags.count, 1) : CGFLOAT_MAX;
    for (NSString *tag in tags) {
        UIView *tagContainer = [self newContainerFor:[self newTagIcon] label:[self newLabel:tag] startingX:startingX maxWidth:maxWidth];
        [self.mutableTagContainers addObject:tagContainer];
        [self addSubview:tagContainer];
        startingX += tagSpacing + tagContainer.frame.size.width;
    }

    self.tagViews = [NSArray arrayWithArray:self.mutableTagContainers];
}


- (UIView *)newContainerFor:(UIView *)icon label:(UIView *)label startingX:(CGFloat)startingX maxWidth:(CGFloat)maxWidth {
    float totalWidth = tagMargin + icon.frame.size.width + tagMargin + label.frame.size.width + tagMargin;
    if (totalWidth > maxWidth) {
        float deltaWidth = totalWidth - maxWidth;
        totalWidth = maxWidth;
        label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width - deltaWidth, label.frame.size.height);
    }

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(
            startingX,
            (self.frame.size.height - tagHeight) / 2,
            totalWidth,
            tagHeight
    )];
    [container addSubview:icon];
    [container addSubview:label];
    container.layer.cornerRadius = 4.0f;
    container.layer.borderWidth = 0.5f;
    container.layer.backgroundColor = [ThemeUtil darkBlueColor].CGColor;
    container.backgroundColor = [ThemeUtil darkBlueColor];
    return container;
}

- (UILabel *)newLabel:(NSString *)tagText {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0 + tagMargin + tagMargin, 0.0, 45.0, tagHeight - 1.0)];
    label.text = [tagText stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    label.textColor = [UIColor whiteColor];
    label.adjustsFontSizeToFitWidth = NO;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.font = [UIFont regularFontOfSize:11.0f];
    [LayoutUtil fitTextWidthTo:label];
    return label;
}

- (UILabel *)newTagIcon {
    UILabel *tagIcon = [[UILabel alloc] initWithFrame:CGRectMake(tagMargin, 0, 12.0, tagHeight)];
    tagIcon.text = @"\uf02c";
    tagIcon.textColor = [UIColor whiteColor];
    tagIcon.font = [UIFont iconFontOfSize:11.0f];
    [LayoutUtil fitTextWidthTo:tagIcon];
    return tagIcon;
}

@end