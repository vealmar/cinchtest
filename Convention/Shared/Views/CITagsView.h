//
// Created by David Jafari on 2/13/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CITagsView : UIView

@property NSArray *tagViews;

- (void)prepareForDisplay:(NSString *)tagString;

@end