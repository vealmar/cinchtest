//
// Created by David Jafari on 12/31/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CITagColumnView.h"
#import "LineItem.h"
#import "Product.h"
#import "ThemeUtil.h"
#import "CITableViewColumn.h"

@interface CITagColumnView ()

@property NSMutableArray *tagContainers;

@end

@implementation CITagColumnView

static CGFloat tagMargin = 5.0;
static CGFloat tagSpacing = 5.0;
static CGFloat tagHeight = 20.0;

- (id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    self = [super initColumn:column frame:frame];
    if (self) {
        [self unhighlight];
        self.tagContainers = [NSMutableArray array];
    }

    return self;
}

- (void)render:(id)rowData {
    [super render:rowData];

    // clear existing tags
    for (UIView *view in self.tagContainers) {
        [view removeFromSuperview];
    }
    [self.tagContainers removeAllObjects];

    // add new tags
    NSArray *values = [self.column valuesFor:rowData];
    NSString *tagString = values.count > 0 ? values[0] : nil;
    NSArray *tags = tagString ? [[tagString stringByReplacingOccurrencesOfString:@", " withString:@","] componentsSeparatedByString:@","] : @[ ];
    float startingX = 0.0;
    float maxWidth = self.frame.size.width / MAX(tags.count, 1);
    for (NSString *tag in tags) {
        UIView *tagContainer = [self newContainerFor:[self newTagIcon] label:[self newLabel:tag] startingX:startingX maxWidth:maxWidth];
        [self.tagContainers addObject:tagContainer];
        [self addSubview:tagContainer];
        startingX += tagSpacing + tagContainer.frame.size.width;
    }
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
    [ThemeUtil fitTextWidthTo:label];
    return label;
}

- (UILabel *)newTagIcon {
    UILabel *tagIcon = [[UILabel alloc] initWithFrame:CGRectMake(tagMargin, 0, 12.0, tagHeight)];
    tagIcon.text = @"\uf02c";
    tagIcon.textColor = [UIColor whiteColor];
    tagIcon.font = [UIFont iconFontOfSize:11.0f];
    [ThemeUtil fitTextWidthTo:tagIcon];
    return tagIcon;
}

-(void)unhighlight {
    for (UIView *view in self.tagContainers) {
        view.backgroundColor = [ThemeUtil darkBlueColor];
        view.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

-(void)highlight:(NSDictionary *)attributes {
    for (UIView *view in self.tagContainers) {
        view.backgroundColor = [UIColor clearColor];
        view.layer.borderColor = [UIColor whiteColor].CGColor;
    }
}

@end