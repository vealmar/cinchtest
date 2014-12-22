//
//  CIProductViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <JSONKit/JSONKit.h>
#import <Underscore.m/Underscore.h>
#import "CISlidingProductViewController.h"
#import "CIProductViewController.h"
#import "config.h"
#import "SettingsManager.h"
#import "CoreDataUtil.h"
#import "Order+Extensions.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "ShowConfigurations.h"
#import "AnOrder.h"
#import "CoreDataManager.h"
#import "CIProductViewControllerHelper.h"
#import "NilUtil.h"
#import "NumberUtil.h"
#import "Product.h"
#import "Vendor.h"
#import "Bulletin.h"
#import "Error.h"
#import "AProduct.h"
#import "MBProgressHUD.h"
#import "ProductCache.h"
#import "NotificationConstants.h"
#import "CinchJSONAPIClient.h"
#import "BulletinViewController.h"
#import "EditableEntity+Extensions.h"
#import "JMStaticContentTableViewController.h"
#import "Aspects.h"
#import "CINavViewManager.h"
#import "ThemeUtil.h"
#import "CIKeyboardUtil.h"
#import "CIProductTableViewController.h"
#import "CIBarButton.h"

@interface CIProductViewController () {
    NSInteger initialVendor;
    NSInteger currentVendor; //Logged in vendor's id or the vendor selected in the bulletin drop down
    int currentBulletin; //Bulletin selected in the bulletin drop down
    NSArray *vendorsData; //Vendors belonging to the same vendor group as the logged in vendors. These vendors are displayed in the bulletins drop down.
    NSDictionary *bulletins;
    CIProductViewControllerHelper *helper;
    CIFinalCustomerInfoViewController *customerInfoViewController;
}
@property(strong, nonatomic) AnOrder *savedOrder;
@property(nonatomic) BOOL unsavedChangesPresent;
@property CINavViewManager *navViewManager;

@property (strong, nonatomic) UIBarButtonItem *filterBarButtonItem;
@property (strong, nonatomic) JMStaticContentTableViewController *filterStaticController;
@property (strong, nonatomic) UISwitch *filterCartSwitch;
@end

@implementation CIProductViewController

#pragma mark - constructor

#define OrderRecoverySelectionYes  1
#define OrderRecoverySelectionNo  0
#define OrderRecoverySelectionNone  -1

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        helper = [[CIProductViewControllerHelper alloc] init];
    }
    return self;
}

#pragma mark - View lifecycle

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)reinit {
    self.delegate = nil;
    self.coreDataOrder = nil;
    self.savedOrder = nil;
    self.viewInitialized = NO;
    initialVendor = ![ShowConfigurations instance].vendorMode && self.loggedInVendorId && ![self.loggedInVendorId isKindOfClass:[NSNull class]] ? [self.loggedInVendorId intValue] : 0;
    currentVendor = initialVendor;
    currentBulletin = 0;
    self.filterCartSwitch = NO;
    self.vendorProductIds = [NSMutableArray array];
    self.vendorProducts = [NSMutableArray array];
    self.orderSubmitted = NO;
    self.selectedPrintStationId = 0;
    self.unsavedChangesPresent = NO;
    self.selectedCarts = [NSMutableSet set];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:0.133 green:0.129 blue:0.137 alpha:1];

    self.useShipDates = [ShowConfigurations instance].shipDates;
    self.allowPrinting = [ShowConfigurations instance].printing;
    initialVendor = ![ShowConfigurations instance].vendorMode && self.loggedInVendorId && ![self.loggedInVendorId isKindOfClass:[NSNull class]] ? [self.loggedInVendorId intValue] : 0;
    currentVendor = initialVendor;
    self.tableHeader.hidden = NO;
    self.tableHeaderMinColumnLabel.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    self.tableHeaderPrice1Label.text = [[ShowConfigurations instance] price1Label];
    self.tableHeaderPrice2Label.text = [[ShowConfigurations instance] price2Label];
    if (![ShowConfigurations instance].isOrderShipDatesType) self.btnSelectShipDates.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    if (!self.viewInitialized) {
        [self.productTableViewController prepareForDisplay:self];

        if (self.coreDataOrder == nil) {
            if (self.newOrder)
                [self createNewOrder];
            else
                [self loadOrder:OrderRecoverySelectionNone];
        }
        [self loadVendors];
        [self loadBulletins];
        [self loadProductsForCurrentVendorAndBulletin];
        [self deserializeOrder];
        self.viewInitialized = YES;
    } else {
        [self deserializeOrder];
    }

    self.vendorLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsUsernameKey];

    [self.vendorTable reloadData];
    [self updateErrorsView];

    if ([self.customer objectForKey:kBillName] != nil) self.customerLabel.text = [self.customer objectForKey:kBillName];

    // notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartQuantityChange:) name:CartQuantityChangedNotification object:nil];

    // listen for changes KVO
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(coreDataOrder)) options:0 context:nil];
    [self addObserver:self
           forKeyPath:[NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(coreDataOrder)), NSStringFromSelector(@selector(ship_dates))]
              options:0
              context:nil];

    CINavViewManager *navViewManager = self.navViewManager = [[CINavViewManager alloc] init:YES];
    navViewManager.delegate = self;
    [navViewManager setupNavBar];
    [self updateNavigationTitle];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.orderSubmitted) {
        [super viewDidAppear:animated];
        [self loadNotesForm];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(coreDataOrder))];
    [self removeObserver:self forKeyPath:[NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(coreDataOrder)), NSStringFromSelector(@selector(ship_dates))]];
}

# pragma mark - Initialization

- (void)loadVendors {
    NSArray *vendors = [CoreDataManager getVendors:self.managedObjectContext];
    if (vendors && vendors.count > 0) {//todo use AVendor objects
        NSMutableArray *vendorDataMutable = [[NSMutableArray alloc] init];
        for (Vendor *vendor in vendors) {
            [vendorDataMutable addObject:[vendor asDictionary]];
        }
        [vendorDataMutable insertObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Any", @"name", @"0", @"id", nil] atIndex:0];
        vendorsData = vendorDataMutable;
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Problem loading vendors! If this problem persists please notify Convention Innovations!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void)loadOrder:(int)orderRecoverySelection {
    orderRecoverySelection = OrderRecoverySelectionYes;

    Order *coreDataOrder = self.selectedOrder.coreDataOrder;//CIOrderViewController supplies the coredata order in the selectedorder when it is a partial order i.e. does not exist on the server.
    if (coreDataOrder == nil && self.selectedOrder.orderId != nil && [self.selectedOrder.orderId intValue] != 0) {//Must be a pending order i.e. exists on server.
        coreDataOrder = [CoreDataManager getOrder:self.selectedOrder.orderId managedObjectContext:self.managedObjectContext];
    }
    BOOL orderExistsInCoreData = coreDataOrder != nil;
    BOOL orderExistsOnServer = self.selectedOrder.orderId != nil && [self.selectedOrder.orderId intValue] != 0;
    if (orderExistsInCoreData && orderExistsOnServer) { //pending order in the middle of whose editing the app crashed, thus leaving a copy in core data.
        if (orderRecoverySelection == OrderRecoverySelectionNone) {//Prompt user to decide if they want to overlay server order with core data values.
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Recover Order?" message:@"It appears like the app crashed when you were working on this order. Would you like to recover the changes you had made?"
                                                           delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
            [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
                if ([[alert buttonTitleAtIndex:buttonIndex] isEqualToString:@"YES"]) {
                    [self loadOrder:OrderRecoverySelectionYes];
                } else
                    [self loadOrder:OrderRecoverySelectionNo];
                [self deserializeOrder];
            }];
        } else if (orderRecoverySelection == OrderRecoverySelectionNo) {
            [[CoreDataUtil sharedManager] deleteObject:coreDataOrder]; //delete existing core data entry. Start fresh with the order from server
            [[CoreDataUtil sharedManager] saveObjects];
            self.coreDataOrder = [helper createCoreDataCopyOfOrder:self.selectedOrder customer:self.customer loggedInVendorId:self.loggedInVendorId loggedInVendorGroupId:self.loggedInVendorGroupId managedObjectContext:self.managedObjectContext];
        } else if (orderRecoverySelection == OrderRecoverySelectionYes) {
            self.coreDataOrder = coreDataOrder; //Use the order from core data
            self.unsavedChangesPresent = YES;
        }
    } else if (orderExistsOnServer) {//pending order.
        self.coreDataOrder = [helper createCoreDataCopyOfOrder:self.selectedOrder customer:self.customer loggedInVendorId:self.loggedInVendorId loggedInVendorGroupId:self.loggedInVendorGroupId managedObjectContext:self.managedObjectContext];
    } else if (orderExistsInCoreData) {//partial order i.e. a brand new order in the middle of which the app crashed. Hence there is a copy in core data but none on server.
        self.coreDataOrder = coreDataOrder;
        self.unsavedChangesPresent = YES;
    }
}

- (void)loadProductsForCurrentVendorAndBulletin {
    [self.productTableViewController filterToVendorId:currentVendor bulletinId:currentBulletin queryTerm:nil];
    [self updateNavigationTitle];
}

- (void)createNewOrder {
    if (self.coreDataOrder == nil) {
        NSString *custId = [self.customer objectForKey:@"custid"];
        NSString *customerId = [[self.customer objectForKey:@"id"] stringValue];
        NSManagedObjectContext *context = self.managedObjectContext;
        self.coreDataOrder = [NSEntityDescription insertNewObjectForEntityForName:@"Order" inManagedObjectContext:context];
        [self.coreDataOrder setBillname:self.customerLabel.text];
        [self.coreDataOrder setCustomer_id:customerId];
        [self.coreDataOrder setCustid:custId];
        [self.coreDataOrder setStatus:@"partial"];
        [self.coreDataOrder setVendorGroup:self.loggedInVendorId];
        [self.coreDataOrder setVendorGroupId:self.loggedInVendorGroupId];
        [self.coreDataOrder setCustid:custId];
        [self.coreDataOrder setCustomer_id:customerId];
        [self.coreDataOrder setBillname:[self.customer objectForKey:kBillName]];
        NSError *error = nil;
        BOOL success = [context save:&error];
        if (!success) {
            NSLog(@"%s:%d Error saving new order: %@, %@", __func__, __LINE__, [error localizedDescription], [error userInfo]);
            NSString *msg = [NSString stringWithFormat:@"Error saving new order: %@", [error localizedDescription]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        } else
            self.unsavedChangesPresent = YES;
    }
}

- (void)deserializeOrder {
    [self reloadTable];
    [self updateTotals];
}

- (void)updateNavigationTitle {
    if (self.filterCartSwitch.on) {
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%s %b - %s", @"Products in", @"Cart", [self.customer objectForKey:kBillName]];
    } else if (currentBulletin) {
        NSArray *currentVendorBulletins = [bulletins objectForKey:[NSNumber numberWithInt:currentVendor]];
        NSDictionary *bulletin = Underscore.array(currentVendorBulletins).find(^BOOL(NSDictionary *bulletin) {
            NSNumber *bulletinId = (NSNumber *) [NilUtil nilOrObject:[bulletin objectForKey:kBulletinId]];
            return bulletinId && [bulletinId integerValue] == currentBulletin;
        });
        NSString *bulletinName = (NSString *) [NilUtil nilOrObject:[bulletin objectForKey:kBulletinName]];
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%b %s - %s", bulletinName, @"Products", [self.customer objectForKey:kBillName]];
    } else if (currentVendor && vendorsData) {
        NSDictionary *vendorDict = Underscore.array(vendorsData).find(^BOOL(NSDictionary *vendor) {
            NSNumber *vendorId = (NSNumber *) [NilUtil nilOrObject:[vendor objectForKey:kVendorID]];
            return [NilUtil nilOrObject:[vendor objectForKey:kVendorID]] && [vendorId integerValue] == currentVendor;
        });
        NSString *vendorName = (NSString *) [NilUtil nilOrObject:[vendorDict objectForKey:kVendorName]];
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%b %s - %s", vendorName, @"Products", [self.customer objectForKey:kBillName]];
    } else {
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%b %s - %s", @"All", @"Products", [self.customer objectForKey:kBillName]];
    }
}

- (void)loadBulletins {
    NSArray *coreDataBulletins = [CoreDataManager getBulletins:self.managedObjectContext];
    if (coreDataBulletins && coreDataBulletins.count > 0) {//todo use ABulletin objects
        NSMutableDictionary *bulls = [[NSMutableDictionary alloc] init];
        for (Bulletin *bulletin in coreDataBulletins) {
            NSDictionary *dict = [bulletin asDictionary];
            NSNumber *vendid = bulletin.vendor_id;
            if ([bulls objectForKey:vendid] == nil) {
                NSDictionary *any = [NSDictionary dictionaryWithObjectsAndKeys:@"Any", @"name", [NSNumber numberWithInt:0], @"id", nil];
                NSMutableArray *arr = [[NSMutableArray alloc] init];
                [arr addObject:any];
                [bulls setObject:arr forKey:vendid];
            }
            [[bulls objectForKey:vendid] addObject:dict];
        }
        bulletins = bulls;
    }
}

- (void)updateErrorsView {
    NSSet *warnings = self.coreDataOrder ? self.coreDataOrder.warnings : [NSSet new];
    NSSet *errors = self.coreDataOrder ? self.coreDataOrder.errors : [NSSet new];
    if (warnings.count > 0 || errors.count > 0) {
        self.errorMessageTextView.attributedText = [self.coreDataOrder buildMessageSummary];
        self.errorMessageTextView.hidden = NO;
    } else {
        self.errorMessageTextView.text = @"";
        self.errorMessageTextView.hidden = YES;
    }
}

- (void)toggleCartSelection:(Cart *)cart {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.selectedCarts containsObject:cart]) {
            [self.selectedCarts removeObject:cart];
            dispatch_async(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [[NSNotificationCenter defaultCenter] postNotificationName:CartDeselectionNotification object:cart];
                }
            });
        } else {
            [self.selectedCarts addObject:cart];
            dispatch_async(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [[NSNotificationCenter defaultCenter] postNotificationName:CartSelectionNotification object:cart];
                }
            });
        }
    });
}

#pragma mark - VendorViewDelegate

- (void)setVendor:(NSInteger)vendorId {
    currentVendor = vendorId;
    currentBulletin = 0;
    [((UINavigationController*)self.poController.contentViewController) popViewControllerAnimated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.filterStaticController.tableView reloadData];
    });

    [self loadProductsForCurrentVendorAndBulletin];
    [self updateFilterButtonState];
}

- (void)setBulletin:(NSInteger)bulletinId {
    currentBulletin = bulletinId;
    [((UINavigationController*)self.poController.contentViewController) popViewControllerAnimated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.filterStaticController.tableView reloadData];
    });

    [self loadProductsForCurrentVendorAndBulletin];
    [self updateFilterButtonState];
}

- (void)dismissVendorPopover {
    return;
    
    if ([self.poController isPopoverVisible])
        [self.poController dismissPopoverAnimated:YES];
    [self loadProductsForCurrentVendorAndBulletin];
}

- (void)filterCartSwitchChanged {
    [self loadProductsForCurrentVendorAndBulletin];
    [self updateFilterButtonState];
}

/**
* SG: This is the Bulletins drop down.
*/
- (void)showFilterView {

    if (!self.filterCartSwitch) {
        self.filterCartSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        self.filterCartSwitch.on = NO;
        [self.filterCartSwitch addTarget:self action:@selector(filterCartSwitchChanged) forControlEvents:UIControlEventValueChanged];
    }

    if (!self.filterStaticController) {
        self.filterStaticController = [[JMStaticContentTableViewController alloc] initWithStyle:UITableViewStylePlain];

        __weak typeof(self) weakSelf = self;
        [self.filterStaticController addSection:^(JMStaticContentTableViewSection *section, NSUInteger sectionIndex) {
            [section addCell:^(JMStaticContentTableViewCell *staticContentCell, UITableViewCell *cell, NSIndexPath *indexPath) {
                staticContentCell.reuseIdentifier = @"UIControlCell";
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.text = @"In Cart";
                cell.accessoryView = weakSelf.filterCartSwitch;
            }];

            [section addCell:^(JMStaticContentTableViewCell *staticContentCell, UITableViewCell *cell, NSIndexPath *indexPath) {
                staticContentCell.cellStyle = UITableViewCellStyleValue1;
                staticContentCell.reuseIdentifier = @"DetailTextCell";

                cell.textLabel.text = @"Vendor";

                if (currentVendor == 0) {
                    cell.detailTextLabel.text = @"All";
                } else {
                    for (NSDictionary *vendor in vendorsData) {
                        if ([vendor[@"id"] intValue] == currentVendor) {
                            cell.detailTextLabel.text = vendor[@"name"];
                            break;
                        }
                    }
                }
            } whenSelected:^(NSIndexPath *indexPath) {
                VendorViewController *vendorViewController = [[VendorViewController alloc] initWithNibName:@"VendorViewController" bundle:nil];
                vendorViewController.vendors = [NSArray arrayWithArray:vendorsData];
                if (bulletins != nil) vendorViewController.bulletins = [NSDictionary dictionaryWithDictionary:bulletins];
                vendorViewController.delegate = self;

                [self.filterStaticController.navigationController pushViewController:vendorViewController animated:YES];
            }];

            [section addCell:^(JMStaticContentTableViewCell *staticContentCell, UITableViewCell *cell, NSIndexPath *indexPath) {
                staticContentCell.cellStyle = UITableViewCellStyleValue1;
                staticContentCell.reuseIdentifier = @"DetailTextCell";

                cell.textLabel.text = @"Brand";

                if (currentBulletin == 0) {
                    cell.detailTextLabel.text = @"All";
                } else {
                    if (currentVendor == 0) {
                        cell.detailTextLabel.text = @"All";
                    } else {
                        NSArray *items = bulletins[@(currentVendor)];
                        for (NSDictionary *item in items) {
                            if ([item[@"id"] intValue] == currentBulletin) {
                                cell.detailTextLabel.text = item[@"name"];
                                break;
                            }
                        }
                    }
                }

            }   whenSelected:^(NSIndexPath *indexPath) {
                BulletinViewController *bulletinViewController = [[BulletinViewController alloc] initWithNibName:@"BulletinViewController" bundle:nil];
                bulletinViewController.bulletins = [NSDictionary dictionaryWithDictionary:bulletins];
                bulletinViewController.currentVendId = currentVendor;
                bulletinViewController.delegate = self;

                [self.filterStaticController.navigationController pushViewController:bulletinViewController animated:YES];
            }];
        }];

        [self.filterStaticController aspect_hookSelector:@selector(viewWillAppear:) withOptions:AspectPositionAfter usingBlock:^(id instance, NSArray *args) {
            self.filterStaticController.tableView.separatorColor = [UIColor colorWithRed:0.839 green:0.839 blue:0.851 alpha:1];
            self.filterStaticController.navigationController.navigationBarHidden = YES;
            self.poController.popoverContentSize = CGSizeMake(320, 133);
            NSLog(@"appears");
        }                                          error:nil];

        [self.filterStaticController aspect_hookSelector:@selector(viewWillDisappear:) withOptions:AspectPositionAfter usingBlock:^(id instance, NSArray *args) {
            [self.poController setPopoverContentSize:CGSizeMake(320, 480) animated:YES];
            NSLog(@"disapp");
        }                                          error:nil];


        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.filterStaticController];
        nav.navigationBarHidden = NO;
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
        nav.navigationItem.backBarButtonItem = backButton;

        self.poController = [[UIPopoverController alloc] initWithContentViewController:nav];
    }

    [self.poController presentPopoverFromBarButtonItem:self.filterBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)closeCalendar {
    if ([ShowConfigurations instance].isLineItemShipDatesType) {
        // close calendar
        if (self.selectedCarts.count == 1) {
            [self.selectedCarts enumerateObjectsUsingBlock:^(Cart *cart, BOOL *stop) {
                [self toggleCartSelection:cart]; //disable selection
            }];
            [self.slidingProductViewControllerDelegate toggleShipDates:NO];
        }
    }
}

#pragma mark - Events

- (IBAction)Cancel:(id)sender {
    if ([self.coreDataOrder.orderId intValue] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cancel Order?" message:@"This will cancel the current order." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [alertView show];
    } else if (self.unsavedChangesPresent) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Exit Without Saving?" message:@"There are some unsaved changes. Are you sure you want to exit without saving?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alertView withCallBack:^(NSInteger buttonIndex) {
            if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
                [self Return];
            }
        }];
    } else {
        [self Return];
    }
}

- (void)loadPrintersAndPromptForSelection {
    [[CinchJSONAPIClient sharedInstance] GET:kDBGETPRINTERS parameters:@{ kAuthToken: self.authToken } success:^(NSURLSessionDataTask *task, id JSON) {
        if (JSON != nil && [JSON isKindOfClass:[NSArray class]] && [JSON count] > 0) {
            NSMutableDictionary *printStations = [[NSMutableDictionary alloc] initWithCapacity:[JSON count]];
            for (NSDictionary *printer in JSON) {
                [printStations setObject:printer forKey:[printer objectForKey:@"name"]];
            }
            self.availablePrinters = [NSDictionary dictionaryWithDictionary:printStations];
            if (self.availablePrinters == nil || self.availablePrinters.count == 0) {
                NSString *msg = @"No printers are available. Order will not be printed.";
                [[[UIAlertView alloc] initWithTitle:@"No Printers" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                [self sendOrderToServer:NO ];
            } else {
                [self prompForPrinterSelection];
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSString *msg = [NSString stringWithFormat:@"Unable to load available printers. Order will not be printed. %@", [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"No Printers" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }];
}

- (void)loadNotesForm {
    if ([helper isOrderReadyForSubmission:self.coreDataOrder]) {
        if (customerInfoViewController == nil) {
            customerInfoViewController = [[CIFinalCustomerInfoViewController alloc] init];
            customerInfoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            customerInfoViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            customerInfoViewController.delegate = self;
        }
        customerInfoViewController.order = self.coreDataOrder;
        [self presentViewController:customerInfoViewController animated:YES completion:nil];
    }
}

- (void)reviewCart {
    if ([helper isOrderReadyForSubmission:self.coreDataOrder]) {
        CICartViewController *cart = [[CICartViewController alloc] initWithOrder:self.coreDataOrder customer:self.customer authToken:self.authToken selectedVendorId:[NSNumber numberWithInt:currentVendor] loggedInVendorId:self.loggedInVendorId loggedInVendorGroupId:self.loggedInVendorGroupId andManagedObjectContext:self.managedObjectContext];
        cart.delegate = self;
//        cart.modalPresentationStyle = UIModalPresentationFullScreen;
//        [self presentViewController:cart animated:YES completion:nil];
        [self.navigationController pushViewController:cart animated:YES];
    }
}

- (BOOL)findAndResignFirstResponder:(UIView *)view {
    if (view.isFirstResponder) {
        [view resignFirstResponder];
        return YES;
    } else if (view.subviews && view.subviews.count > 0) {
        for (UIView *subView in view.subviews) {
            if ([self findAndResignFirstResponder:subView]) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark Keyboard Adjustments

- (void)keyboardWillShow:(NSNotification *)note {
    [CIKeyboardUtil keyboardWillShow:note adjustConstraint:self.keyboardHeightFooter in:self.view];
}

- (void)keyboardDidHide:(NSNotification *)note {
    [CIKeyboardUtil keyboardWillHide:note adjustConstraint:self.keyboardHeightFooter in:self.view];
}

- (void)sendOrderToServer:(BOOL)printThisOrder {
    if (![helper isOrderReadyForSubmission:self.coreDataOrder]) {return;}
    self.coreDataOrder.status = @"complete";
    self.coreDataOrder.print = [NSNumber numberWithBool:printThisOrder];
    self.coreDataOrder.printer = printThisOrder ? [NSNumber numberWithInt:self.selectedPrintStationId] : nil;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:[self.coreDataOrder asJSONReqParameter]];
    parameters[kAuthToken] = self.authToken;
    NSString *method = [self.coreDataOrder.orderId intValue] > 0 ? @"PUT" : @"POST";
    NSString *url = [self.coreDataOrder.orderId intValue] == 0 ? kDBORDER : kDBORDEREDITS([self.coreDataOrder.orderId intValue]);
    void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
        self.savedOrder = [self loadJson:JSON];
        [self Return];
    };
    void (^failureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (JSON) {
            [self loadJson:JSON];
        }
    };
    [helper sendRequest:method url:url parameters:parameters successBlock:successBlock failureBlock:failureBlock view:self.view loadingText:@"Submitting order"];
}

- (AnOrder *)loadJson:(id)JSON {
    AnOrder *anOrder = [[AnOrder alloc] initWithJSONFromServer:(NSDictionary *) JSON];
    [self.managedObjectContext deleteObject:self.coreDataOrder];//delete existing core data representation
    self.coreDataOrder = [helper createCoreDataCopyOfOrder:anOrder customer:self.customer loggedInVendorId:self.loggedInVendorId loggedInVendorGroupId:self.loggedInVendorGroupId managedObjectContext:self.managedObjectContext];//create fresh new core data representation
    [[CoreDataUtil sharedManager] saveObjects];
    [self reloadTable];
    [self updateTotals];
    [self updateErrorsView];
    return anOrder;
}

- (void)reloadTable {
    [self.productTableViewController.tableView reloadData];
}

- (void)updateTotals {
    NSArray *totals = [helper getTotals:self.coreDataOrder];
    self.totalCost.text = [NumberUtil formatDollarAmount:totals[0]];
}

#pragma mark - CIFinalCustomerDelegate

- (void)dismissFinalCustomerViewController {
    [customerInfoViewController dismissViewControllerAnimated:NO completion:nil];
}

- (NSDictionary *)getCustomerInfo {
    return [self.customer copy];
}

//Called from the authorization, notes etc. popup
- (IBAction)submit:(id)sender {
    if (self.allowPrinting) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to print the order after submission?" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", @"No", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
            if (buttonIndex == 1) { // YES
                if (self.selectedPrintStationId == 0) {
                    if (self.availablePrinters == nil) {
                        [self loadPrintersAndPromptForSelection];
                    } else {
                        [self prompForPrinterSelection];
                    }
                } else {
                    [self sendOrderToServer:YES ];
                }
            } else { // NO
                [self sendOrderToServer:NO ];
            }
        }];
    } else {
        [self sendOrderToServer:NO ];
    }
}

#pragma - UIPrinterSelectedDelegate

- (void)setSelectedPrinter:(NSString *)printer {
    [self.poController dismissPopoverAnimated:YES];
    [[SettingsManager sharedManager] saveSetting:@"printer" value:printer];
    self.selectedPrintStationId = [[[self.availablePrinters objectForKey:printer] objectForKey:@"id"] intValue];
    [self sendOrderToServer:YES ];
}

- (void)prompForPrinterSelection {
    PrinterSelectionViewController *psvc = [[PrinterSelectionViewController alloc] initWithNibName:@"PrinterSelectionViewController" bundle:nil];
    psvc.title = @"Available Printers";
    NSArray *keys = [[[self.availablePrinters allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] copy];
    psvc.availablePrinters = [NSArray arrayWithArray:keys];
    psvc.delegate = self;
    CGRect frame = self.cartButton.frame;
    frame = CGRectOffset(frame, 0, 0);
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:psvc];
    self.poController = [[UIPopoverController alloc] initWithContentViewController:nav];
    [self.poController presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - ProductCellDelegate

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSString *orderShipDatesKeyPath = [NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(coreDataOrder)), NSStringFromSelector(@selector(ship_dates))];
    if ([NSStringFromSelector(@selector(coreDataOrder)) isEqualToString:keyPath]) {
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            NSString *msg = [NSString stringWithFormat:@"There was an error saving the product item. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    } else if ([orderShipDatesKeyPath isEqualToString:keyPath]) {
        [self.productTableViewController.tableView reloadData];
        [self updateTotals];
    }
}

- (void)onCartQuantityChange:(NSNotification *)notification {
    [self updateTotals];
    self.unsavedChangesPresent = YES;
}

- (void)QtyTouchForIndex:(NSNumber *)productId {
    if ([ShowConfigurations instance].isLineItemShipDatesType) {
        Cart *cart = [self.coreDataOrder findOrCreateCartForId:productId
                                                       context:self.managedObjectContext];

        if (self.selectedCarts.count == 1) {
            [self closeCalendar];
        } else {
            [self toggleCartSelection:cart];
            self.slidingProductViewControllerDelegate.shipDateController.workingCart = cart;
            [self.slidingProductViewControllerDelegate toggleShipDates:YES];
        }

        [self.searchText resignFirstResponder];
    }
}

- (Order *)currentOrderForCell {
    return self.coreDataOrder;
}

- (void)ShowPriceChange:(double)price productId:(NSNumber *)productId {
    [self.coreDataOrder updateItemShowPrice:@(price) productId:productId context:self.managedObjectContext];
    self.unsavedChangesPresent = YES;
    [self updateTotals];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        [self Return];
    }
}

#pragma CICartViewDelegate
- (void)cartViewDismissedWith:(Order *)coreDataOrder savedOrder:(AnOrder *)savedOrder unsavedChangesPresent:(BOOL)unsavedChangesPresent orderCompleted:(BOOL)orderCompleted {
    self.coreDataOrder = coreDataOrder;
    self.savedOrder = savedOrder;
    self.unsavedChangesPresent = unsavedChangesPresent;
    self.orderSubmitted = orderCompleted;
}

#pragma Return
- (void)Return {
    enum OrderUpdateStatus status = [self.selectedOrder.status isEqualToString:@"partial"] && self.savedOrder == nil? PartialOrderCancelled
            : [self.selectedOrder.status isEqualToString:@"partial"] && self.savedOrder != nil? PartialOrderSaved
                    : [self.selectedOrder.orderId intValue] != 0 && self.savedOrder == nil? PersistentOrderUnchanged
                            : !self.newOrder && [self.selectedOrder.orderId intValue] != 0 && self.savedOrder != nil? PersistentOrderUpdated
                                    : self.newOrder && self.savedOrder == nil? NewOrderCancelled
                                            : NewOrderCreated;

        [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate != nil) {
            NSNumber *orderId = nil;
            if (self.coreDataOrder != nil) {
                orderId = self.coreDataOrder != nil? self.coreDataOrder.orderId : nil;
                [[CoreDataUtil sharedManager] deleteObject:self.coreDataOrder];  //always delete the core data entry before exiting this view. core data should contain an entry only if the order crashed in the middle of an order
            }
            [self.delegate Return:orderId order:self.savedOrder updateStatus:status];
            [self reinit]; //clear up memory
        }
    }];
}

- (void)dealloc {
    DLog(@"Deallocing CIProductViewController");
}

#pragma mark - CINavViewManagerDelegate

- (UINavigationController *)navigationControllerForNavViewManager {
    return self.navigationController;
}

- (UINavigationItem *)navigationItemForNavViewManager {
    return self.parentViewController.navigationItem;
}

- (NSArray *)leftActionItems {
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"\uf00d" style:UIBarButtonItemStylePlain handler:^(id sender) {
        [self Cancel:nil];
    }];
    return @[cancelItem];
}

- (NSArray *)rightActionItems {
    if (!self.filterBarButtonItem) {
        CIBarButton *filterBarButton = [[CIBarButton alloc] initWithText:@"" style:CIBarButtonStyleRoundButton handler:^(id sender) {
            [self showFilterView];
        }];
        NSDictionary *labelAttributes = [ThemeUtil navigationRightActionButtonTextAttributes];
        filterBarButton.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue140" attributes:Underscore.extend(labelAttributes, @{
            NSFontAttributeName: [UIFont iconAltFontOfSize:14],
        })];
        [filterBarButton setBackgroundColor:[ThemeUtil offWhiteColor] borderColor:[ThemeUtil offWhiteBorderColor] textColor:[ThemeUtil offBlackColor] forControlState:UIControlStateNormal];
        [filterBarButton setBackgroundColor:[ThemeUtil lightBlueColor] borderColor:[ThemeUtil lightBlueBorderColor] textColor:nil forControlState:UIControlStateHighlighted];

        self.filterBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:filterBarButton];
    }

    UIBarButtonItem *addItem = [CIBarButton buttonItemWithText:@"\uf07a" style:CIBarButtonStyleRoundButton handler:^(id sender) {
        [self reviewCart];
    }];
    return @[addItem, self.filterBarButtonItem];
}

- (void)navViewDidSearch:(NSString *)searchTerm inputCompleted:(BOOL)inputCompleted {
    [self.productTableViewController filterToVendorId:currentVendor bulletinId:currentBulletin queryTerm:searchTerm];
}

- (void)updateFilterButtonState {
    ((CIBarButton *) self.filterBarButtonItem.customView).active = (0 != currentBulletin ||
            initialVendor != currentVendor ||
            self.filterCartSwitch.on);
}

@end