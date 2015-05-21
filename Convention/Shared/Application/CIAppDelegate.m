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
#import "CinchJSONAPIClient.h"

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
    [[SettingsManager sharedManager] initialize];
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
    [self loadLaunchViewController];
    return YES;
}

- (void)loadLaunchViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchViewController" bundle:nil];
    LaunchViewController *launchViewController = [storyboard instantiateInitialViewController];
    launchViewController.managedObjectContext = [CurrentSession mainQueueContext];
    self.window.rootViewController = launchViewController;
    [self.window makeKeyAndVisible];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    DLog(@"Application received memory warning!!!");
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Reachability

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
- (BOOL)isNetworkReachable {
    return networkAvailable;
}
#pragma clang diagnostic pop

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

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ProductCart11-3.sqlite"];
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
