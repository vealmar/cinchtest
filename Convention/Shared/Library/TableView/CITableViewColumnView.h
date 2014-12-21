//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CITableViewColumn;

@interface CITableViewColumnView : UIView

@property CITableViewColumn *column;

-(id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame;
-(void)render:(id)rowData;

@end

@interface CITableViewColumnView (Abstract)

-(void)unhighlight;
-(void)highlight:(NSDictionary *)attributes;

@end