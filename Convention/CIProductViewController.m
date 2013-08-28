//
//  CIProductViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "CIProductViewController.h"
#import "config.h"
#import "MBProgressHUD.h"
#import "CICalendarViewController.h"
#import "SettingsManager.h"
#import "CoreDataUtil.h"
#import "Cart.h"
#import "ShipDate.h"
#import "Order+Extensions.h"
#import "StringManipulation.h"
#import "AFJSONRequestOperation.h"
#import "AFHTTPClient.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "FarrisProductCell.h"
#import "ShowConfigurations.h"
#import "AnOrder.h"
#import "ALineItem.h"
#import "CoreDataManager.h"

@interface CIProductViewController () {
    NSInteger currentVendor; //Logged in vendor's id or the vendor selected in the bulletin drop down
    int currentBulletin; //Bulletin selected in the bulletin drop down
    NSArray *vendorsData; //Vendors belonging to the same vendor group as the logged in vendors. These vendors are displayed in the bulletins drop down.
    NSMutableDictionary *editableData; //Key is product_id. Contains all changes made to the rows. Like changing quantity, ship dates, voucher.
    NSMutableSet *selectedIdx; //Item rows selected for specifying ship dates. These rows appear with a checkmark.
    NSDictionary *bulletins;
    NSIndexPath *selectedItemRowIndexPath;
}

@end

@implementation CIProductViewController

#pragma mark - constructor

#define kDeserializeOrder @"DeserializeOrder"
#define kLaunchCart @"LaunchCart"
#define OrderRecoveryAlertTag  111
#define OrderRecoverySelectionYes  1
#define OrderRecoverySelectionNo  0
#define OrderRecoverySelectionNone  -1

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        self.showPrice = YES;
        self.viewInitialized = NO;
        self.tOffset = 0;
        currentVendor = 0;
        currentBulletin = 0;
        self.productCart = [NSMutableDictionary dictionary];
        self.productMap = [NSMutableDictionary dictionary];
        self.discountItems = [NSMutableDictionary dictionary];
        editableData = [NSMutableDictionary dictionary];
        selectedIdx = [NSMutableSet set];
        self.multiStore = NO;
        self.orderSubmitted = NO;
        _printStationId = 0;
        self.unsavedChangesPresent = NO;
    }
    reachDelegation = [[ReachabilityDelegation alloc] initWithDelegate:self withUrl:kBASEURL];
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.searchText addTarget:self action:@selector(searchTextUpdated:) forControlEvents:UIControlEventEditingChanged];
    self.showShipDates = [[ShowConfigurations instance] shipDates];
    self.allowPrinting = [ShowConfigurations instance].printing;
}

- (void)viewWillAppear:(BOOL)animated {
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        self.tableHeaderPigglyWiggly.hidden = NO;
        self.tableHeaderFarris.hidden = YES;
    } else if ([kShowCorp isEqualToString:kFarris]) {
        self.tableHeaderPigglyWiggly.hidden = YES;
        self.tableHeaderFarris.hidden = NO;
    } else {
        self.tableHeaderPigglyWiggly.hidden = YES;
        self.tableHeaderFarris.hidden = YES;
    }
    if (!self.showShipDates) self.btnSelectShipDates.hidden = YES;

    if (self.orderSubmitted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishOrder:nil]; //SG: Displays the view that asks the user for Authorized By, Notes etc information in a modal window.
        });
    } else if (!self.viewInitialized) {
        if ([self.customer objectForKey:kBillName] != nil) self.customerLabel.text = [self.customer objectForKey:kBillName];
        self.multiStore = [[self.customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [self.customer objectForKey:kStores]) count] > 0;
        currentVendor = self.loggedInVendorId && ![self.loggedInVendorId isKindOfClass:[NSNull class]] ? [self.loggedInVendorId intValue] : 0;
        [self loadProducts];
    } else
        [self.products reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification object:self.view.window];
    self.vendorLabel.text = [[SettingsManager sharedManager] lookupSettingByString:@"username"];
    [self.vendorTable reloadData];
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
            if (orderRecoverySelection == OrderRecoverySelectionNone) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Recover Order?" message:@"It appears like the app crashed last time you were working on this order. Would you like to recover those changes?"
                                                               delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
                [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
                    if ([[alert buttonTitleAtIndex:buttonIndex] isEqualToString:@"YES"]) {
                        [self loadOrder:OrderRecoverySelectionYes];
                    } else
                        [self loadOrder:OrderRecoverySelectionNo];
                    [self deserializeOrder];
                }];
            }
        } else if (orderRecoverySelection == OrderRecoverySelectionNo) {
            [[CoreDataUtil sharedManager] deleteObject:coreDataOrder]; //delete existing core data entry. Start fresh with the order from server
            [[CoreDataUtil sharedManager] saveObjects];
            self.coreDataOrder = [self createCoreDataWorkingCopyOfSelectedOrder];
        } else if (orderRecoverySelection == OrderRecoverySelectionYes) {
            self.coreDataOrder = coreDataOrder; //Use the order from core data
            self.unsavedChangesPresent = YES;
        }
    } else if (orderExistsOnServer) {//pending order.
        self.coreDataOrder = [self createCoreDataWorkingCopyOfSelectedOrder];
    } else if (orderExistsInCoreData) {//partial order i.e. a brand new order in the middle of which the app crashed. Hence there is a copy in core data but none on server.
        self.coreDataOrder = coreDataOrder;
        self.unsavedChangesPresent = YES;
    }
}

- (Order *)createCoreDataWorkingCopyOfSelectedOrder {
    Order *coreDataOrder = [[Order alloc] initWithOrder:self.selectedOrder forCustomer:self.customer vendorId:[[NSNumber alloc] initWithInt:[self.loggedInVendorId intValue]] vendorGroup:self.loggedInVendorId andVendorGroupId:self.loggedInVendorGroupId context:self.managedObjectContext];
    NSMutableOrderedSet *carts = [[NSMutableOrderedSet alloc] init];
    for (ALineItem *lineItem in self.selectedOrder.lineItems) {
        NSNumber *product_id = lineItem.productId;
        NSDictionary *product = [self.productMap objectForKey:product_id];
        Cart *cart = [[Cart alloc] initWithLineItem:lineItem forProduct:product andCustomer:self.customer context:self.managedObjectContext];
        [carts addObject:cart];
    }
    coreDataOrder.carts = carts;
    [self.managedObjectContext insertObject:coreDataOrder];
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSString *msg = [NSString stringWithFormat:@"Error loading order: %@", [error localizedDescription]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    return coreDataOrder;
}

- (NSMutableDictionary *)createIfDoesntExist:(NSMutableDictionary *)dict orig:(NSDictionary *)odict {
    if (dict != nil && [dict objectForKey:kEditablePrice] != nil
            && [dict objectForKey:kEditableVoucher] != nil && [dict objectForKey:kEditableQty] != nil) {
        return nil;
    }

    dict = [NSMutableDictionary dictionary];

    [dict setValue:[NSNumber numberWithDouble:[[odict objectForKey:kProductShowPrice] doubleValue]] forKey:kEditablePrice];
    [dict setValue:[NSNumber numberWithDouble:[[odict objectForKey:kProductVoucher] doubleValue]] forKey:kEditableVoucher];
    [dict setValue:[NSNumber numberWithInt:0] forKey:kEditableQty];

    return dict;
}

- (void)loadProducts {
    NSString *url;
    if (currentVendor == 0) {
        if (self.loggedInVendorId && ![self.loggedInVendorId isKindOfClass:[NSNull class]]) {
            url = [NSString stringWithFormat:@"%@?%@=%@&%@=%@", kDBGETPRODUCTS, kAuthToken, self.authToken, kVendorGroupID, self.loggedInVendorGroupId];
        } else {
            url = [NSString stringWithFormat:@"%@?%@=%@", kDBGETPRODUCTS, kAuthToken, self.authToken];
        }
    } else {
        url = [NSString stringWithFormat:@"%@?%@=%@&%@=%d", kDBGETPRODUCTS, kAuthToken, self.authToken, @"vendor_id", currentVendor];
    }
    [self loadProductsForUrl:url];
}

- (void)loadProductsForUrl:(NSString *)url {
    MBProgressHUD *__weak loadProductsHUD = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    loadProductsHUD.labelText = @"Loading Products...";
    [loadProductsHUD show:NO];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    AFJSONRequestOperation *jsonOp;
    jsonOp = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
            success:^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
                self.resultData = [[NSMutableArray alloc] init];
                [JSON enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [self.productMap setObject:obj forKey:[obj objectForKey:kProductId]];
                    int bulletinId = 0;
                    if ([obj objectForKey:@"bulletin_id"] != nil && ![[obj objectForKey:@"bulletin_id"] isKindOfClass:[NSNull class]])
                        bulletinId = [[obj objectForKey:@"bulletin_id"] intValue];
                    if (currentBulletin == 0 || currentBulletin == bulletinId)
                        [self.resultData addObject:[obj mutableCopy]];
                }];
                [self.products reloadData];
                [loadProductsHUD hide:NO];
                if (self.coreDataOrder == nil) {
                    if (self.newOrder)
                        [self createNewOrder];
                    else
                        [self loadOrder:OrderRecoverySelectionNone];
                }
                [self deserializeOrder];
                self.viewInitialized = YES;
            } failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id JSON) {
                [[[UIAlertView alloc] initWithTitle:@"Error!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                [loadProductsHUD hide:NO];
            }];
    [jsonOp start];
}

- (void)loadBulletins {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kDBGETBULLETINS]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
            success:^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
                NSMutableDictionary *bulls = [[NSMutableDictionary alloc] init];
                [JSON enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSDictionary *dict = (NSDictionary *) obj;
                    NSNumber *vendid = [NSNumber numberWithInt:[[dict objectForKey:@"vendor_id"] intValue]];
                    if ([bulls objectForKey:vendid] == nil) {
                        NSDictionary *any = [NSDictionary dictionaryWithObjectsAndKeys:@"Any", @"name", [NSNumber numberWithInt:0], @"id", nil];
                        NSMutableArray *arr = [[NSMutableArray alloc] init];
                        [arr addObject:any];
                        [bulls setObject:arr forKey:vendid];
                    }
                    [[bulls objectForKey:vendid] addObject:dict];
                }];

                bulletins = [NSDictionary dictionaryWithDictionary:bulls];
                [self showVendorView];

            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                bulletins = nil;
                [self showVendorView];
            }];

    [operation start];
}

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}


#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    if (self.resultData && myTableView == self.products) {
        return [self.resultData count];
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.products) {
        NSMutableDictionary *dict = [self.resultData objectAtIndex:(NSUInteger) [indexPath row]];
        NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
        [(ProductCell *) cell updateCellBackground:dict item:editableDict multiStore:self.multiStore showShipDates:self.showShipDates];
    }
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (myTableView == self.products && self.resultData == nil)return nil;

    NSMutableDictionary *dict = [self.resultData objectAtIndex:(NSUInteger) [indexPath row]];
    NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    UITableViewCell *cell = [self dequeueReusableProductCell];
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        BOOL rowIsSelected = [selectedIdx containsObject:[NSNumber numberWithInteger:[indexPath row]]] && ![[dict objectForKey:@"invtid"] isEqualToString:@"0"];
        [(PWProductCell *) cell initializeWith:self.customer multiStore:self.multiStore showPrice:self.showPrice product:dict item:editableDict checkmarked:rowIsSelected tag:[indexPath row] ProductCellDelegate:self];
    } else if ([kShowCorp isEqualToString:kFarris]) {
        [(FarrisProductCell *) cell initializeWith:dict item:editableDict tag:[indexPath row] ProductCellDelegate:self];
    }
    return cell;
}

- (UITableViewCell *)dequeueReusableProductCell {
    NSString *CellIdentifier = [kShowCorp isEqualToString:kPigglyWiggly] ? @"PWProductCell" : @"FarrisProductCell";
    UITableViewCell *cell = [self.products dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:nil options:nil];
        cell = [topLevelObjects objectAtIndex:0];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.products) {
        NSDictionary *dict = [self.resultData objectAtIndex:(NSUInteger) [indexPath row]];
        if ([selectedIdx containsObject:[NSNumber numberWithInteger:[indexPath row]]]) {
            [selectedIdx removeObject:[NSNumber numberWithInteger:[indexPath row]]];
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        } else {
            [selectedIdx addObject:[NSNumber numberWithInteger:[indexPath row]]];
            if (![[dict objectForKey:@"invtid"] isEqualToString:@"0"] && self.showShipDates) {
                [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    }
}

#pragma mark - Other

- (void)Cancel {
    if (_coreDataOrder.orderId == 0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                initWithTitle:@"Cancel Order?"
                      message:@"This will cancel the current order."
                     delegate:self
            cancelButtonTitle:@"Cancel"
            otherButtonTitles:@"OK", nil];
        [alertView show];
    } else if (self.unsavedChangesPresent) {
        UIAlertView *alertView = [[UIAlertView alloc]
                initWithTitle:@"Exit Without Saving?"
                      message:@"There are some unsaved changes. Are you sure you want to exit without saving?"
                     delegate:self
            cancelButtonTitle:@"No"
            otherButtonTitles:@"Yes", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alertView withCallBack:^(NSInteger buttonIndex) {
            if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"]) {
                [self Return];
            }
        }];
    } else {
        [self Return];
    }
}

- (void)cancelNewOrder {
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"%@ - %@", self, self.delegate);
        [self.delegate Return:nil];
    }];
}

- (IBAction)Cancel:(id)sender {
    [self Cancel];
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
        [self.coreDataOrder setMultiStore:self.multiStore];
        [self.coreDataOrder setStatus:@"partial"];
        [self.coreDataOrder setVendorGroup:self.loggedInVendorId];
        [self.coreDataOrder setVendorGroupId:self.loggedInVendorGroupId];
        [self.coreDataOrder setVendor_id:currentVendor];
        [self.coreDataOrder setCustid:custId];
        [self.coreDataOrder setCustomer_id:customerId];
        [self.coreDataOrder setBillname:[self.customer objectForKey:kBillName]];
        [self.coreDataOrder setMultiStore:self.multiStore];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDeserializeOrder object:nil];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];

    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    nf.formatterBehavior = NSNumberFormatterBehavior10_4;
    nf.maximumFractionDigits = 2;
    nf.minimumFractionDigits = 2;
    nf.minimumIntegerDigits = 1;

    self.totalCost.text = [nf stringFromNumber:[NSNumber numberWithDouble:_coreDataOrder.totalCost]];

    for (Cart *cart in _coreDataOrder.carts) {
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setObject:cart.category forKey:@"category"];
        [item setObject:[NSString stringWithFormat:@"%d", cart.adv] forKey:kProductAdv];
        [item setObject:cart.caseqty forKey:kProductCaseQty];
        [item setObject:cart.company forKey:kProductCompany];
        [item setObject:cart.descr forKey:kProductDescr];

        if ([kShowCorp isEqualToString:kFarris])
            [item setObject:cart.descr2 forKey:kProductDescr2];

        [item setObject:[NSString stringWithFormat:@"%d", cart.dirship] forKey:kProductDirShip];
        [item setObject:[NSNumber numberWithFloat:cart.discount] forKey:kProductDiscount];
        [item setObject:[NSNumber numberWithFloat:cart.editablePrice] forKey:kEditablePrice];

        if (!_coreDataOrder.multiStore) {
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            [f setFormatterBehavior:NSNumberFormatterBehavior10_4];
            [item setObject:[f numberFromString:cart.editableQty] forKey:kEditableQty];
        } else {
            [item setObject:cart.editableQty forKey:kEditableQty];
        }
        [item setObject:[NSNumber numberWithFloat:cart.editableVoucher] forKey:kEditableVoucher];
        [item setObject:[NSNumber numberWithInt:cart.cartId] forKey:@"id"];
        [item setObject:[NSNumber numberWithInt:cart.idx] forKey:kProductIdx];
        [item setObject:[NSNumber numberWithInt:cart.import_id] forKey:kProductImportID];
        [item setObject:[NSString stringWithFormat:@"%@", cart.invtid] forKey:kProductInvtid];
        [item setObject:cart.initial_show == nil ? @"" : cart.initial_show forKey:kProductInitialShow];
        [item setObject:cart.linenbr == nil ? @"" : cart.linenbr forKey:kProductLineNbr];
        [item setObject:[NSString stringWithFormat:@"%d", cart.new] forKey:kProductNew];
        [item setObject:cart.partnbr == nil ? @"" : cart.partnbr forKey:kProductPartNbr];
        [item setObject:cart.regprc == nil ? @"" : cart.regprc forKey:kProductRegPrc];
        [item setObject:cart.shipdate1 == nil ? @"" : cart.shipdate1 forKey:kProductShipDate1];
        [item setObject:cart.shipdate2 == nil ? @"" : cart.shipdate2 forKey:kProductShipDate2];

        NSMutableArray *shipdates = [[NSMutableArray alloc] initWithCapacity:[cart.shipdates count]];
        if ([cart.shipdates count] > 0) {
            for (ShipDate *sd in cart.shipdates) {
                //[shipdates addObject:[df stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:sd.shipdate]]];
                [shipdates addObject:sd.shipdate];
            }

            [item setObject:shipdates forKey:kOrderItemShipDates];
        }
        [item setObject:cart.showprc forKey:kProductShowPrice];
        [item setObject:cart.unique_product_id forKey:kProductUniqueId];
        [item setObject:cart.uom == nil ? @"" : cart.uom forKey:kProductUom];
        [item setObject:cart.updated_at == nil ? @"" : cart.updated_at forKey:kProductUpdatedAt];
        [item setObject:cart.vendid forKey:kProductVendID];
        [item setObject:[NSNumber numberWithInt:cart.vendor_id] forKey:@"vendor_id"];
        [item setObject:cart.voucher forKey:kProductVoucher];

        if (cart.orderLineItem_id > 0)
            [item setObject:[NSNumber numberWithInt:cart.orderLineItem_id] forKey:kOrderLineItemId];

        [self.productCart setObject:item forKey:[NSNumber numberWithInt:cart.cartId]];

        NSString *invt_id = cart.invtid;
        NSUInteger index = [self.resultData indexOfObjectPassingTest:^BOOL(id dictionary, NSUInteger idx, BOOL *stop) {
            NSString *prodId = [dictionary objectForKey:kProductInvtid];
            *stop = [prodId isEqualToString:invt_id];
            return *stop;
        }];
        if (index != NSNotFound) {
            NSMutableDictionary *dict = [self.resultData objectAtIndex:index];
            NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
            NSMutableDictionary *edict = [self createIfDoesntExist:editableDict orig:dict];

            if (edict == nil) {
                edict = editableDict;
            }

            [edict setValue:[item objectForKey:kEditablePrice] forKey:kEditablePrice];
            [edict setValue:[item objectForKey:kEditableQty] forKey:kEditableQty];
            [edict setValue:[item objectForKey:kEditableVoucher] forKey:kEditableVoucher];
            if ([shipdates count] > 0) {
                [edict setObject:shipdates forKey:kOrderItemShipDates];
            }

            [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
        }
    }

    [self.products reloadData];
    self.viewInitialized = YES;
}

- (void)setAuthorizedByInfo:(NSDictionary *)info {
    NSMutableDictionary *customerCopy = [self.customer mutableCopy];
    [customerCopy setObject:[info objectForKey:kShipNotes] forKey:kShipNotes];
    [customerCopy setObject:[info objectForKey:kNotes] forKey:kNotes];
    [customerCopy setObject:[info objectForKey:kAuthorizedBy] forKey:kAuthorizedBy];
    if ([kShowCorp isEqualToString:kFarris]) {
        [customerCopy setObject:[info objectForKey:kShipFlag] forKey:kShipFlag];
    }
    self.customer = customerCopy;
}

- (void)setSelectedPrinter:(NSString *)printer {
    [self.poController dismissPopoverAnimated:YES];
    [[SettingsManager sharedManager] saveSetting:@"printer" value:printer];
    _printStationId = [[[_availablePrinters objectForKey:printer] objectForKey:@"id"] intValue];
    [self sendOrderToServer:YES asPending:NO beforeCart:NO];
}

- (void)selectPrintStation {
    PrinterSelectionViewController *psvc = [[PrinterSelectionViewController alloc] initWithNibName:@"PrinterSelectionViewController" bundle:nil];
    psvc.title = @"Available Printers";
    NSArray *keys = [[[_availablePrinters allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] copy];
    psvc.availablePrinters = [NSArray arrayWithArray:keys];
    psvc.delegate = self;

    CGRect frame = self.cartButton.frame;
    frame = CGRectOffset(frame, 0, 0);

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:psvc];
    self.poController = [[UIPopoverController alloc] initWithContentViewController:nav];
    [self.poController presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)calcOrder:(id)sender {
    [self sendOrderToServer:NO asPending:YES beforeCart:NO];
}

- (IBAction)submit:(id)sender {

    if (self.allowPrinting) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Do you want to print the order after submission?"
                                                       delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", @"No", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {

            if (buttonIndex != 0) {
                if (buttonIndex == 1) { // YES
                    if (_printStationId == 0) {
                        if (_availablePrinters == nil) {
                            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kDBGETPRINTERS]];
                            AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

                                if (JSON != nil && [JSON isKindOfClass:[NSArray class]] && [JSON count] > 0) {
                                    NSMutableDictionary *printStations = [[NSMutableDictionary alloc] initWithCapacity:[JSON count]];
                                    for (NSDictionary *printer in JSON) {
                                        [printStations setObject:printer forKey:[printer objectForKey:@"name"]];
                                    }

                                    _availablePrinters = [NSDictionary dictionaryWithDictionary:printStations];
                                    [self selectPrintStation];
                                }

                            }                                                                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

                                NSString *msg = [NSString stringWithFormat:@"Unable to load available printers. Order will not be printed. %@", [error localizedDescription]];
                                [[[UIAlertView alloc] initWithTitle:@"No Printers" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                            }];

                            [operation start];
                        } else {
                            [self selectPrintStation];
                        }

                    } else {
                        [self sendOrderToServer:YES asPending:NO beforeCart:NO];
                    }
                } else { // NO
                    [self sendOrderToServer:NO asPending:NO beforeCart:NO];
                }
            }
        }];
    } else {
        [self sendOrderToServer:NO asPending:NO beforeCart:NO];
    }
}

- (void)sendOrderToServer:(BOOL)printThisOrder asPending:(BOOL)asPending beforeCart:(BOOL)beforeCart {
    MBProgressHUD *submit = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if (asPending)
        submit.labelText = @"Calculating order total...";
    else
        submit.labelText = @"Submitting order...";
    [submit show:YES];

    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSArray *keys = self.productCart.allKeys;

    if ([self.productCart.allKeys count] == 0) {
        [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Please add at least one product to the cart before continuing." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [submit hide:YES];
        return;
    }

    if (![self orderReadyForSubmission]) {
        [submit hide:YES];
        return;
    }

    if (self.coreDataOrder.orderId == 0) {
        self.coreDataOrder.status = @"pending";
        for (NSNumber *i in keys) {
            NSDictionary *dict = [self.productCart objectForKey:i];
            NSString *productID = [i stringValue];//[[self.productData objectAtIndex:] objectForKey:@"id"];
            NSString *myId = [dict objectForKey:kOrderLineItemId] != nil ? [[dict objectForKey:kOrderLineItemId] stringValue] : @"";
            NSInteger num = 0;
            if (!self.multiStore) {
                num = [[dict objectForKey:kEditableQty] integerValue];
            } else {
                NSMutableDictionary *qty = [[dict objectForKey:kEditableQty] objectFromJSONString];
                for (NSString *n in qty.allKeys) {
                    int j = [[qty objectForKey:n] intValue];
                    if (j > num) {
                        num = j;
                        if (num > 0) {
                            break;
                        }
                    }
                }
            }

            if (num > 0) {
                if ([ShowConfigurations instance].shipDates) {
                    NSMutableArray *strs = [NSMutableArray array];
                    NSArray *dates = [dict objectForKey:kOrderItemShipDates];
                    if ([dates count] > 0) {
                        NSDateFormatter *df = [[NSDateFormatter alloc] init];
                        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                        for (int i = 0; i < dates.count; i++) {
                            NSString *str = [df stringFromDate:[dates objectAtIndex:i]];
                            [strs addObject:str];
                        }
                    }

                    if ([strs count] > 0 || itemIsVoucher(dict)) {
                        NSString *lineItemId = [dict objectForKey:kOrderLineItemId] ? [[dict objectForKey:kOrderLineItemId] stringValue] : @"";
                        NSString *ePrice = [[dict objectForKey:kEditablePrice] stringValue];
                        NSString *eVoucher = [[dict objectForKey:kEditableVoucher] stringValue];
                        NSDictionary *proDict = [NSDictionary dictionaryWithObjectsAndKeys:lineItemId, kID, productID, kOrderItemID,
                                                                                           [dict objectForKey:kEditableQty], kOrderItemNum, ePrice, kOrderItemPRICE,
                                                                                           eVoucher, kOrderItemVoucher, strs, kOrderItemShipDates, nil];
                        [arr addObject:(id) proDict];
                    }
                } else {
                    NSString *ePrice = [[dict objectForKey:kEditablePrice] stringValue];
                    NSString *eVoucher = [[dict objectForKey:kEditableVoucher] stringValue];
                    NSDictionary *proDict;

                    if ([myId isEqualToString:@""]) {
                        proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, [[dict objectForKey:kEditableQty] stringValue], kOrderItemNum, ePrice, kOrderItemPRICE, eVoucher, kOrderItemVoucher, nil];
                    }
                    else {
                        proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, myId, kID, [[dict objectForKey:kEditableQty] stringValue], kOrderItemNum, ePrice, kOrderItemPRICE, eVoucher, kOrderItemVoucher, nil];
                    }
                    [arr addObject:(id) proDict];
                }
            }
        }
    } else {
        for (NSNumber *i in keys) {
            NSMutableArray *strs = nil;
            NSDictionary *dict = [self.productCart objectForKey:i];
            if ([ShowConfigurations instance].shipDates) {
                strs = [NSMutableArray array];
                NSArray *dates = [dict objectForKey:kOrderItemShipDates];
                if ([dates count] > 0) {
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
                    for (int i = 0; i < dates.count; i++) {
                        NSString *str = [df stringFromDate:[dates objectAtIndex:i]];
                        [strs addObject:str];
                    }
                }
            }
            NSString *productID = [i stringValue];//[[self.productData objectAtIndex:] objectForKey:@"id"];
            NSString *myId = [dict objectForKey:kOrderLineItemId] != nil ? [[dict objectForKey:kOrderLineItemId] stringValue] : @"";
            NSString *ePrice = [[dict objectForKey:kEditablePrice] stringValue];
            NSString *eVoucher = [[dict objectForKey:kEditableVoucher] stringValue];
            NSDictionary *proDict;
            if ([kShowCorp isEqualToString:kPigglyWiggly]) {
                if (![myId isEqualToString:@""])
                    proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, myId, kID,
                                                                         (self.multiStore ? [dict objectForKey:kEditableQty] : [[dict objectForKey:kEditableQty] stringValue]), kOrderItemNum, ePrice, kOrderItemPRICE,
                                                                         eVoucher, kOrderItemVoucher, strs, kOrderItemShipDates, nil];
                else
                    proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, (self.multiStore ? [dict objectForKey:kEditableQty] : [[dict objectForKey:kEditableQty] stringValue]), kOrderItemNum,
                                                                         ePrice, kOrderItemPRICE, strs, kOrderItemShipDates, nil];
            }
            else {
                if (![myId isEqualToString:@""])
                    proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, myId, kID, (self.multiStore ? [dict objectForKey:kEditableQty] : [[dict objectForKey:kEditableQty] stringValue]), kOrderItemNum, ePrice, kOrderItemPRICE, eVoucher, kOrderItemVoucher, nil];
                else
                    proDict = [NSDictionary dictionaryWithObjectsAndKeys:productID, kOrderItemID, (self.multiStore ? [dict objectForKey:kEditableQty] : [[dict objectForKey:kEditableQty] stringValue]), kOrderItemNum, ePrice, kOrderItemPRICE, nil];
            }
            [arr addObject:(id) proDict];
        }
    }

    [arr removeObjectIdenticalTo:nil];


    if (self.customer == nil) {
        return;
    }

    NSString *orderStatus = asPending ? @"pending" : @"complete";
    NSMutableDictionary *newOrder;

    if (!asPending) {
        NSString *_notes = [self.customer objectForKey:kNotes];
        if (_notes == nil || [_notes isEqualToString:@""])
            _notes = @"";
        NSString *_shipFlag = [self.customer objectForKey:kShipFlag];
        if (_shipFlag == nil)
            _shipFlag = @"0";
        NSString *shipNotes = [self.customer objectForKey:kShipNotes];
        shipNotes = (shipNotes == nil || [shipNotes isKindOfClass:[NSNull class]]) ? @"" : shipNotes;

        newOrder = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self.customer objectForKey:@"id"], kOrderCustID,
                                                                     _notes, kNotes, shipNotes, kShipNotes, [self.customer objectForKey:kAuthorizedBy], kAuthorizedBy,
                                                                     _shipFlag, kShipFlag, orderStatus, kOrderStatus,
                                                                     arr, kOrderItems, nil];
    } else {
        newOrder = [NSMutableDictionary dictionaryWithObjectsAndKeys:[self.customer objectForKey:@"id"], kOrderCustID, orderStatus, kOrderStatus, arr, kOrderItems, nil];
    }
    if (printThisOrder) {
        [newOrder setObject:@"TRUE" forKey:@"print"];
        [newOrder setObject:[NSNumber numberWithInt:_printStationId] forKey:@"printer"];
    }

    NSDictionary *final = [NSDictionary dictionaryWithObjectsAndKeys:newOrder, kOrder, nil];

    NSString *url;
    if (_coreDataOrder.orderId == 0) {
        url = [NSString stringWithFormat:@"%@?%@=%@", kDBORDER, kAuthToken, self.authToken];
    } else {
        url = [NSString stringWithFormat:@"%@?%@=%@", [NSString stringWithFormat:kDBORDEREDITS(_coreDataOrder.orderId)], kAuthToken, self.authToken];
    }

    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];
    [client setParameterEncoding:AFJSONParameterEncoding];

    NSString *method = @"POST";
    if (_coreDataOrder.orderId > 0)
        method = @"PUT";

    NSMutableURLRequest *request = [client requestWithMethod:method path:nil parameters:final];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
            success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                [submit hide:YES];
                self.unsavedChangesPresent = NO;
                AnOrder *anOrder = [[AnOrder alloc] initWithJSONFromServer:(NSDictionary *) JSON];
                if (asPending) {
                    NSNumber *totalCost = anOrder.total;
                    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                    nf.formatterBehavior = NSNumberFormatterBehavior10_4;
                    nf.maximumFractionDigits = 2;
                    nf.minimumFractionDigits = 2;
                    nf.minimumIntegerDigits = 1;

                    double grossTotal = 0.0;
                    double voucherTotal = 0.0;
                    int orderId = [anOrder.orderId intValue];
                    NSArray *lineItems = anOrder.lineItems;
                    self.discountItems = [NSMutableDictionary dictionary];
                    for (int i = 0; i < [lineItems count]; i++) {
                        ALineItem *details = [lineItems objectAtIndex:i];
                        NSString *category = details.category;
                        if ([category isEqualToString:@"standard"]) {
                            int productId = [details.productId intValue];
                            int lineItemId = [details.itemId intValue];
                            Cart *cartItem = [self findCartForId:productId];
                            if (cartItem != nil) {
                                cartItem.orderLineItem_id = lineItemId;
                            }
                            NSMutableDictionary *dict = [self.productCart objectForKey:[NSNumber numberWithInt:productId]];
                            [dict setObject:[NSNumber numberWithInt:lineItemId] forKey:kOrderLineItemId];

                            int qty = 0;
                            if (self.multiStore) {
                                NSDictionary *quantitiesByStore = [[dict objectForKey:kEditableQty] objectFromJSONString];
                                for (NSString *storeId in [quantitiesByStore allKeys]) {
                                    qty += [[quantitiesByStore objectForKey:storeId] intValue];
                                }
                            }
                            else {
                                qty += [[dict objectForKey:kEditableQty] intValue];
                            }
                            double price = [[dict objectForKey:kEditablePrice] doubleValue];
                            int numOfShipDates = [[dict objectForKey:kOrderItemShipDates] count];
                            grossTotal += qty * price * (numOfShipDates == 0 ? 1 : numOfShipDates);
                            if ([dict objectForKey:kEditableVoucher] != nil && ![[dict objectForKey:kEditableVoucher] isKindOfClass:[NSNull class]]) {
                                double voucherPrice = [[dict objectForKey:kEditableVoucher] doubleValue];
                                voucherTotal += qty * voucherPrice * (numOfShipDates == 0 ? 1 : numOfShipDates);
                            }
                        } else if ([category isEqualToString:@"discount"]) {
                            [self.discountItems setObject:details forKey:details.itemId];
                        }
                    }
                    self.totalCost.text = [nf stringFromNumber:[NSNumber numberWithDouble:grossTotal]];
                    self.totalCost.textColor = [UIColor blackColor];
                    [_coreDataOrder setOrderId:orderId];
                    [_coreDataOrder setTotalCost:[totalCost doubleValue]];
                    [[CoreDataUtil sharedManager] saveObjects];
                    if (beforeCart)
                        [[NSNotificationCenter defaultCenter] postNotificationName:kLaunchCart object:nil];
                } else {
                    [self Return];
                }
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

                [submit hide:YES];
                NSString *errorMsg = [NSString stringWithFormat:@"There was an error submitting the order. %@", error.localizedDescription];
                [[[UIAlertView alloc] initWithTitle:@"Error!" message:errorMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

            }];

    [operation start];
}

- (void)Return {

    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate != nil) {
            NSNumber *orderId = nil;
            if (self.coreDataOrder != nil) {
                orderId = self.coreDataOrder != nil? [NSNumber numberWithInt:self.coreDataOrder.orderId] : nil;
                [[CoreDataUtil sharedManager] deleteObject:self.coreDataOrder];  //always delete the core data entry before exiting this view. core data should contain an entry only if the order crashed in the middle of an order
            }
            [self.delegate Return:orderId];
        }
    }];
}

BOOL itemIsVoucher(NSDictionary *dict);

BOOL itemIsVoucher(NSDictionary *dict) {
    int idx = [[dict objectForKey:kProductIdx] intValue];
    //int invtid = [[dict objectForKey:kProductInvtid] intValue];
    NSString *invtId = [dict objectForKey:kProductInvtid];

    return idx == 0 && ([invtId isEmpty] || [invtId isEqualToString:@"0"]);
}

- (BOOL)orderReadyForSubmission {
    NSArray *keys = self.productCart.allKeys;
    for (NSString *i in keys) {
        NSDictionary *dict = [self.productCart objectForKey:i];

        BOOL hasQty = NO;
        NSInteger num = 0;
        if (!self.multiStore) {
            num = [[dict objectForKey:kEditableQty] integerValue];
        } else {
            NSMutableDictionary *qty = [[dict objectForKey:kEditableQty] objectFromJSONString];
            for (NSString *n in qty.allKeys) {
                int j = [[qty objectForKey:n] intValue];
                if (j > num) {
                    num = j;
                    if (num > 0) {
                        break;
                    }
                }
            }
        }

        BOOL hasShipDates = NO;
        if (num > 0) {
            hasQty = YES;
            NSArray *dates = [dict objectForKey:kOrderItemShipDates];
            NSMutableArray *strs = [NSMutableArray array];

            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            for (int i = 0; i < dates.count; i++) {
                NSString *str = [df stringFromDate:[dates objectAtIndex:i]];
                [strs addObject:str];
            }

            if ([strs count] > 0) {
                hasShipDates = YES;
            }
        }

        if (!itemIsVoucher(dict) && (!hasQty || !(hasShipDates || (self.showShipDates == NO)))) {
            [[[UIAlertView alloc] initWithTitle:@"Missing Data" message:@"All items in the cart must have a quantity and ship date(s) before the order can be submitted. Check cart items and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            return NO;
        }
    }

    return YES;
}

//SG: This method loads the view that is displayed after you Submit an order. It prompts the user for information like Authorized By and Notes.
- (IBAction)finishOrder:(id)sender {
    if ([self orderReadyForSubmission]) {
        if ([[self.productCart allKeys] count] <= 0) {
            [[[UIAlertView alloc] initWithTitle:@"Cart Empty." message:@"You don't have anything in your cart!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }
        CIFinalCustomerInfoViewController *ci = [[CIFinalCustomerInfoViewController alloc] initWithNibName:@"CIFinalCustomerInfoViewController" bundle:nil];
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
    [self.hiddenTxt becomeFirstResponder];
    [self.hiddenTxt resignFirstResponder];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(launchCart) name:kLaunchCart object:nil];
    [self sendOrderToServer:NO asPending:YES beforeCart:YES];
}

- (void)launchCart {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLaunchCart object:nil];
    CICartViewController *cart = [[CICartViewController alloc] initWithNibName:@"CICartViewController" bundle:nil];
    cart.delegate = self;
    cart.productData = [NSMutableDictionary dictionaryWithDictionary:self.productCart];
    cart.productCart = [NSMutableDictionary dictionaryWithDictionary:self.productCart];
    cart.discountItems = [NSMutableDictionary dictionaryWithDictionary:self.discountItems];
    cart.modalPresentationStyle = UIModalPresentationFullScreen;
    cart.customer = self.customer;
    [self presentViewController:cart animated:YES completion:nil];
}

- (IBAction)vendorTouch:(id)sender {
    if (!self.vendorView.hidden && !self.dismissVendor.hidden) {
        self.vendorView.hidden = YES;
        self.dismissVendor.hidden = YES;
        return;
    }
    [selectedIdx removeAllObjects];

    if (vendorsData == nil) {
        MBProgressHUD *venderLoading = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        venderLoading.labelText = @"Loading vendors from your vendor group...";
        [venderLoading show:YES];

        if (self.loggedInVendorId && ![self.loggedInVendorId isKindOfClass:[NSNull class]]) {

            NSString *url = [NSString stringWithFormat:@"%@&%@=%@", kDBGETVENDORSWithVG(self.loggedInVendorGroupId), kAuthToken, self.authToken];
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            AFJSONRequestOperation *jsonOp = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

                        NSArray *results = [NSArray arrayWithArray:JSON];
                        if (results == nil || [results isKindOfClass:[NSNull class]] || results.count == 0 || [results objectAtIndex:0] == nil || [[results objectAtIndex:0] objectForKey:@"vendors"] == nil) {
                            [venderLoading hide:YES];
                            [[[UIAlertView alloc] initWithTitle:@"Error!" message:@"Problem loading vendors! If this problem persists please notify Convention Innovations!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                            return;
                        }

                        NSArray *vendors = [[results objectAtIndex:0] objectForKey:@"vendors"];
                        NSMutableArray *vs = [NSMutableArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any", @"name", @"0", @"id", nil], nil];

                        [vendors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                            NSDictionary *dict = (NSDictionary *) obj;
                            [vs addObject:dict];
                        }];

                        vendorsData = [vs mutableCopy];
                        [venderLoading hide:YES];
                        [self loadBulletins];

                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

                        [[[UIAlertView alloc] initWithTitle:@"Error!"
                                                    message:[NSString stringWithFormat:@"Got error retrieving vendors for vendor group:%@", error.localizedDescription]
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];

                        vendorsData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any", @"name", @"0", @"id", nil], nil];
                        [venderLoading hide:YES];
                        [self showVendorView];
                    }];

            [jsonOp start];

        } else {
            [venderLoading hide:YES];
            vendorsData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Any", @"name", @"0", @"id", nil], nil];
            [self showVendorView];
        }
    } else {
        [self showVendorView];
    }
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
        NSDictionary *dict = [self.resultData objectAtIndex:idx.intValue];
        if ([[dict objectForKey:@"invtid"] isEqualToString:@"0"]) {
            continue;
        }
        NSDate *startDate = [[NSDate alloc] init];
        NSDate *endDate = [[NSDate alloc] init];
        if ([dict objectForKey:kProductShipDate1] != nil && ![[dict objectForKey:kProductShipDate1] isKindOfClass:[NSNull class]]) {
            startDate = [df dateFromString:[dict objectForKey:kProductShipDate1]];
        }
        if ([dict objectForKey:kProductShipDate2] != nil && ![[dict objectForKey:kProductShipDate2] isKindOfClass:[NSNull class]]) {
            endDate = [df dateFromString:[dict objectForKey:kProductShipDate2]];
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
            NSMutableDictionary *dict = [self.resultData objectAtIndex:[idx integerValue]];
            NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
            NSMutableDictionary *edict = [self createIfDoesntExist:editableDict orig:dict];
            if (edict == nil) {
                edict = editableDict;
            }
            [edict setObject:dates forKey:kOrderItemShipDates];
            [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
            if ([self.productCart objectForKey:[dict objectForKey:@"id"]] != nil) {
                NSMutableDictionary *dict2 = [self.productCart objectForKey:[dict objectForKey:@"id"]];
                [dict2 setObject:dates forKey:kOrderItemShipDates];
                [self updateShipDatesInCartWithId:[[dict objectForKey:@"id"] intValue] forDates:dates];
                self.unsavedChangesPresent = YES;
            }
            [self updateCellColorForId:[idx integerValue]];
        }];
        [selectedIdx removeAllObjects];
        [self.products reloadData];
        [strongCalView dismissViewControllerAnimated:NO completion:nil];
    };
    __block NSMutableArray *selectedArr = [NSMutableArray array];
    for (NSNumber *idx in selectedIdx) {
        NSMutableDictionary *dict = [self.resultData objectAtIndex:[idx integerValue]];
        NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
        if (editableDict && [editableDict objectForKey:kOrderItemShipDates]) {
            if ([[editableDict objectForKey:kOrderItemShipDates] isKindOfClass:[NSArray class]] && ((NSArray *) [editableDict objectForKey:kOrderItemShipDates]).count > 0) {
                [selectedArr addObjectsFromArray:((NSArray *) [editableDict objectForKey:kOrderItemShipDates])];
            }
        }
    }
    NSArray *selectedDates = [[[NSOrderedSet orderedSetWithArray:selectedArr] array] copy];
    if (ranges.count > 1) {
        NSMutableSet *final = [NSMutableSet setWithArray:[ranges objectAtIndex:0]];
        for (int i = 1; i < ranges.count; i++) {
            NSSet *tempset = [NSSet setWithArray:[ranges objectAtIndex:i]];
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

- (void)VoucherChange:(double)price forIndex:(int)idx {
    NSMutableDictionary *dict = [self.resultData objectAtIndex:idx];
    NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    NSMutableDictionary *edict = [self createIfDoesntExist:editableDict orig:dict];
    if (edict == nil ) {
        edict = editableDict;
    }
    [edict setObject:[NSNumber numberWithDouble:price] forKey:kEditableVoucher];
    [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
    self.unsavedChangesPresent = YES;
}

- (void)PriceChange:(double)price forIndex:(int)idx {
    //    NSString* key = [[self.productData objectAtIndex:idx] objectForKey:@"id"];
    NSMutableDictionary *dict = [self.resultData objectAtIndex:idx];
    NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];

    NSMutableDictionary *edict = [self createIfDoesntExist:editableDict orig:dict];

    if (edict == nil ) {
        edict = editableDict;
    }

    [edict setObject:[NSNumber numberWithDouble:price] forKey:kEditablePrice];
    [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
    self.unsavedChangesPresent = YES;
}

- (void)QtyChange:(double)qty forIndex:(int)idx {
    NSString *key = [[self.resultData objectAtIndex:idx] objectForKey:@"id"];
    NSMutableDictionary *dict = [self.resultData objectAtIndex:idx];
    NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];

    NSMutableDictionary *edict = [self createIfDoesntExist:editableDict orig:dict];


    if (edict == nil ) {
        edict = editableDict;
    }

    [edict setObject:[NSNumber numberWithDouble:qty] forKey:kEditableQty];
    [editableData setObject:edict forKey:[dict objectForKey:@"id"]];

    if (qty > 0) {
        [self AddToCartForIndex:idx];
    } else {
        NSDictionary *details = [self.productCart objectForKey:key];
        [self.productCart removeObjectForKey:key];
        [self removeLineItemFromProductCart:[key intValue]];
        if (_coreDataOrder.orderId > 0) {
            if ([details objectForKey:kOrderLineItemId])
                [self deleteLineItemFromOrder:[[details objectForKey:kOrderLineItemId] integerValue]];
        }
    }

    [self updateCellColorForId:idx];

    self.totalCost.textColor = [UIColor redColor];
    self.unsavedChangesPresent = YES;

}

- (void)deleteLineItemFromOrder:(NSInteger)lineItemId {
    NSString *url = [NSString stringWithFormat:@"%@?%@=%@", [NSString stringWithFormat:kDBOrderLineItemDelete(lineItemId)], kAuthToken, self.authToken];
    AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];

    [client deletePath:nil parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    }          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"DELETE failed for line item id: %d", lineItemId);
    }];

}

- (void)AddToCartForIndex:(int)idx {
    NSNumber *key = [[self.resultData objectAtIndex:idx] objectForKey:@"id"];
    NSMutableDictionary *dict = [[self.resultData objectAtIndex:idx] mutableCopy];
    NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];

    NSMutableDictionary *edict = [self createIfDoesntExist:editableDict orig:dict];

    if (edict == nil ) {
        edict = editableDict;
    }

    [dict addEntriesFromDictionary:edict];

    NSDictionary *oldCartItem = [self.productCart objectForKey:key];
    if (oldCartItem != nil) {
        NSNumber *lineItemId = [oldCartItem objectForKey:kOrderLineItemId];
        if (lineItemId != nil)
            [dict setObject:lineItemId forKey:kOrderLineItemId];
    }

    [self.productCart setObject:dict forKey:key];

    // add item to core data store
    [self addLineItemToProductCart:dict];

}

#pragma mark - Core Data routines

- (Cart *)findCartForId:(int)cartId {
    for (Cart *cart in _coreDataOrder.carts) {
        if (cart.cartId == cartId)
            return cart;
    }

    return nil;
}

// Adds a Cart object to the data store using the key/value pairs in the dictionary.
- (void)addLineItemToProductCart:(NSMutableDictionary *)dict {
    NSArray *dates = [dict objectForKey:kOrderItemShipDates];

    NSManagedObjectContext *context = _coreDataOrder.managedObjectContext;
    int cartId = [[dict objectForKey:kID] intValue];
    Cart *oldCart = [self findCartForId:cartId];

    if (!oldCart) {
        NSMutableDictionary *valuesForCart = [self convertForCoreData:dict];

        Cart *cart = [NSEntityDescription insertNewObjectForEntityForName:@"Cart" inManagedObjectContext:context];
        [_coreDataOrder addCartsObject:cart];
        @try {
            [cart setValuesForKeysWithDictionary:valuesForCart];
        }
        @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
        }

        if (dates.count > 0) {
            //NSMutableArray *shipDates = [NSMutableArray arrayWithCapacity:dates.count];
            for (int i = 0; i < dates.count; i++) {

                ShipDate *sd = [NSEntityDescription insertNewObjectForEntityForName:@"ShipDate" inManagedObjectContext:cart.managedObjectContext];
                [cart addShipdatesObject:sd];
                [sd setShipdate:[dates objectAtIndex:i]];
            }
        }

        NSError *error = nil;
        if (![context save:&error]) {
            NSString *msg = [NSString stringWithFormat:@"There was an error saving the product item. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }
    else {
        if (!self.multiStore) {
            [oldCart setEditableQty:[[dict objectForKey:kEditableQty] stringValue]];
        } else {
            [oldCart setEditableQty:[dict objectForKey:kEditableQty]];
        }

        if (dates && [dates count] > 0) {
            [self updateShipDates:dates inCart:oldCart];
        }
        NSError *error = nil;
        if (![context save:&error]) {
            NSString *msg = [NSString stringWithFormat:@"There was an error updating the product item. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }
}

// This method takes the values in the dictionary and makes sure they are in the
// propery object format to be translated to the core data Cart entity.
- (NSMutableDictionary *)convertForCoreData:(NSMutableDictionary *)dict {
    NSMutableDictionary *cartValues = [NSMutableDictionary dictionaryWithCapacity:dict.count];

    [cartValues setValue:@"standard" forKey:@"category"];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductAdv asFloat:NO] forKey:kProductAdv];
    [cartValues setValue:[dict objectForKey:kProductCaseQty] forKey:kProductCaseQty];
    [cartValues setValue:[dict objectForKey:kProductCompany] forKey:kProductCompany];
    [cartValues setValue:[dict objectForKey:kProductCreatedAt] forKey:kProductCreatedAt];
    [cartValues setValue:[dict objectForKey:kProductDescr] forKey:kProductDescr];

    if ([kShowCorp isEqualToString:kFarris])
        [cartValues setValue:[dict objectForKey:kProductDescr2] forKey:kProductDescr2];

    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductDirShip asFloat:NO] forKey:kProductDirShip];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductDiscount asFloat:YES] forKey:kProductDiscount];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kEditablePrice asFloat:YES] forKey:kEditablePrice];
    if (!self.multiStore) {
        [cartValues setValue:[[dict objectForKey:kEditableQty] stringValue] forKey:kEditableQty];
    } else {
        [cartValues setValue:[dict objectForKey:kEditableQty] forKey:kEditableQty];
    }
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kEditableVoucher asFloat:YES] forKey:kEditableVoucher];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kID asFloat:NO] forKey:@"cartId"];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductIdx asFloat:NO] forKey:kProductIdx];
    if ([dict objectForKey:kProductImportID] && ![[dict objectForKey:kProductImportID] isEqual:[NSNull null]]) {
        [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductImportID asFloat:NO] forKey:kProductImportID];
    } else {
        [cartValues setValue:[NSNull null] forKey:kProductImportID];
    }
    [cartValues setValue:[dict objectForKey:kProductInitialShow] forKey:kProductInitialShow];
    [cartValues setValue:[dict objectForKey:kProductInvtid] forKey:kProductInvtid];
    [cartValues setValue:[dict objectForKey:kProductLineNbr] forKey:kProductLineNbr];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:kProductNew asFloat:NO] forKey:kProductNew];
    [cartValues setValue:[dict objectForKey:kProductPartNbr] forKey:kProductPartNbr];
    [cartValues setValue:[dict objectForKey:kProductRegPrc] forKey:kProductRegPrc];
    [cartValues setValue:[dict objectForKey:kProductShipDate1] forKey:kProductShipDate1];
    [cartValues setValue:[dict objectForKey:kProductShipDate2] forKey:kProductShipDate2];
    [cartValues setValue:[dict objectForKey:kProductShowPrice] forKey:kProductShowPrice];
    [cartValues setValue:[dict objectForKey:kProductUniqueId] forKey:kProductUniqueId];
    [cartValues setValue:[dict objectForKey:kProductUom] forKey:kProductUom];
    [cartValues setValue:[dict objectForKey:kProductUpdatedAt] forKey:kProductUpdatedAt];
    [cartValues setValue:[dict objectForKey:kProductVendID] forKey:kProductVendID];
    [cartValues setValue:[self getNumberFromDictionary:dict forKey:@"vendor_id" asFloat:NO] forKey:@"vendor_id"];
    [cartValues setValue:[dict objectForKey:kProductVoucher] forKey:kProductVoucher];

    return cartValues;
}

- (void)updateShipDatesInCartWithId:(int)cartId forDates:(NSArray *)dates {
    if (dates && [dates count] > 0) {
        Cart *cart = [self findCartForId:cartId];
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
//            [cart removeShipdates:[cart shipdates]];
            for (NSDate *aDate in sortedDates) {
                ShipDate *sd = [NSEntityDescription insertNewObjectForEntityForName:@"ShipDate" inManagedObjectContext:cart.managedObjectContext];
//                [cart addShipdatesObject:sd];
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

// Returns an NSNumber object from the dictonary for a given key. If asFloat=YES, returns floatValue, otherwise integerValue.
- (NSNumber *)getNumberFromDictionary:(NSMutableDictionary *)dict forKey:(NSString *)key asFloat:(BOOL)asFloat {
    NSNumber *num;
    if (!asFloat) {
        num = [NSNumber numberWithInt:[[dict objectForKey:key] integerValue]];
    } else {
        num = [NSNumber numberWithFloat:[[dict objectForKey:key] floatValue]];
    }

    return num;
}

// Removes a Cart object from the data store for a given product id.
- (void)removeLineItemFromProductCart:(int)productId {
    Cart *oldCart = [self findCartForId:productId];
    if (oldCart) {
        [[CoreDataUtil sharedManager] deleteObject:oldCart];
        [[CoreDataUtil sharedManager] saveObjects];
    }
}

//- (void)cancelOrder {
//    if (self.viewInitialized && self.coreDataOrder) {
//        [[CoreDataUtil sharedManager] deleteObject:_coreDataOrder];
//        [[CoreDataUtil sharedManager] saveObjects];
//    }
//}

- (void)updateCellColorForId:(NSUInteger)cellId {
    NSMutableDictionary *dict = [self.resultData objectAtIndex:cellId];
    NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];
    NSString *invtid = [dict objectForKey:@"invtid"];
    NSArray *cells = [self.products visibleCells];
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        for (PWProductCell *cell in cells) {
            if ([invtid isEqualToString:cell.InvtID.text]) {
                BOOL hasQty = NO;

                //if you want it to highlight based on qty uncomment this:
                if (self.multiStore && editableDict && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]]
                        && [[[editableDict objectForKey:kEditableQty] objectFromJSONString] isKindOfClass:[NSDictionary class]]
                        && ((NSDictionary *) [[editableDict objectForKey:kEditableQty] objectFromJSONString]).allKeys.count > 0) {
                    for (NSNumber *n in [[[editableDict objectForKey:kEditableQty] objectFromJSONString] allObjects]) {
                        if (n > 0)
                            hasQty = YES;
                    }
                } else if (editableDict && [editableDict objectForKey:kEditableQty] && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]] && [[editableDict objectForKey:kEditableQty] integerValue] > 0) {
                    hasQty = YES;
                } else if (editableDict && [editableDict objectForKey:kEditableQty] && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]] && [[editableDict objectForKey:kEditableQty] intValue] > 0) {
                    hasQty = YES;
                } else {
                    cell.backgroundView = nil;
                }

                BOOL hasShipDates = NO;
                NSArray *shipDates = [editableDict objectForKey:kOrderItemShipDates];
                if (shipDates && [shipDates count] > 0) {
                    hasShipDates = YES;
                }

                NSNumber *zero = [NSNumber numberWithInt:0];
                BOOL isVoucher = [[dict objectForKey:kProductIdx] isEqualToNumber:zero]
                        && [[dict objectForKey:kProductInvtid] isEqualToString:[zero stringValue]];
                if (!isVoucher) {
                    if (hasQty && (hasShipDates || (self.showShipDates == NO))) {
                        UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                        view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
                        cell.backgroundView = view;
                    } else if (hasQty ^ hasShipDates) {
                        UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                        view.backgroundColor = [UIColor colorWithRed:0.839 green:0.655 blue:0.655 alpha:0.75];
                        cell.backgroundView = view;
                    }
                }
            }
        }
    } else if ([kShowCorp isEqualToString:kFarris]) {
        for (FarrisProductCell *cell in cells) {
            if ([invtid isEqualToString:cell.itemNumber.text]) {
                BOOL hasQty = NO;

                //if you want it to highlight based on qty uncomment this:
                if (editableDict && [editableDict objectForKey:kEditableQty] && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSString class]] && [[editableDict objectForKey:kEditableQty] integerValue] > 0) {
                    hasQty = YES;
                } else if (editableDict && [editableDict objectForKey:kEditableQty] && [[editableDict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]] && [[editableDict objectForKey:kEditableQty] intValue] > 0) {
                    hasQty = YES;
                } else {
                    cell.backgroundView = nil;
                }

                if (hasQty) {
                    UIView *view = [[UIView alloc] initWithFrame:cell.frame];
                    view.backgroundColor = [UIColor colorWithRed:0.722 green:0.871 blue:0.765 alpha:0.75];
                    cell.backgroundView = view;
                }
            }
        }
    }
}

#pragma mark - line item entry

- (void)QtyTouchForIndex:(int)idx {
    if ([self.poController isPopoverVisible]) {
        [self.poController dismissPopoverAnimated:YES];
    } else {
        if (!self.storeQtysPO) {
            self.storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }
        NSMutableDictionary *dict = [self.resultData objectAtIndex:idx];
        NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];

        NSMutableDictionary *edict = [self createIfDoesntExist:editableDict orig:dict];

        if (edict == nil ) {
            edict = editableDict;
        }

        if ([[edict objectForKey:kEditableQty] isKindOfClass:[NSNumber class]]) {
            NSArray *storeNums = [[self.customer objectForKey:kStores] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                NSNumber *n1 = (NSNumber *) obj1;
                NSNumber *n2 = (NSNumber *) obj2;
                return [n1 compare:n2];
            }];


            NSMutableDictionary *stores = [NSMutableDictionary dictionaryWithCapacity:storeNums.count + 1];

            [stores setValue:[NSNumber numberWithInt:0] forKey:[self.customer objectForKey:kCustID]];
            for (int i = 0; i < storeNums.count; i++) {
                [stores setValue:[NSNumber numberWithInt:0] forKey:[[storeNums objectAtIndex:i] stringValue]];
//                DLog(@"setting %@ to %@ so stores is now:%@",[storeNums objectAtIndex:i],[NSNumber numberWithInt:0],stores);
            }

            NSString *JSON = [stores JSONString];
            [edict setObject:JSON forKey:kEditableQty];
        }
        self.storeQtysPO.stores = [[[edict objectForKey:kEditableQty] objectFromJSONString] mutableCopy];
        [editableData setObject:edict forKey:[dict objectForKey:@"id"]];
        self.storeQtysPO.tag = idx;
        self.storeQtysPO.delegate = self;
        CGRect frame = [self.products rectForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        frame = CGRectOffset(frame, 750, 0);
//        DLog(@"pop from frame:%@",NSStringFromCGRect(frame));
        self.poController = [[UIPopoverController alloc] initWithContentViewController:self.storeQtysPO];
        [self.poController presentPopoverFromRect:frame inView:self.products permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)QtyTableChange:(NSMutableDictionary *)qty forIndex:(int)idx {
    NSString *JSON = [qty JSONString];

    NSString *key = [[self.resultData objectAtIndex:idx] objectForKey:@"id"];

    NSMutableDictionary *dict = [self.resultData objectAtIndex:idx];
    NSMutableDictionary *editableDict = [editableData objectForKey:[dict objectForKey:@"id"]];

    NSMutableDictionary *edict = [self createIfDoesntExist:editableDict orig:dict];

    if (edict == nil ) {
        edict = editableDict;
    }

    [edict setValue:JSON forKey:kEditableQty];
    [editableData setObject:edict forKey:key];

    int highestQty = -1;

    for (NSString *n in qty.allKeys) {
        int j = [[qty objectForKey:n] intValue];
        if (j > highestQty) {
            highestQty = j;
            if (highestQty > 0) {
                break;
            }
        }
    }


    if (highestQty > 0) {
        [self AddToCartForIndex:idx];
    } else {
        [self.productCart removeObjectForKey:key];
    }

    [self updateCellColorForId:idx];
    self.unsavedChangesPresent = YES;
}

#pragma mark - keyboard functionality 

- (void)dismissKeyboard {

}

- (NSDictionary *)getCustomerInfo {
    return [self.customer copy];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        [self Return];
    }
}

#pragma mark - Product search

- (void)searchTextUpdated:(UITextField *)textField {
    [self searchProducts:textField];
}

- (IBAction)searchProducts:(id)sender {
    if (self.productMap == nil|| [self.productMap isKindOfClass:[NSNull class]] || [self.productMap count] == 0) return;
    if ([self.searchText.text isEqualToString:@""]) {
        self.resultData = [[self.productMap allValues] mutableCopy];
    } else {
        NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
            NSMutableDictionary *dict = (NSMutableDictionary *) obj;
            NSString *invtid = nil;
            if ([dict objectForKey:kProductInvtid] && ![[dict objectForKey:kProductInvtid] isKindOfClass:[NSNull class]]) {
                if ([[dict objectForKey:kProductInvtid] respondsToSelector:@selector(stringValue)]) {
                    invtid = [[dict objectForKey:kProductInvtid] stringValue];
                } else {
                    invtid = [dict objectForKey:kProductInvtid];
                }
            } else {
                invtid = @"";
            }
            NSString *descrip = [dict objectForKey:kProductDescr];
            NSString *desc2 = @"";
            if ([kShowCorp isEqualToString:kFarris])
                desc2 = [dict objectForKey:kProductDescr2];
            NSString *test = [self.searchText.text uppercaseString];
            return [invtid hasPrefix:test] || [[descrip uppercaseString] contains:test] || [[desc2 uppercaseString] contains:test];
        }];
        self.resultData = [[[self.productMap allValues] filteredArrayUsingPredicate:pred] mutableCopy];
        [selectedIdx removeAllObjects];
    }
    [self.products reloadData];
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        for (PWProductCell *cell in self.products.visibleCells) {
            if ([cell.quantity isFirstResponder]) {
                [cell.quantity resignFirstResponder];
                break;
            }
        }
    }
}

#pragma mark - UITextFielDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.restorationIdentifier isEqualToString:@"SearchField"]) {
        [self.view endEditing:YES];
    }

    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

#pragma mark - Reachability delegate methods

- (void)networkLost {

    [self.ciLogo setImage:[UIImage imageNamed:@"ci_red.png"]];
}

- (void)networkRestored {

    [self.ciLogo setImage:[UIImage imageNamed:@"ci_green.png"]];
}

#pragma mark - Vendor View Delegate

- (void)setVendor:(NSInteger)vendorId {
    currentVendor = vendorId;
}

- (void)setBulletin:(NSInteger)bulletinId {
    currentBulletin = bulletinId;
}

- (void)dismissVendorPopover {
    if ([self.poController isPopoverVisible])
        [self.poController dismissPopoverAnimated:YES];
    [self loadProducts];
}

#pragma CICartViewController Delegate

- (void)setSelectedRow:(NSUInteger)index {
    selectedItemRowIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
}

- (void)keyboardWillShow {

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.products.contentOffset = selectedItemRowIndexPath ? CGPointMake(0, [self.products rowHeight] * selectedItemRowIndexPath.row) : CGPointMake(0, 0);
    [UIView commitAnimations];
}

- (void)keyboardDidHide {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    self.products.contentOffset = CGPointMake(0, 0);
    [UIView commitAnimations];
}

@end