//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CITableViewColumnView.h"
#import "CITableViewColumn.h"


@implementation CITableViewColumnView

- (id)initColumn:(CITableViewColumn *)column frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.column = column;
    }
    return self;
}

-(void)render:(id)rowData {
    [self unhighlight];
}

-(void)unhighlight {

}

-(void)highlight:(NSDictionary *)attributes {

}

@end