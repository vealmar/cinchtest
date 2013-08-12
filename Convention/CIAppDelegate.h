//
//  CIAppDelegate.h
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReachabilityDelegation.h"

@class CIViewController;

@interface CIAppDelegate : UIResponder <UIApplicationDelegate, ReachabilityDelegate> {
	
	ReachabilityDelegation *reachDelegation;
}

@property (strong, nonatomic) UIWindow *window;

@property (assign) BOOL networkAvailable;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

-(BOOL)isNetworkReachable;

@end
