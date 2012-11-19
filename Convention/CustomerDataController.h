//
//  CustomerDataController.h
//  Convention
//
//  Created by Kerry Sanders on 11/18/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomerDataController : NSObject

+(void)loadCustomers:(NSString *)authToken;

@end
