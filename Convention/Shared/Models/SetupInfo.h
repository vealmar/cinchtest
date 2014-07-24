//
//  SetupInfo.h
//  Convention
//
//  Created by Kerry Sanders on 12/6/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SetupInfo : NSManagedObject

@property (nonatomic, retain) NSString * item;
@property (nonatomic, retain) NSString * value;

@end
