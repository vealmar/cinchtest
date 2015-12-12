//
//  CIAppDelegate.h
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReachabilityDelegation.h"
#import "APLSlideMenuViewController.h"



@interface CIAppDelegate : UIResponder <UIApplicationDelegate, ReachabilityDelegate> {

	ReachabilityDelegation *reachDelegation;
}

@property (strong, nonatomic) UIWindow *window;

@property (assign) BOOL networkAvailable;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) APLSlideMenuViewController *slideMenu;

+ (CIAppDelegate*)instance;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
-(BOOL)isNetworkReachable;
#pragma clang diagnostic pop

@end
