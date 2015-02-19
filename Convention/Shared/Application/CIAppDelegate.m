//
//  CIAppDelegate.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIAppDelegate.h"
#import "SettingsManager.h"
#import "LaunchViewController.h"
#import "CurrentSession.h"

static CIAppDelegate *appInstance;

@interface CIAppDelegate()

@property (strong, nonatomic) UIButton *zoomDismissButton;
@property (strong, nonatomic) UIView *zoomedBackgroundView;

@end

@implementation CIAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize window = _window;
@synthesize networkAvailable;

+ (CIAppDelegate*)instance {
    return appInstance;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    appInstance = self;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchViewController" bundle:nil];
    LaunchViewController *launchViewController = [storyboard instantiateInitialViewController];
    launchViewController.managedObjectContext = [CurrentSession mainQueueContext];
    self.window.rootViewController = launchViewController;
    [self.window makeKeyAndVisible];
    [[SettingsManager sharedManager] initialize];
    //reachDelegation = [[ReachabilityDelegation alloc] initWithDelegate:self
    // withUrl:kBASEURL];
    self.networkAvailable = [reachDelegation isNetworkReachable]; //TODO: We may need actually prod it to check here.
    [application setStatusBarStyle:UIStatusBarStyleLightContent];

    self.zoomedBackgroundView = [[UIView alloc] initWithFrame:self.window.bounds];
    self.zoomedBackgroundView.backgroundColor = [UIColor clearColor];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.zoomedBackgroundView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0.494 green:0.302 blue:0.647 alpha:1] CGColor], (id)[[UIColor colorWithRed:0.129 green:0.224 blue:0.353 alpha:1] CGColor], nil];
    gradient.startPoint = CGPointMake(0.0, 0.5);
    gradient.endPoint = CGPointMake(1.0, 0.5);
    [self.zoomedBackgroundView.layer addSublayer:gradient];

    return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    DLog(@"Application received memory warning!!!");
}

- (void)showZoomedController:(UIViewController*)c {
//    self.menuViewController = UIApplication.sharedApplication.keyWindow.rootViewController.navigationController;
//
//    [self.window insertSubview:self.zoomedBackgroundView atIndex:0];
//
//    c.view.frame = c.view.frame;
//    self.zoomedViewController = c;
//
//    UIWindow *window = [CIAppDelegate instance].window;
//    UIView *rootView = window.rootViewController.view;
//    rootView.userInteractionEnabled = NO;
//
//    self.zoomDismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    self.zoomDismissButton.frame = window.bounds;
//    self.zoomDismissButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
//    self.zoomDismissButton.alpha = 0.0;
//    [window addSubview:self.zoomDismissButton];
//
//    CGRect f = c.view.frame;
//    f.origin.y = window.bounds.size.height;
//    c.view.frame = f;
//    [window addSubview:c.view];
//
//    [self.menuViewController viewWillDisappear:YES];
//
//    [self.zoomDismissButton bk_addEventHandler:^(id sender) {
//        [self dismissZoomedController];
//    } forControlEvents:UIControlEventTouchDown];
//
//    [NSObject pop_animate:^{
//        rootView.pop_duration = 0.3;
//        rootView.pop_easeOut.pop_scaleXY = CGPointMake(0.85, 0.85);
//
//        self.zoomDismissButton.pop_duration = 0.3;
//        self.zoomDismissButton.pop_easeOut.alpha = 1.0;
//
//        self.zoomedViewController.view.pop_duration = 0.3;
//        CGRect f = self.zoomedViewController.view.frame;
//        f.origin.y = window.bounds.size.height - f.size.height;
//        self.zoomedViewController.view.pop_easeOut.frame = f;
//    } completion:^(BOOL finished) {
//        [self.menuViewController viewDidDisappear:YES];
//    }];
}

- (void)dismissZoomedController {
//    UIWindow *window = [CIAppDelegate instance].window;
//    UIView *rootView = window.rootViewController.view;
//
//    [self.zoomedViewController viewWillDisappear:YES];
//    [self.menuViewController viewWillAppear:YES];
//
//    [NSObject pop_animate:^{
//        rootView.pop_duration = 0.3;
//        rootView.pop_easeOut.pop_scaleXY = CGPointMake(1.0, 1.0);
//
//        self.zoomDismissButton.pop_duration = 0.3;
//        self.zoomDismissButton.pop_easeOut.alpha = 0.0;
//
//        self.zoomedViewController.view.pop_duration = 0.3;
//        CGRect f = self.zoomedViewController.view.frame;
//        f.origin.y = window.bounds.size.height;
//        self.zoomedViewController.view.pop_easeOut.frame = f;
//    } completion:^(BOOL finished) {
//        [self.zoomedBackgroundView removeFromSuperview];
//
//        rootView.userInteractionEnabled = YES;
//        [self.zoomedViewController.view removeFromSuperview];
//        self.zoomedViewController = nil;
//        self.zoomDismissButton = nil;
//
//        [self.zoomedViewController viewDidDisappear:YES];
//        [self.menuViewController viewDidAppear:YES];
//    }];
}

#pragma mark Reachability

- (BOOL)isNetworkReachable {
    return networkAvailable;
}

- (void)networkLost {

    DLog(@"Network Lost !");

    networkAvailable = NO;
}

- (void)networkRestored {

    DLog(@"Network Gained !");

    networkAvailable = YES;
}

#pragma mark - Core Data helper methods

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            DLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        [_managedObjectContext setMergePolicy:[[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType]];
        [_managedObjectContext setUndoManager:nil];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ProductCart" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
static int persistentStoreCoordinatorInvocationAttempts = 0;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ProductCart9-3.sqlite"];
    // remove old data before a login, takes too much time to delete individually
    if (![CurrentSession instance].authToken) {
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    }

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSDictionary *pragmaOptions = @{ @"synchronous": @"NORMAL",
                                     @"journal_mode" : @"WAL" };
    NSDictionary *storeOptions = @{ NSSQLitePragmasOption: pragmaOptions };

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil URL:storeURL
                                                         options:storeOptions
                                                           error:&error]) {
        if (0 == persistentStoreCoordinatorInvocationAttempts) {
            // we can remove and recreate the store, it's only used an a cache of server data
            persistentStoreCoordinatorInvocationAttempts++;
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
            _persistentStoreCoordinator = nil;
            return [self persistentStoreCoordinator];
        } else {
            DLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }

    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
