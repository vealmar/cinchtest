//
//  Error.h
//  Convention
//
//  Created by septerr on 12/27/13.
//  Copyright (c) 2013 Convention Innovations. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Error : NSManagedObject

@property(nonatomic, retain) NSString *message;

@end
