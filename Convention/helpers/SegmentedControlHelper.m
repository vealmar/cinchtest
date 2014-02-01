//
// Created by septerr on 1/15/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import "SegmentedControlHelper.h"


@interface SegmentedControlHelper ()

@property(strong, nonatomic) NSArray *values;
@property(strong, nonatomic) NSArray *strings;

@end


@implementation SegmentedControlHelper {

}

- (id)initForCancelByDays {
    self = [super init];
    if (self) {
        self.values = @[@-1, @90, @120, @150, @180];
        self.strings = @[@"Do Not Cancel", @"90 Days", @"120 Days", @"150 Days", @"180 Days"];
    }
    return self;
}

- (id)initForPaymentTerms {
    self = [super init];
    if (self) {
        self.values = @[@-1, @90, @120, @150, @180];
        self.strings = @[@"N/A", @"90 Days", @"120 Days", @"150 Days", @"180 Days"];
    }
    return self;
}

- (NSArray *)displayStrings {
    return self.strings;
}

- (NSNumber *)numberAtIndex:(NSInteger)index {
    if (index < 0 || index > self.values.count)
        return self.values[0]; //default to first value.
    else
        return self.values[(NSUInteger) index];
}


- (NSUInteger)indexForValue:(NSNumber *)value {
    if (value == nil)
        return 0;
    NSUInteger index = [self.values indexOfObject:value];
    if (index < 0)
        return 0;
    else
        return index;
}
@end