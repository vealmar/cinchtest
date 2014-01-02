//
//  CIProductViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIProductViewController.h"
#import "config.h"
#import "CICalendarViewController.h"
#import "SettingsManager.h"
#import "CoreDataUtil.h"
#import "ShipDate.h"
#import "Order+Extensions.h"
#import "StringManipulation.h"
#import "AFJSONRequestOperation.h"
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
#import "Cart+Extensions.h"
#import "Error.h"
#import "Product+Extensions.h"
#import "DiscountLineItem+Extensions.h"
#import "HudUtil.h"

@interface CIProductViewController () {
    NSInteger currentVendor; //Logged in vendor's id or the vendor selected in the bulletin drop down
    int currentBulletin; //Bulletin selected in the bulletin drop down
    NSArray *vendorsData; //Vendors belonging to the same vendor group as the logged in vendors. These vendors are displayed in the bulletins drop down.
    NSMutableSet *selectedIdx; //Item rows selected for specifying ship dates. These rows appear with a checkmark.
    NSDictionary *bulletins;
    NSIndexPath *selectedItemRowIndexPath;
    CIProductViewControllerHelper *helper;
    PullToRefreshView *pull;
    BOOL keyboardUp;
}
@property(strong, nonatomic) AnOrder *savedOrder;
@property(nonatomic) BOOL unsavedChangesPresent;
//Working copy of selected or new order
@property(nonatomic, strong) Order *coreDataOrder;
@end

@implementation CIProductViewController

#pragma mark - constructor

#define OrderRecoverySelectionYes  1
#define OrderRecoverySelectionNo  0
#define OrderRecoverySelectionNone  -1

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        self.viewInitialized = NO;
        currentVendor = 0;
        currentBulletin = 0;
        self.vendorProductIds = [NSMutableArray array];
        selectedIdx = [NSMutableSet set];
        self.multiStore = NO;
        self.orderSubmitted = NO;
        self.selectedPrintStationId = 0;
        self.unsavedChangesPresent = NO;
        helper = [[CIProductViewControllerHelper alloc] init];
        keyboardUp = NO;
    }
    reachDelegation = [[ReachabilityDelegation alloc] initWithDelegate:self withUrl:kBASEURL];
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


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.searchText addTarget:self action:@selector(searchTextUpdated:) forControlEvents:UIControlEventEditingChanged];
    self.showShipDates = [[ShowConfigurations instance] shipDates];
    self.allowPrinting = [ShowConfigurations instance].printing;
    self.multiStore = [[self.customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [self.customer objectForKey:kStores]) count] > 0;
    pull = [[PullToRefreshView alloc] initWithScrollView:self.productsTableView];
    [pull setDelegate:self];
    [self.productsTableView addSubview:pull];
    currentVendor = self.loggedInVendorId && ![self.loggedInVendorId isKindOfClass:[NSNull class]] ? [self.loggedInVendorId intValue] : 0;
    if ([self.customer objectForKey:kBillName] != nil) self.customerLabel.text = [self.customer objectForKey:kBillName];
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        self.tableHeaderPigglyWiggly.hidden = NO;
        self.tableHeaderFarris.hidden = YES;
    } else {
        self.tableHeaderPigglyWiggly.hidden = YES;
        self.tableHeaderFarris.hidden = NO;
        self.tableHeaderMinColumnLabel.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    }
    if (!self.showShipDates) self.btnSelectShipDates.hidden = YES;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification object:nil];
    self.vendorLabel.text = [[SettingsManager sharedManager] lookupSettingByString:@"username"];
    [self.vendorTable reloadData];
    [self updateErrorsView];
}

- (void)viewDidAppear:(BOOL)animated {
    [HudUtil dismissGlobalHUD];
    if (self.orderSubmitted) {
        [super viewDidAppear:animated];
        [self loadNotesForm];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [CoreDataManager reloadProducts:self.authToken vendorGroupId:self.loggedInVendorGroupId managedObjectContext:self.managedObjectContext];
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@&%@=%@", kDBGETPRODUCTS, kAuthToken, self.authToken, kVendorGroupID, self.loggedInVendorGroupId];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, id json) {
        [[CoreDataUtil sharedManager] deleteAllObjects:@"Product"];
        for (NSDictionary *productJson in json) {
            Product *product = [[Product alloc] initWithProductFromServer:productJson context:self.managedObjectContext];
            [self.managedObjectContext insertObject:product];
            //re-establish connection between carts and products
            NSArray *carts = [[CoreDataUtil sharedManager] fetchArray:@"Cart" withPredicate:[NSPredicate predicateWithFormat:@"(cartId == %@)", product.productId]];
            if (carts) {
                for (Cart *cart in carts) {
                    cart.product = product;
                }
            }
            //re-establish connection between discount line items and products
            NSArray *discountLineItems = [[CoreDataUtil sharedManager] fetchArray:@"DiscountLineItem" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", product.productId]];
            if (discountLineItems) {
                for (DiscountLineItem *discountLineItem in discountLineItems) {
                    discountLineItem.product = product;
                }
            }
        }
        [[CoreDataUtil sharedManager] saveObjects];
        [self loadProductsForCurrentVendorAndBulletin];
        [self.productsTableView reloadData];
        [pull finishedLoading];
    };
    [helper sendRequest:@"GET" url:url parameters:nil successBlock:successBlock failureBlock:nil view:self.view loadingText:@"Loading Products"];
}

- (void)loadProductsForCurrentVendorAndBulletin {
    NSMutableArray *products = [[NSMutableArray alloc] init];
    self.vendorProductIds = [[NSMutableArray alloc] init];
    [[CoreDataManager getProducts:self.managedObjectContext] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Product *product = (Product *) obj;
        NSNumber *vendorId = product.vendor_id;
        if (currentVendor == 0 || (vendorId && [vendorId integerValue] == currentVendor)) {
            NSNumber *productId = product.productId;
            [self.vendorProductIds addObject:productId];
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
            DLog(@"Error saving new order: %@", [error localizedDescription]);
            NSString *msg = [NSString stringWithFormat:@"Error saving new order: %@", [error localizedDescription]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        } else
            self.unsavedChangesPresent = YES;
    }
}

- (void)deserializeOrder {
    [self.productsTableView reloadData];
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
    NSSet *errors = self.coreDataOrder ? self.coreDataOrder.errors : nil;
    if (errors && errors.count > 0) {
        NSMutableString *bulletList = [NSMutableString stringWithCapacity:errors.count * 30];
        for (Error *error in errors) {
            [bulletList appendFormat:@"%@\n", error.message];
        }
        self.errorMessageTextView.text = bulletList;
        self.errorMessageTextView.hidden = NO;
    } else {
        self.errorMessageTextView.text = @"";
        self.errorMessageTextView.hidden = YES;
    }
}

#pragma mark - Other Views

/**
* SG: This is the Bulletins drop down.
*/
- (void)showVendorView {
    VendorViewController *vendorViewController = [[VendorViewController alloc] initWithNibName:@"VendorViewController" bundle:nil];
    vendorViewController.vendors = [NSArray arrayWithArray:vendorsData];

    if (bulletins != nil)
        vendorViewController.bulletins = [NSDictionary dictionaryWithDictionary:bulletins];

    vendorViewController.delegate = self;

    CGRect frame = self.vendorDropdown.frame;
    frame = CGRectOffset(frame, 0, 0);

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vendorViewController];
    nav.navigationBarHidden = NO;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    nav.navigationItem.backBarButtonItem = backButton;

    self.poController = [[UIPopoverController alloc] initWithContentViewController:nav];
    vendorViewController.parentPopover = self.poController;
    [self.poController presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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
    [helper updateCellBackground:cell cart:[self.coreDataOrder findCartForProductId:productId]];
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) [indexPath row]];
    Product *product = [Product findProduct:productId];
    UITableViewCell *cell = [helper dequeueReusableProductCell:myTableView];
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        BOOL rowIsSelected = [selectedIdx containsObject:[NSNumber numberWithInteger:[indexPath row]]] && ![product.invtid isEqualToString:@"0"];
        [(PWProductCell *) cell initializeWith:self.customer multiStore:self.multiStore product:product cart:[self.coreDataOrder findCartForProductId:product.productId] checkmarked:rowIsSelected tag:[indexPath row] productCellDelegate:self];
    } else {
        [(FarrisProductCell *) cell initializeWithProduct:product cart:[self.coreDataOrder findCartForProductId:product.productId] tag:[indexPath row] ProductCellDelegate:self];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.showShipDates) {
        NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) [indexPath row]];
        Product *product = [Product findProduct:productId];
        if ([selectedIdx containsObject:[NSNumber numberWithInteger:[indexPath row]]]) {
            [selectedIdx removeObject:[NSNumber numberWithInteger:[indexPath row]]];
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        } else {
            [selectedIdx addObject:[NSNumber numberWithInteger:[indexPath row]]];
            if (![product.invtid isEqualToString:@"0"] && self.showShipDates) {
                [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSNumber *productId = self.resultData[(NSUInteger) indexPath.row];
    Cart *cart = [self.coreDataOrder findCartForProductId:productId];
    return (cart.errors.count > 0) ? 44 + cart.errors.count * 42 : 44;
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
    [selectedIdx removeAllObjects];
    if (vendorsData && [vendorsData count] > 0) {
        [self showVendorView];
    }
}

- (void)loadPrintersAndPromptForSelection {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kDBGETPRINTERS]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
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
    }                                                                                   failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSString *msg = [NSString stringWithFormat:@"Unable to load available printers. Order will not be printed. %@", [error localizedDescription]];
        [[[UIAlertView alloc] initWithTitle:@"No Printers" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }];
    [operation start];
}

- (void)loadNotesForm {
    if ([helper isOrderReadyForSubmission:self.coreDataOrder]) {
        CIFinalCustomerInfoViewController *ci = [[CIFinalCustomerInfoViewController alloc] initWithNibName:@"CIFinalCustomerInfoViewController" bundle:nil];
        ci.order = self.coreDataOrder;
        ci.modalPresentationStyle = UIModalPresentationFormSheet;
        ci.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        ci.delegate = self;
        [self presentViewController:ci animated:YES completion:nil];
    }
}

/**
* SG: This method is called when user taps the cart button.
*/
- (IBAction)reviewCart:(id)sender {
    CICartViewController *cart = [[CICartViewController alloc] initWithOrder:self.coreDataOrder customer:self.customer authToken:self.authToken selectedVendorId:[NSNumber numberWithInt:currentVendor] loggedInVendorId:self.loggedInVendorId loggedInVendorGroupId:self.loggedInVendorGroupId andManagedObjectContext:self.managedObjectContext];
    cart.delegate = self;
    cart.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:cart animated:YES completion:nil];
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
    if (selectedIdx.count <= 0) {
        [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"Please select the item(s) you want to set dates for."
                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }

    NSMutableArray *ranges = [NSMutableArray arrayWithCapacity:selectedIdx.count];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];

    for (NSNumber *idx in selectedIdx) {
        NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) idx.intValue];
        Product *product = [Product findProduct:productId];
        if ([product.invtid isEqualToString:@"0"]) {
            continue;
        }
        NSDate *startDate = [[NSDate alloc] init];
        NSDate *endDate = [[NSDate alloc] init];
        if (product.shipdate1) {
            startDate = product.shipdate1;
        }
        if (product.shipdate2) {
            endDate = product.shipdate2;
        }
        NSMutableArray *dateList = [NSMutableArray array];
        NSCalendar *currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setDay:1];
        [dateList addObject:startDate];
        NSDate *currentDate = startDate;
        // add one the first time through, so that we can use NSOrderedAscending (prevents millisecond infinite loop)
        currentDate = [currentCalendar dateByAddingComponents:comps toDate:currentDate options:0];
        while ([endDate compare:currentDate] != NSOrderedAscending) {
            [dateList addObject:currentDate];
            currentDate = [currentCalendar dateByAddingComponents:comps toDate:currentDate options:0];
        }
        [ranges addObject:dateList];
    }
    CICalendarViewController *calView = [[CICalendarViewController alloc] initWithNibName:@"CICalendarViewController" bundle:nil];
    calView.modalPresentationStyle = UIModalPresentationFormSheet;
    CICalendarViewController __weak *weakCalView = calView;
    calView.cancelTouched = ^{
        CICalendarViewController *strongCalView = weakCalView;
        [strongCalView dismissViewControllerAnimated:NO completion:nil];
    };
    calView.doneTouched = ^(NSArray *dates) {
        CICalendarViewController *strongCalView = weakCalView;
        [selectedIdx enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            NSNumber *idx = (NSNumber *) obj;
            NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) [idx integerValue]];
            if ([self.productCart objectForKey:productId] != nil) {
                [self updateShipDatesInCartWithId:productId forDates:dates];
                [self updateTotals];
                self.unsavedChangesPresent = YES;
            }
            [self updateCellColorForId:(NSUInteger) [idx integerValue]];
        }];
        [selectedIdx removeAllObjects];
        [self.productsTableView reloadData];
        [strongCalView dismissViewControllerAnimated:NO completion:nil];
    };
    __block NSMutableArray *selectedArr = [NSMutableArray array];
    for (Cart *cart in self.coreDataOrder.carts) {
        if (cart.shipdates && cart.shipdates.count > 0) {
            [selectedArr addObjectsFromArray:[cart shipDatesAsStringArray]];
        }
    }
    NSArray *selectedDates = [[[NSOrderedSet orderedSetWithArray:selectedArr] array] copy];
    if (ranges.count > 1) {
        NSMutableSet *final = [NSMutableSet setWithArray:[ranges objectAtIndex:0]];
        for (int i = 1; i < ranges.count; i++) {
            NSSet *tempset = [NSSet setWithArray:[ranges objectAtIndex:(NSUInteger) i]];
            [final intersectSet:tempset];
        }
        if (final.count <= 0) {
            [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"We couldn't find any dates that could be used for all of the items you have selected! Please de-select some and then try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            calView.startDate = [[final allObjects] objectAtIndex:0];
            calView.afterLoad = ^{
                calView.calendarView.avalibleDates = [[final allObjects] mutableCopy];
                calView.calendarView.selectedDates = [selectedDates mutableCopy];
            };
            [self presentViewController:calView animated:NO completion:nil];
        }
    } else {
        if (ranges && ranges.count == 1) {
            calView.startDate = [[ranges objectAtIndex:0] objectAtIndex:0];
            calView.afterLoad = ^{
                calView.calendarView.avalibleDates = [[ranges objectAtIndex:0] mutableCopy];
                calView.calendarView.selectedDates = [selectedDates mutableCopy];
            };
            [self presentViewController:calView animated:NO completion:nil];
        }
    }
}

- (void)searchTextUpdated:(UITextField *)textField {
    [self searchProducts:textField];
}

- (IBAction)searchProducts:(id)sender {
    if (self.vendorProductIds == nil|| [self.vendorProductIds isKindOfClass:[NSNull class]] || [self.vendorProductIds count] == 0) return;
    if ([self.searchText.text isEqualToString:@""]) {
        self.resultData = [self.vendorProductIds mutableCopy];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
            NSNumber *productId = (NSNumber *) obj;
            Product *product = [Product findProduct:productId];
            NSString *invtid = [NilUtil objectOrDefaultString:product.invtid defaultObject:@""];
            NSString *descrip = [NilUtil objectOrDefaultString:product.descr defaultObject:@""];
            NSString *desc2 = [NilUtil objectOrDefaultString:product.descr2 defaultObject:@""];
            NSString *test = [self.searchText.text uppercaseString];
            return [[invtid uppercaseString] contains:test] || [[descrip uppercaseString] contains:test] || (desc2 != nil && ![desc2 isEqual:[NSNull null]] && [[desc2 uppercaseString] contains:test]);
        }];
        self.resultData = [[self.vendorProductIds filteredArrayUsingPredicate:pred] mutableCopy];
        [selectedIdx removeAllObjects];
    }
    [self.productsTableView reloadData];
}

//User is in middle of editing a quantity (so the keyboard is visible), then taps somewhere else on the screen - the keyboard should disappear.
- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([kShowCorp isEqualToString:kPigglyWiggly]) {
            for (PWProductCell *cell in self.productsTableView.visibleCells) {
                if ([cell.quantity isFirstResponder]) {
                    [cell.quantity resignFirstResponder];//so the keyboard will hide
                    break;
                }
            }
        } else {
            for (FarrisProductCell *cell in self.productsTableView.visibleCells) {
                if ([cell.quantity isFirstResponder]) {
                    [cell.quantity resignFirstResponder];//so the keyboard will hide
                    break;
                }
            }
        }
    }
}

- (void)keyboardWillShow {
    // Reducing the frame height by 300 causes it to end above the keyboard, so the keyboard cannot overlap any content. 300 is the height occupied by the keyboard.
    // In addition scroll the selected row into view.
    CGRect frame = self.productsTableView.frame;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    frame.size.height -= 300;
    self.productsTableView.frame = frame;
    [self.productsTableView scrollToRowAtIndexPath:selectedItemRowIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    keyboardUp = YES;
    [UIView commitAnimations];
}

- (void)keyboardDidHide {
    CGRect frame = self.productsTableView.frame;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    frame.size.height += 300;
    self.productsTableView.frame = frame;
    keyboardUp = NO;
    [UIView commitAnimations];
}

- (void)sendOrderToServer:(BOOL)printThisOrder {
    if (![helper isOrderReadyForSubmission:self.coreDataOrder]) {return;}
    self.coreDataOrder.status = @"complete";
    self.coreDataOrder.print = [NSNumber numberWithBool:printThisOrder];
    self.coreDataOrder.printer = printThisOrder ? [NSNumber numberWithInt:self.selectedPrintStationId] : nil;
    NSDictionary *parameters = [self.coreDataOrder asJSONReqParameter];
    NSString *method = [self.coreDataOrder.orderId intValue] > 0 ? @"PUT" : @"POST";
    NSString *url = [self.coreDataOrder.orderId intValue] == 0 ? [NSString stringWithFormat:@"%@?%@=%@", kDBORDER, kAuthToken, self.authToken] : [NSString stringWithFormat:@"%@?%@=%@", [NSString stringWithFormat:kDBORDEREDITS([self.coreDataOrder.orderId intValue])], kAuthToken, self.authToken];
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
    [self.productsTableView reloadData];
    [self updateTotals];
    [self updateErrorsView];
    return anOrder;
}

- (void)updateTotals {
    NSArray *totals = [helper getTotals:self.coreDataOrder];
    self.totalCost.text = [NumberUtil formatDollarAmount:totals[0]];
}

#pragma mark - CIFinalCustomerDelegate

- (void)setAuthorizedByInfo:(NSDictionary *)info {
    self.coreDataOrder.ship_notes = [info objectForKey:kShipNotes];
    self.coreDataOrder.notes = [info objectForKey:kNotes];
    self.coreDataOrder.authorized = [info objectForKey:kAuthorizedBy];
    if (!([kShowCorp isEqualToString:kPigglyWiggly])) {
        self.coreDataOrder.ship_flag = [[info objectForKey:kShipFlag] isEqualToString:@"true"] ? @(1) : @(0);
    }
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

- (void)QtyChange:(int)qty forIndex:(int)idx {
    NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) idx];
    [self.coreDataOrder updateItemQuantity:[NSString stringWithFormat:@"%i", qty] productId:productId context:self.managedObjectContext];
    self.unsavedChangesPresent = YES;
    [self updateCellColorForId:(NSUInteger) idx];
    [self updateTotals];
}

- (void)QtyTouchForIndex:(int)idx {
    if ([self.poController isPopoverVisible]) {
        [self.poController dismissPopoverAnimated:YES];
    } else {
        if (!self.storeQtysPO) {
            self.storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }
        NSNumber *productId = [self.resultData objectAtIndex:(NSUInteger) idx];
        Cart *cart = [self.coreDataOrder findCartForProductId:productId];
        self.storeQtysPO.stores = [[cart.editableQty objectFromJSONString] mutableCopy];
        self.storeQtysPO.tag = idx;
        self.storeQtysPO.delegate = self;
        CGRect frame = [self.productsTableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        frame = CGRectOffset(frame, 750, 0);
        self.poController = [[UIPopoverController alloc] initWithContentViewController:self.storeQtysPO];
        [self.poController presentPopoverFromRect:frame inView:self.productsTableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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

- (void)setSelectedRow:(NSIndexPath *)index {
    selectedItemRowIndexPath = index;
}

#pragma mark - Core Data routines

- (void)updateShipDatesInCartWithId:(NSNumber *)cartId forDates:(NSArray *)dates {
    if (dates && [dates count] > 0) {
        Cart *cart = [self.coreDataOrder findCartForProductId:cartId];
        [self updateShipDates:dates inCart:cart];
    }
}

- (void)updateShipDates:(NSArray *)dates inCart:(Cart *)cart {
    if (dates && cart && [dates count] > 0) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];

        NSMutableArray *cartDates = [[NSMutableArray alloc] initWithCapacity:[cart.shipdates count]];
        for (ShipDate *sd in cart.shipdates) {
            [cartDates addObject:sd.shipdate];
        }

        NSMutableArray *newDates = [[NSMutableArray alloc] initWithCapacity:[dates count]];
        for (NSDate *aDate in dates) {
            NSTimeInterval timeInt = [aDate timeIntervalSinceReferenceDate];
            [newDates addObject:[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:timeInt]];
        }

        NSArray *sortedCartDates = [cartDates sortedArrayUsingSelector:@selector(compare:)];
        NSArray *sortedDates = [newDates sortedArrayUsingSelector:@selector(compare:)];

        if (![sortedDates isEqualToArray:sortedCartDates]) {
            NSMutableArray *newShipDates = [[NSMutableArray alloc] init];
            for (NSDate *aDate in sortedDates) {
                ShipDate *sd = [NSEntityDescription insertNewObjectForEntityForName:@"ShipDate" inManagedObjectContext:cart.managedObjectContext];
                [sd setShipdate:aDate];
                [newShipDates addObject:sd];
            }

            for (ShipDate *shipDate in cart.shipdates) {
                [self.managedObjectContext deleteObject:shipDate];
            }

            NSOrderedSet *orderedDates = [NSOrderedSet orderedSetWithArray:newShipDates];
            [cart setShipdates:orderedDates];

            NSError *error = nil;
            BOOL success = [self.managedObjectContext save:&error];
            if (!success) {
                DLog(@"Error updating shipdates in cart: %@", [error localizedDescription]);
            }
        }
    }
}

- (void)updateCellColorForId:(NSUInteger)index {
    NSNumber *productId = [self.resultData objectAtIndex:index];
    ProductCell *cell = (ProductCell *) [self.productsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [helper updateCellBackground:cell cart:[self.coreDataOrder findCartForProductId:productId]];
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

#pragma mark - ReachabilityDelegate

- (void)networkLost {
}

- (void)networkRestored {
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
    BOOL orderWasSaved = self.savedOrder != nil;
    enum OrderUpdateStatus status = [self.selectedOrder.status isEqualToString:@"partial"] && self.savedOrder == nil? PartialOrderCancelled
            : [self.selectedOrder.status isEqualToString:@"partial"] && self.savedOrder != nil? PartialOrderSaved
                    : [self.selectedOrder.orderId intValue] != 0 && self.savedOrder == nil? PersistentOrderUnchanged
                            : [self.selectedOrder.orderId intValue] != 0 && self.savedOrder != nil? PersistentOrderUpdated
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
        }
    }];
}


@end