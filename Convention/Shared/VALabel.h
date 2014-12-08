//
//  VALabel.h
//  Convention
//
//  Created by Bogdan Covaci on 06.12.2014.
//  Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    VerticalAlignmentTop = 0,
    VerticalAlignmentMiddle,
    VerticalAlignmentBottom,
} VerticalAlignment;


@interface VALabel : UILabel

@property (nonatomic, readwrite) VerticalAlignment verticalAlignment;

@end