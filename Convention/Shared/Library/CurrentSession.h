//
// Created by David Jafari on 12/14/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CurrentSession : NSObject

@property NSManagedObjectContext *managedObjectContext;
@property NSString *authToken;
@property NSDictionary* vendorInfo;
@property (readonly) NSNumber* showId;
@property (readonly) NSString* loggedInVendorGroupId;
@property (readonly) NSNumber* vendorId;

+(CurrentSession *)instance;

- (void)dispatchSessionDidChange;

/**
* In situations where operations will be performed off the main thread, this
* method will construct a new ManagedObjectContext. The managedObjectContext
* provided as a property on this class is intended to only be used on the
* main thread.
*
* @return a new context
*/
- (NSManagedObjectContext *)newManagedObjectContext;

@end