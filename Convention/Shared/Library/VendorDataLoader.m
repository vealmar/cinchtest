//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "VendorDataLoader.h"
#import "MBProgressHUD.h"
#import "CinchJSONAPIClient.h"
#import "CurrentSession.h"
#import "CoreDataUtil.h"
#import "Bulletin.h"
#import "Customer.h"
#import "NotificationConstants.h"
#import "CoreDataManager.h"
#import "NilUtil.h"
#import "Vendor.h"
#import "Show.h"
#import "Show+Extensions.h"

@interface VendorDataLoader ()

@property UIView *view;
@property CurrentSession *currentSession;
@property(nonatomic, copy) void (^onComplete)();
@property NSMutableArray *dataTypes;

@property(strong) VendorDataLoader *retainedSelf;

@end

@implementation VendorDataLoader

// loads customers -> products -> vendors -> bulletins
+ (VendorDataLoader *)load:(NSArray *)dataTypes inView:(UIView *)view onComplete:(void (^)())onComplete {
    VendorDataLoader *loader = [VendorDataLoader new];
    loader.currentSession = [CurrentSession instance];
    loader.view = view;
    loader.retainedSelf = loader;
    loader.dataTypes = [NSMutableArray arrayWithArray:dataTypes];
    loader.onComplete = ^{
        [[NSNotificationCenter defaultCenter] removeObserver:loader];
        if(onComplete){
            onComplete();
        }
        loader.retainedSelf = nil;
    };
    [loader loadNext];
    return loader;
}

- (void)loadNext {
    if (self.dataTypes.count > 0) {
        id dataType = self.dataTypes.firstObject;
        [self.dataTypes removeObject:dataType];
        switch ([dataType intValue]) {
            case (VendorDataTypeCustomers):
                [self loadCustomers];
                break;
            case (VendorDataTypeVendors):
                [self loadVendors];
                break;
            case (VendorDataTypeBulletins):
                [self loadBulletins];
                break;
            case (VendorDataTypeProducts):
                [self loadProducts];
                break;
            case (VendorDataTypeShows):
                [self loadShows];
                break;
            default:break;
        }
    } else {
        if(self.onComplete){
            self.onComplete();
        }
    }
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productLoadComplete) name:ProductsLoadedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customerLoadComplete) name:CustomersLoadedNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadCustomers {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"Loading Customers";
    [hud show:NO];

    [[CinchJSONAPIClient sharedInstance] getCustomersWithSession:self.currentSession
                                                         success:^(NSURLSessionDataTask *task, id JSON) {
                                                             [[CurrentSession privateQueueContext] performBlock:^{
                                                                 [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Customer" withContext:[CurrentSession privateQueueContext]];
                                                                 if (JSON && ([(NSArray *) JSON count] > 0)) {
                                                                     NSArray *customers = (NSArray *) JSON;
                                                                     for (NSDictionary *customer in customers) {
                                                                         [[CurrentSession privateQueueContext] insertObject:[[Customer alloc] initWithCustomerFromServer:customer context:[CurrentSession privateQueueContext]]];
                                                                     }
                                                                     [[CurrentSession privateQueueContext] save:nil];
                                                                 }
                                                                 [[NSNotificationCenter defaultCenter] postNotificationName:CustomersLoadedNotification object:nil];
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     if (hud) [hud hide:NO];
                                                                     [self loadNext];
                                                                 });
                                                             }];
                                                         }
                                                         failure:^(NSURLSessionDataTask *task, NSError *apiError) {
                                                             [[CurrentSession privateQueueContext] performBlock:^{
                                                                 [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Customer" withContext:[CurrentSession privateQueueContext]];
                                                             }];
                                                             [hud hide:NO];
                                                             [[[UIAlertView alloc] initWithTitle:@"Error" message:[apiError localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                                             NSLog(@"%@ Error loading customers: %@", [self class], [apiError localizedDescription]);
                                                         }];
}

- (void)customerLoadComplete {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CustomersLoadedNotification object:nil];
}

- (void)loadProducts {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"Loading Products";
    [hud show:NO];

    void (^successBlock)() = ^() {
    };

    void (^failureBlock)() = ^() {
        [hud hide:NO];
    };

    [CoreDataManager reloadProductsAsync:YES usingQueueContext:[CurrentSession privateQueueContext] onSuccess:successBlock onFailure:failureBlock];
}

- (void)loadShows {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"Loading Sales Periods";
    [hud show:NO];
    [[CinchJSONAPIClient sharedInstance] getShowsWithSession:self.currentSession
                                                     success:^(NSURLSessionDataTask *task, id JSON) {
                                                         [[CurrentSession privateQueueContext] performBlock:^{
                                                             [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Show" withContext:[CurrentSession privateQueueContext]];
                                                             if (JSON && ([(NSArray *) JSON count] > 0)) {
                                                                 NSArray *shows = (NSArray *) JSON;
                                                                 for (NSDictionary *show in shows) {
                                                                     [[CurrentSession privateQueueContext] insertObject:[[Show alloc] initWithShowFromServer:show context:[CurrentSession privateQueueContext]]];
                                                                 }
                                                                 [[CurrentSession privateQueueContext] save:nil];
                                                             }
                                                             [[NSNotificationCenter defaultCenter] postNotificationName:ShowsLoadedNotification object:nil];
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 if (hud) [hud hide:NO];
                                                                 [self loadNext];
                                                             });
                                                         }];
                                                     }
                                                     failure:^(NSURLSessionDataTask *task, NSError *apiError) {
                                                         [[CurrentSession privateQueueContext] performBlock:^{
                                                             [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Show" withContext:[CurrentSession privateQueueContext]];
                                                         }];
                                                         [hud hide:NO];
                                                         [[[UIAlertView alloc] initWithTitle:@"Error" message:[apiError localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                                         NSLog(@"%@ Error loading shows: %@", [self class], [apiError localizedDescription]);
                                                     }];
}

- (void)productLoadComplete {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ProductsLoadedNotification object:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[MBProgressHUD HUDForView:self.view] hide:NO];
        [self loadNext];
    });
}

- (void)loadVendors {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"Loading Vendors";
    [hud show:NO];
    [[CinchJSONAPIClient sharedInstance] getVendorsWithSession:self.currentSession
                                                       success:^(NSURLSessionDataTask *task, id JSON) {
                                                           [[CurrentSession mainQueueContext] performBlockAndWait:^{
                                                               [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Vendor" withContext:[CurrentSession mainQueueContext]];

                                                               if (JSON) {
                                                                   NSArray *vendorgroups = [NSArray arrayWithArray:JSON];
                                                                   for (NSDictionary *vendorgroup in vendorgroups) {
                                                                       NSArray *vendors = [NilUtil objectOrEmptyArray:vendorgroup[@"vendors"]];
                                                                       for (NSDictionary *vendor in vendors) {
                                                                           [[CurrentSession mainQueueContext] insertObject:[[Vendor alloc] initWithVendorFromServer:vendor context:[CurrentSession mainQueueContext]]];
                                                                       }
                                                                   }
                                                                   [[CurrentSession mainQueueContext] save:nil];
                                                                   [hud hide:NO];
                                                                   [self loadNext];
                                                               }
                                                           }];
                                                       }
                                                       failure:^(NSURLSessionDataTask *task, NSError *apiError) {
                                                           [[CurrentSession mainQueueContext] performBlockAndWait:^{
                                                               [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Vendor" withContext:[CurrentSession mainQueueContext]];
                                                           }];
                                                           [hud hide:NO];
                                                           [[[UIAlertView alloc] initWithTitle:@"Error" message:[apiError localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                                           NSLog(@"%@ Error loading vendors: %@", [self class], [apiError localizedDescription]);
                                                       }];
}

- (void)loadBulletins {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"Loading Brands";
    [hud show:NO];

    [[CinchJSONAPIClient sharedInstance] getBulletinsWithSession:self.currentSession
                                                         success:^(NSURLSessionDataTask *task, id JSON) {
                                                             [[CurrentSession mainQueueContext] performBlockAndWait:^{
                                                                 [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Bulletin" withContext:[CurrentSession mainQueueContext]];

                                                                 if (JSON) {
                                                                     for (NSDictionary *bulletin in JSON) {
                                                                         [[CurrentSession mainQueueContext] insertObject:[[Bulletin alloc] initWithBulletinFromServer:bulletin context:[CurrentSession mainQueueContext]]];
                                                                     }
                                                                     [[CurrentSession mainQueueContext] save:nil];
                                                                 }
                                                                 [hud hide:NO];
                                                                 [self loadNext];
                                                             }];
                                                         } failure:^(NSURLSessionDataTask *task, NSError *apiError) {
                [[CurrentSession mainQueueContext] performBlockAndWait:^{
                    [[CoreDataUtil sharedManager] deleteAllObjectsAndSave:@"Bulletin" withContext:[CurrentSession mainQueueContext]];
                }];
                [hud hide:NO];
                [[[UIAlertView alloc] initWithTitle:@"Error" message:[apiError localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                NSLog(@"%@ Error loading bulletins: %@", [self class], [apiError localizedDescription]);
            }];
}

@end