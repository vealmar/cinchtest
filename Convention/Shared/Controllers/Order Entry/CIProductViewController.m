//
//  CIProductViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <JSONKit/JSONKit.h>
#import "CISlidingProductViewController.h"
#import "CIProductViewController.h"
#import "config.h"
#import "SettingsManager.h"
#import "CoreDataUtil.h"
#import "Order+Extensions.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "FarrisProductCell.h"
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
#import "Cart+Extensions.h"
#import "ProductSearch.h"
#import "ProductSearchQueue.h"
#import "CinchJSONAPIClient.h"
#import "BulletinViewController.h"
#import "EditableEntity+Extensions.h"

@interface CIProductViewController () {
    NSInteger currentVendor; //Logged in vendor's id or the vendor selected in the bulletin drop down
    int currentBulletin; //Bulletin selected in the bulletin drop down
    NSArray *vendorsData; //Vendors belonging to the same vendor group as the logged in vendors. These vendors are displayed in the bulletins drop down.
    NSDictionary *bulletins;
    NSIndexPath *selectedItemRowIndexPath;
    CIProductViewControllerHelper *helper;
    PullToRefreshView *pull;
    BOOL keyboardUp;
    float keyboardHeight;
    CIFinalCustomerInfoViewController *customerInfoViewController;
}
@property(strong, nonatomic) AnOrder *savedOrder;
@property(nonatomic) BOOL unsavedChangesPresent;
@property ProductSearchQueue *productSearchQueue;
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
    currentVendor = 0;
    currentBulletin = 0;
    self.vendorProductIds = [NSMutableArray array];
    self.vendorProducts = [NSMutableArray array];
    self.multiStore = NO;
    self.orderSubmitted = NO;
    self.selectedPrintStationId = 0;
    self.unsavedChangesPresent = NO;
    keyboardUp = NO;
    self.selectedCarts = [NSMutableSet set];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.useShipDates = [ShowConfigurations instance].shipDates;
    self.allowPrinting = [ShowConfigurations instance].printing;
    self.contactBeforeShipping = [ShowConfigurations instance].contactBeforeShipping;
    self.cancelOrderConfig = [ShowConfigurations instance].cancelOrder;
    self.poNumberConfig = [ShowConfigurations instance].poNumber;
    self.paymentTermsConfig = [ShowConfigurations instance].paymentTerms;
    self.useOrderBasedShipDates = self.useShipDates && [[ShowConfigurations instance] isOrderShipDatesType];
    self.multiStore = [[self.customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [self.customer objectForKey:kStores]) count] > 0;
    pull = [[PullToRefreshView alloc] initWithScrollView:self.productsTableView];
    [pull setDelegate:self];
    [self.productsTableView addSubview:pull];
    currentVendor = ![ShowConfigurations instance].vendorMode && self.loggedInVendorId && ![self.loggedInVendorId isKindOfClass:[NSNull class]] ? [self.loggedInVendorId intValue] : 0;
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        self.tableHeaderPigglyWiggly.hidden = NO;
        self.tableHeaderFarris.hidden = YES;
    } else {
        self.tableHeaderPigglyWiggly.hidden = YES;
        self.tableHeaderFarris.hidden = NO;
        self.tableHeaderMinColumnLabel.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    }
    if (![ShowConfigurations instance].isOrderShipDatesType) self.btnSelectShipDates.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    if (!self.viewInitialized) {
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
    if (keyboardUp) {
        //if the frame size was decreased to accomodate the keyboard right before cart was launched,
        //when the view reappears, the keyboard would have been hidden (without keyboard hide notification being sent out it seems)
        //so it is important to undo the frame resize at this point.
        [self keyboardDidHide];
    }

    self.vendorLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingsUsernameKey];

    [self.vendorTable reloadData];
    [self updateErrorsView];

    self.productSearchQueue = [[ProductSearchQueue alloc] initWithProductController:self];
    if ([self.customer objectForKey:kBillName] != nil) self.customerLabel.text = [self.customer objectForKey:kBillName];

    // notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartQuantityChange:) name:CartQuantityChangedNotification object:nil];

    // listen for changes KVO
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(coreDataOrder)) options:0 context:nil];
    [self addObserver:self
           forKeyPath:[NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(coreDataOrder)), NSStringFromSelector(@selector(ship_dates))]
              options:0
              context:nil];
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(resultData)) options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.orderSubmitted) {
        [super viewDidAppear:animated];
        [self loadNotesForm];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    self.productSearchQueue = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(coreDataOrder))];
    [self removeObserver:self forKeyPath:[NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(coreDataOrder)), NSStringFromSelector(@selector(ship_dates))]];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(resultData))];
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

- (void)reloadProducts {

    MBProgressHUD *submit = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    submit.removeFromSuperViewOnHide = YES;
    submit.labelText = @"Loading Products";
    [submit show:NO];

    void (^successBlock)(id) = ^(id json) {
        [self loadProductsForCurrentVendorAndBulletin];//this method includes a call to reloadtable
        [pull finishedLoading];
        [self adjustTableInset]; //pull.finishedLoading resets the content offsets
        [submit hide:NO];
    };
    void (^failureBlock)() = ^() {
        [pull finishedLoading];
        [self adjustTableInset]; //pull.finishedLoading resets the content offsets
        [submit hide:NO];
    };

    [CoreDataManager reloadProducts:self.authToken
                      vendorGroupId:self.loggedInVendorGroupId
               managedObjectContext:self.managedObjectContext
                          onSuccess:successBlock
                          onFailure:failureBlock];

}

- (void)loadProductsForCurrentVendorAndBulletin {
    NSMutableArray *products = [[NSMutableArray alloc] init];
    self.vendorProductIds = [[NSMutableArray alloc] init];
    self.vendorProducts = [[NSMutableArray alloc] init];
    [[CoreDataManager getProducts:self.managedObjectContext] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Product *product = (Product *) obj;
        NSNumber *vendorId = product.vendor_id;
        if (currentVendor == 0 || (vendorId && [vendorId integerValue] == currentVendor)) {
            NSNumber *productId = product.productId;
            [self.vendorProductIds addObject:productId];
            [self.vendorProducts addObject:[[AProduct alloc] initWithCoreDataProduct:product]];
            NSNumber *bulletinId = product.bulletin_id;
            if (currentBulletin == 0 || (bulletinId && [bulletinId integerValue] == currentBulletin))
                [products addObject:product];
        }
    }];
    NSArray *sortedProducts = [helper sortProductsByinvtId:products];
    NSMutableArray *sortedProductIds = [NSMutableArray array];
    for (Product *product in sortedProducts) {
        [sortedProductIds addObject:product.productId];
    }
    self.resultData = sortedProductIds;
    [self updateVendorAndBulletinLabel];
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

- (void)updateVendorAndBulletinLabel {
    NSMutableString *labelText = [NSMutableString string];
    if (currentVendor) {
        if (vendorsData) {
            [labelText appendString:[helper displayNameForVendor:currentVendor vendorDisctionaries:vendorsData]];
        }
    }
    if (currentBulletin) {
        if (bulletins) {
            NSArray *currentVendorBulletins = [bulletins objectForKey:[NSNumber numberWithInt:currentVendor]];
            if (currentVendorBulletins) {
                for (NSDictionary *bulletin in currentVendorBulletins) {
                    NSNumber *bulletinId = (NSNumber *) [NilUtil nilOrObject:[bulletin objectForKey:kBulletinId]];
                    if (bulletinId && [bulletinId integerValue] == currentBulletin) {
                        NSString *bulletinName = (NSString *) [NilUtil nilOrObject:[bulletin objectForKey:kBulletinName]];
                        if (bulletinName == nil)
                            bulletinName = [bulletinId stringValue];
                        if ([labelText length] > 0)
                            [labelText appendString:@" / "];
                        [labelText appendString:bulletinName];
                        break;
                    }
                }
            }
        }
    }
    self.bulletinVendorLabel.text = labelText;
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
//        int row = [self.resultData indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
//            // obj should be a productId
//            return [obj isEqual:blockCart.cartId];
//        }];
//
//        if (row != NSNotFound) {
//            UITableViewCell *productCell = [self.productsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
//            if ([self.selectedCarts containsObject:blockCart]) {
//                productCell.accessoryType = UITableViewCellAccessoryNone;
//            } else {
//                if (![blockCart.product.invtid isEqualToString:@"0"]) {
//                    // todo revert this back to checkmark; right now the checks are showing up in random places when we change bulletins
//                    productCell.accessoryType = UITableViewCellAccessoryNone;
//                }
//            }
//        }

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

#pragma mark - Other Views

/**
* SG: This is the Bulletins drop down.
*/
- (void)showVendorView {
    UIViewController *rootDropdownController;
    if ([ShowConfigurations instance].vendorMode) {
        BulletinViewController *bulletinViewController = [[BulletinViewController alloc] initWithNibName:@"BulletinViewController" bundle:nil];
        bulletinViewController.bulletins = [NSDictionary dictionaryWithDictionary:bulletins];
        bulletinViewController.delegate = self;
        rootDropdownController = bulletinViewController;
    } else {
        VendorViewController *vendorViewController = [[VendorViewController alloc] initWithNibName:@"VendorViewController" bundle:nil];
        vendorViewController.vendors = [NSArray arrayWithArray:vendorsData];
        if (bulletins != nil) vendorViewController.bulletins = [NSDictionary dictionaryWithDictionary:bulletins];
        vendorViewController.delegate = self;
        rootDropdownController = vendorViewController;
    }

    CGRect frame = self.vendorDropdown.frame;
    frame = CGRectOffset(frame, 0, 0);

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootDropdownController];
    nav.navigationBarHidden = NO;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    nav.navigationItem.backBarButtonItem = backButton;

    self.poController = [[UIPopoverController alloc] initWithContentViewController:nav];
    [self.poController presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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

#pragma mark - UITableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    return [self.resultData count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) [indexPath row]];
    [helper updateCellBackground:cell order:self.coreDataOrder cart:[self.coreDataOrder findCartForProductId:productId]];
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) [indexPath row]];
    AProduct *product = [[ProductCache sharedCache] getProduct:productId];
    UITableViewCell *cell = [helper dequeueReusableProductCell:myTableView];
    [(FarrisProductCell *)cell initializeWithAProduct:product cart:[self.coreDataOrder findOrCreateCartForId:product.productId context:self.managedObjectContext] tag:[indexPath row] ProductCellDelegate:self];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[ShowConfigurations instance] isLineItemShipDatesType]) {
        NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) [indexPath row]];
        Cart *cart = [self.coreDataOrder findOrCreateCartForId:productId context:self.managedObjectContext];
        [self toggleCartSelection:cart];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[ShowConfigurations instance] isLineItemShipDatesType]) {
        NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) [indexPath row]];
        Cart *cart = [self.coreDataOrder findOrCreateCartForId:productId context:self.managedObjectContext];
        [self toggleCartSelection:cart];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *productId = self.resultData[(NSUInteger) indexPath.row];
    Cart *cart = [self.coreDataOrder findCartForProductId:productId];

    if (cart.warnings.count > 0 || cart.errors.count > 0)
        return 44 + ((cart.warnings.count + cart.errors.count) * 42);
    else
        return 44;
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

- (IBAction)vendorTouch:(id)sender {
    if (!self.vendorView.hidden && !self.dismissVendor.hidden) {
        self.vendorView.hidden = YES;
        self.dismissVendor.hidden = YES;
        return;
    }
    [self.selectedCarts removeAllObjects];
    if (vendorsData && [vendorsData count] > 0) {
        [self showVendorView];
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

/**
* SG: This method is called when user taps the cart button.
*/
- (IBAction)reviewCart:(id)sender {
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

- (IBAction)dismissVendorTouched:(id)sender {
    self.vendorView.hidden = YES;
    self.dismissVendor.hidden = YES;
}

- (IBAction)shipdatesTouched:(id)sender {
    [self.view endEditing:YES];
    [self.slidingProductViewControllerDelegate toggleShipDates:YES];
}

- (IBAction)searchDidBeginEditing:(UITextField *)sender {
    sender.text = @"";
    [self closeCalendar];

    [self searchProducts:sender.text searchIsActive:YES];
}

- (IBAction)searchDidChangeEditing:(UITextField *)sender {
    [self searchProducts:sender.text searchIsActive:YES];
}

- (IBAction)searchDidReturnKey:(id)sender {
    [self searchProducts:((UITextField *) sender).text searchIsActive:NO];
}

- (IBAction)searchDidEndEditing:(UITextField *)sender {
    [self searchProducts:sender.text searchIsActive:NO];
}

- (IBAction)searchButtonPressed:(UIButton *)sender {
    [self searchProducts:self.searchText.text searchIsActive:NO];
}

- (void)searchProducts:(NSString *)queryString searchIsActive:(BOOL)searchIsActive {
    if (self.vendorProducts == nil|| [self.vendorProducts isKindOfClass:[NSNull class]] || [self.vendorProducts count] == 0) return;
    queryString = [queryString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (queryString.length == 0) {
        self.resultData = [self.vendorProductIds mutableCopy];
    } else {
        NSUInteger limit = searchIsActive ? 50 : 0; //0 indicates no limit
        //if search is active i.e. we are doing limited search, query all product attributes and add them to the cahce since they will be needed when table is reloaded.
        //if search is not active, query only product ids since the result might include a large number of products and the table reload will only show 10-20 cells.
        ProductSearch *productSearch = [ProductSearch searchFor:queryString inBulletin:currentBulletin forVendor:currentVendor limitResultSize:limit usingContext:self.managedObjectContext];
        [self.productSearchQueue search:productSearch];
        [self.selectedCarts removeAllObjects];
        selectedItemRowIndexPath = nil;
    }
}

- (void)keyboardWillShow:(NSNotification *)note {
    // Reducing the frame height by 300 causes it to end above the keyboard, so the keyboard cannot overlap any content. 300 is the height occupied by the keyboard.
    // In addition scroll the selected row into view.
    NSDictionary *info = [note userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    //todo maybe we should be scrolling the parent view of the table (put table and totals view inside a view and that will be the parent we scroll?)
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    [self addInsetToTable:kbSize.width - 69];//width because landscape. 69 is height of the view that contains totals at the end of the table.
    if (selectedItemRowIndexPath && [self.resultData count] > [selectedItemRowIndexPath row]) //while you are editing quantity and typing in search field fast, you can reach a situation where selectedItemRowIndexPath is no longer valid.
        [self.productsTableView scrollToRowAtIndexPath:selectedItemRowIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    keyboardUp = YES;
    keyboardHeight = kbSize.width;
    [UIView commitAnimations];
}

- (void)addInsetToTable:(float)insetHeight {
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, insetHeight, 0.0); //width because landscape. 69 is height of the view that contains totals at the end of the table.
    self.productsTableView.contentInset = contentInsets;
    self.productsTableView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardDidHide {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.productsTableView.contentInset = contentInsets;
    self.productsTableView.scrollIndicatorInsets = contentInsets;
    keyboardUp = NO;
    [UIView commitAnimations];
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
    [self.productsTableView reloadData];
    [self adjustTableInset];
}

- (void)adjustTableInset {
    if (keyboardUp) {
        [self addInsetToTable:keyboardHeight - 69];//width because landscape. 69 is height of the view that contains totals at the end of the table.
    }
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
        [self.productsTableView reloadData];
        [self updateTotals];
    } else if ([NSStringFromSelector(@selector(resultData)) isEqualToString:keyPath]) {
        [self reloadTable];
    }
}

- (void)onCartQuantityChange:(NSNotification *)notification {
    Cart *cart = (Cart *) notification.object;
    int idx = [self.resultData indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        // obj should be a productId
        return [obj isEqual:cart.cartId];
    }];
    if (idx != NSNotFound) {
        FarrisProductCell *cell = [self.productsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        cell.quantity.text = [NSString stringWithFormat:@"%i", cart.totalQuantity];
        [self updateCellColorForId:(NSUInteger) idx];
    }
    [self updateTotals];

    self.unsavedChangesPresent = YES;
}

- (void)QtyTouchForIndex:(int)idx {

    if ([ShowConfigurations instance].isLineItemShipDatesType) {
        NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) idx];
        Cart *cart = [self.coreDataOrder findOrCreateCartForId:productId
                                                       context:self.managedObjectContext];

        if (self.selectedCarts.count == 1) {
            [self closeCalendar];
        } else {
            [self toggleCartSelection:cart];
            [self.slidingProductViewControllerDelegate toggleShipDates:YES];
        }

        [self.searchText resignFirstResponder];
    }
}

- (void)QtyTableChange:(NSMutableDictionary *)qty forIndex:(int)idx {
    NSString *JSON = [qty JSONString];
    NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) idx];
    [self.coreDataOrder updateItemQuantity:JSON productId:productId context:self.managedObjectContext];
    [self updateCellColorForId:(NSUInteger) idx];
    [self updateTotals];
    self.unsavedChangesPresent = YES;
}

- (void)VoucherChange:(double)price forIndex:(int)idx {
    NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) idx];
    [self.coreDataOrder updateItemVoucher:@(price) productId:productId context:self.managedObjectContext];
    self.unsavedChangesPresent = YES;
}

- (void)ShowPriceChange:(double)price forIndex:(int)idx {
    NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) idx];
    [self.coreDataOrder updateItemShowPrice:@(price) productId:productId context:self.managedObjectContext];
    self.unsavedChangesPresent = YES;
    [self updateTotals];
}

- (void)setSelectedRow:(NSIndexPath *)index {
    selectedItemRowIndexPath = index;
}

#pragma mark - Core Data routines

- (void)updateCellColorForId:(NSUInteger)index {
    NSNumber *productId = [self.resultData objectAtIndex:index];
    ProductCell *cell = (ProductCell *) [self.productsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [helper updateCellBackground:cell order:self.coreDataOrder cart:[self.coreDataOrder findCartForProductId:productId]];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        [self Return];
    }
}

#pragma mark - PullToRefreshViewDeegate

- (void)pullToRefreshViewShouldRefresh:(PullToRefreshView *)view; {
    [self reloadProducts];
}

#pragma mark - VendorViewDelegate

- (void)setVendor:(NSInteger)vendorId {
    currentVendor = vendorId;
}

- (void)setBulletin:(NSInteger)bulletinId {
    currentBulletin = bulletinId;
}

- (void)dismissVendorPopover {
    if ([self.poController isPopoverVisible])
        [self.poController dismissPopoverAnimated:YES];
    [self loadProductsForCurrentVendorAndBulletin];
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


@end