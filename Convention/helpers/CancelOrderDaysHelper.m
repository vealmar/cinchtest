//
// Created by septerr on 1/15/14.
// Copyright (c) 2014 Convention Innovations. All rights reserved.
//

#import "CancelOrderDaysHelper.h"


@interface CancelOrderDaysHelper ()

@property(strong, nonatomic) NSArray *dayNumbers;
@property(strong, nonatomic) NSArray *dayStrings;

@end


@implementation CancelOrderDaysHelper {

}

- (id)init {
    self = [super init];
    if (self) {
        self.dayNumbers = @[@-1, @90, @120, @150, @180];
        self.dayStrings = @[@"Do Not Cancel", @"90 Days", @"120 Days", @"150 Days", @"180 Days"];
    }
    return self;
}

- (NSArray *)displayStrings {
    return self.dayStrings;
}

- (NSNumber *)numberAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.dayNumbers.count)
        return self.dayNumbers[(NSUInteger) index];
    else
        return nil;
}


- (NSString *)displayStringForIndex:(NSInteger)index {
    if (index >= 0 && index < self.dayNumbers.count)
        return self.dayStrings[(NSUInteger) index];
    else
        return self.dayStrings[0];
}

- (NSUInteger)numberOfOptios {
    return self.dayNumbers.count;
}

- (NSUInteger)indexForDays:(NSNumber *)days {
    if (days == nil)
        return 0;
    NSUInteger index = [self.dayNumbers indexOfObject:days];
    if (index < 0)
        return 0;
    else
        return index;
}
@end