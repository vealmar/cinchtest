//
//  CIProductViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CISlidingProductViewController.h"
#import "CIProductViewController.h"
#import "config.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "ShowConfigurations.h"
#import "CoreDataManager.h"
#import "CIProductViewControllerHelper.h"
#import "NilUtil.h"
#import "NumberUtil.h"
#import "Vendor.h"
#import "Bulletin.h"
#import "NotificationConstants.h"
#import "BulletinViewController.h"
#import "EditableEntity+Extensions.h"
#import "JMStaticContentTableViewController.h"
#import "Order.h"
#import "Aspects.h"
#import "ThemeUtil.h"
#import "CIKeyboardUtil.h"
#import "CIProductTableViewController.h"
#import "CIBarButton.h"
#import "Order+Extensions.h"
#import "CurrentSession.h"
#import "OrderCoreDataManager.h"
#import "OrderTotals.h"

@interface CIProductViewController () {
    NSInteger initialVendor;
    NSInteger currentVendor; //Logged in vendor's id or the vendor selected in the bulletin drop down
    int currentBulletin; //Bulletin selected in the bulletin drop down
    NSArray *vendorsData; //Vendors belonging to the same vendor group as the logged in vendors. These vendors are displayed in the bulletins drop down.
    NSDictionary *bulletins;
    CIProductViewControllerHelper *helper;
    CIFinalCustomerInfoViewController *customerInfoViewController;
}
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
    self.order = nil;
    self.viewInitialized = NO;
    initialVendor = ![ShowConfigurations instance].vendorMode &&
            [CurrentSession instance].vendorId &&
            ![[CurrentSession instance].vendorId isKindOfClass:[NSNull class]] ?
            [[CurrentSession instance].vendorId intValue] : 0;
    currentVendor = initialVendor;
    currentBulletin = 0;
    self.filterCartSwitch = NO;
    self.orderSubmitted = NO;
    self.selectedLineItems = [NSMutableSet set];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:0.133 green:0.129 blue:0.137 alpha:1];

    initialVendor = ![ShowConfigurations instance].vendorMode &&
            [CurrentSession instance].vendorId &&
            ![[CurrentSession instance].vendorId isKindOfClass:[NSNull class]] ?
            [[CurrentSession instance].vendorId intValue] : 0;
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

        if (self.order == nil) {
            if (self.newOrder) {
                self.order = [Order newOrderForCustomer:self.customer];
            }
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onCartQuantityChange:) name:LineQuantityChangedNotification object:nil];

    // listen for changes KVO
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(order)) options:0 context:nil];
    [self addObserver:self
           forKeyPath:[NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(order)), NSStringFromSelector(@selector(shipDates))]
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
        if ([self hasOrderConfirmationFields]) {
            [self loadNotesForm];
        } else {
            [self submit:nil];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(order))];
    [self removeObserver:self forKeyPath:[NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(order)), NSStringFromSelector(@selector(shipDates))]];
}

# pragma mark - Initialization

- (void)loadVendors {
    NSArray *vendors = [CoreDataManager getVendors:[CurrentSession instance].managedObjectContext];
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

//@todo orders when exiting an order without saving, revert to previous state (presumably with sync = true)
- (void)loadOrder:(int)orderRecoverySelection {
    BOOL orderExistsOnServer = self.order.orderId != nil && [self.order.orderId intValue] != 0;

    if (self.order && (self.order.isPartial || (orderExistsOnServer && !self.order.inSync))) {
        // unsynced order in the middle of whose editing the app crashed, thus leaving a copy in core data.
        if (orderRecoverySelection == OrderRecoverySelectionNone) {
            //Prompt user to decide if they want to overlay server order with core data values.
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Recover Order?" message:@"This order record is out-of-sync with the server indicating that it was never saved. Select Yes to recover these changes; No to start from the last version from the last synced version."
                                                           delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
            [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
                if ([[alert buttonTitleAtIndex:buttonIndex] isEqualToString:@"YES"]) {
                    [self loadOrder:OrderRecoverySelectionYes];
                } else
                    [self loadOrder:OrderRecoverySelectionNo];
                [self deserializeOrder];
            }];
        } else if (orderRecoverySelection == OrderRecoverySelectionNo) {
            [self.order.managedObjectContext refreshObject:self.order mergeChanges:NO];
        }
    } else if (!self.order) {
        NSLog(@"Invalid state, product view has no order.");
    }
}

- (void)loadProductsForCurrentVendorAndBulletin {
    [self.productTableViewController filterToVendorId:currentVendor bulletinId:currentBulletin inCart:self.filterCartSwitch.on queryTerm:nil];
    [self updateNavigationTitle];
}

- (void)deserializeOrder {
    [self reloadTable];
    [self updateTotals];
}

- (void)updateNavigationTitle {
    if (self.filterCartSwitch.on) {
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%s %b - %s", @"Products in", @"Cart", [self.customer objectForKey:kBillName], nil];
    } else if (currentBulletin) {
        NSArray *currentBulletins;
        if (currentVendor) {
            currentBulletins = [bulletins objectForKey:[NSNumber numberWithInt:currentVendor]];
        } else {
            currentBulletins = Underscore.array([bulletins allValues]).flatten.unwrap;
        }
        NSDictionary *bulletin = Underscore.array(currentBulletins).find(^BOOL(NSDictionary *bulletin) {
            NSNumber *bulletinId = (NSNumber *) [NilUtil nilOrObject:[bulletin objectForKey:kBulletinId]];
            return bulletinId && [bulletinId integerValue] == currentBulletin;
        });
        if (bulletin) {
            NSString *bulletinName = (NSString *) [NilUtil nilOrObject:[bulletin objectForKey:kBulletinName]];
            self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%b %s - %s", bulletinName, @"Products", [self.customer objectForKey:kBillName], nil];
        } else {
            self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%s - %s", @"Products", [self.customer objectForKey:kBillName], nil];
        }
    } else if (currentVendor && vendorsData) {
        NSDictionary *vendorDict = Underscore.array(vendorsData).find(^BOOL(NSDictionary *vendor) {
            NSNumber *vendorId = (NSNumber *) [NilUtil nilOrObject:[vendor objectForKey:kVendorID]];
            return [NilUtil nilOrObject:[vendor objectForKey:kVendorID]] && [vendorId integerValue] == currentVendor;
        });
        NSString *vendorName = (NSString *) [NilUtil nilOrObject:[vendorDict objectForKey:kVendorName]];
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%b %s - %s", vendorName, @"Products", [self.customer objectForKey:kBillName], nil];
    } else {
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%b %s - %s", @"All", @"Products", [self.customer objectForKey:kBillName], nil];
    }
}

- (void)loadBulletins {
    NSArray *coreDataBulletins = [CoreDataManager getBulletins:[CurrentSession instance].managedObjectContext];
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
    NSSet *warnings = self.order ? self.order.warnings : [NSSet new];
    NSSet *errors = self.order ? self.order.errors : [NSSet new];
    if (warnings.count > 0 || errors.count > 0) {
        self.errorMessageTextView.attributedText = [self.order buildMessageSummary];
        self.errorMessageTextView.hidden = NO;
    } else {
        self.errorMessageTextView.text = @"";
        self.errorMessageTextView.hidden = YES;
    }
}

- (void)toggleLineSelection:(LineItem *)lineItem {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.selectedLineItems containsObject:lineItem]) {
            [self.selectedLineItems removeObject:lineItem];
            dispatch_async(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [[NSNotificationCenter defaultCenter] postNotificationName:LineDeselectionNotification object:lineItem];
                }
            });
        } else {
            [self.selectedLineItems addObject:lineItem];
            dispatch_async(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [[NSNotificationCenter defaultCenter] postNotificationName:LineSelectionNotification object:lineItem];
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
                    NSArray *items = Underscore.array([bulletins allValues]).flatten.unwrap;
                    for (NSDictionary *item in items) {
                        if ([item[@"id"] intValue] == currentBulletin) {
                            cell.detailTextLabel.text = item[@"name"];
                            break;
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
        if (self.selectedLineItems.count == 1) {
            [self.selectedLineItems enumerateObjectsUsingBlock:^(LineItem *lineItem, BOOL *stop) {
                [self toggleLineSelection:lineItem]; //disable selection
            }];
            [self.slidingProductViewControllerDelegate toggleShipDates:NO];
        }
    }
}

#pragma mark - Events

- (void)cancel {
    if ([self.order.orderId intValue] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Cancel Order?" message:@"This will cancel the current order." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [alertView show];
    } else if (self.order.hasNontransientChanges) {
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

- (void)loadNotesForm {
    if ([helper isOrderReadyForSubmission:self.order]) {
        if (customerInfoViewController == nil) {
            customerInfoViewController = [[CIFinalCustomerInfoViewController alloc] init];
            customerInfoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            customerInfoViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            customerInfoViewController.delegate = self;
        }
        customerInfoViewController.order = self.order;
        [self presentViewController:customerInfoViewController animated:YES completion:nil];
    }
}

- (BOOL)hasOrderConfirmationFields {
    ShowConfigurations *configurations = [ShowConfigurations instance];
    return configurations.enableOrderNotes ||
            configurations.enableOrderAuthorizedBy ||
            [configurations orderCustomFields].count > 0;
}

- (void)reviewCart {
    if ([helper isOrderReadyForSubmission:self.order]) {
        CICartViewController *cart = [[CICartViewController alloc] initWithOrder:self.order
                                                                        customer:self.customer
                                                                       authToken:[CurrentSession instance].authToken
                                                                selectedVendorId:[NSNumber numberWithInt:currentVendor]
                                                         andManagedObjectContext:[CurrentSession instance].managedObjectContext];
        cart.delegate = self;
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

- (void)reloadTable {
    [self.productTableViewController.tableView reloadData];
}

- (void)updateTotals {
    OrderTotals *totals = [(self.order) calculateTotals];
    NSArray *totalsArray = @[totals.grossTotal, totals.voucherTotal, totals.discountTotal];
    self.totalCost.text = [NumberUtil formatDollarAmount:totalsArray[0]];
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
    if ([helper isOrderReadyForSubmission:self.order]) {
        __weak CIProductViewController *weakSelf = self;
        [OrderCoreDataManager syncOrder:self.order attachHudTo:self.view onSuccess:^(Order *order) {
            weakSelf.order = order;
            [weakSelf reloadTable];
            [weakSelf updateTotals];
            [weakSelf updateErrorsView];
            [weakSelf Return];
        } onFailure:nil];
    }
}

#pragma mark - ProductCellDelegate

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSString *orderShipDatesKeyPath = [NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(order)), NSStringFromSelector(@selector(shipDates))];
    if ([NSStringFromSelector(@selector(order)) isEqualToString:keyPath]) {
        NSError *error = nil;
        if (![[CurrentSession instance].managedObjectContext save:&error]) {
            NSString *msg = [NSString stringWithFormat:@"There was an error saving the product item. %@", error.localizedDescription];
            [[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    } else if (self.order && [orderShipDatesKeyPath isEqualToString:keyPath]) {
        [self.productTableViewController.tableView reloadData];
        [self updateTotals];
    }
}

- (void)onCartQuantityChange:(NSNotification *)notification {
    [self updateTotals];
}

- (void)QtyTouchForIndex:(NSNumber *)productId {
    if ([ShowConfigurations instance].isLineItemShipDatesType) {
        LineItem *lineItem = [self.order findOrCreateLineForProductId:productId
                                                        context:[CurrentSession instance].managedObjectContext];

        if (self.selectedLineItems.count == 1) {
            [self closeCalendar];
        } else {
            [self toggleLineSelection:lineItem];
            self.slidingProductViewControllerDelegate.shipDateController.workingLineItem = lineItem;
            [self.slidingProductViewControllerDelegate toggleShipDates:YES];
        }

        [self.searchText resignFirstResponder];
    }
}

- (Order *)currentOrderForCell {
    return self.order;
}

- (void)ShowPriceChange:(double)price productId:(NSNumber *)productId {
    [self.order updateItemShowPrice:@(price) productId:productId context:[CurrentSession instance].managedObjectContext];
    [self updateTotals];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        [self Return];
    }
}

#pragma CICartViewDelegate

- (void)cartViewDismissedWith:(Order *)order orderCompleted:(BOOL)orderCompleted {
    self.order = order;
    self.orderSubmitted = orderCompleted;
}

#pragma Return
- (void)Return {
    //@todo orders think about what we want to get out of this
    OrderUpdateStatus status = [self orderStatus];
    
    if (PartialOrderCancelled == status || NewOrderCancelled == status) {
        [self.order.managedObjectContext deleteObject:self.order];
        self.order = nil;
    } else {
        [self.order removeZeroQuantityLines];
        [self.order calculateTotals];
        [OrderCoreDataManager saveOrder:self.order inContext:self.order.managedObjectContext];
    }

    [self dismissViewControllerAnimated:YES completion:^{
        if (self.delegate != nil) {
            [self.delegate returnOrder:self.order updateStatus:status];
            [self reinit]; //clear up memory
        }
    }];
}

- (OrderUpdateStatus)orderStatus {
    if (self.newOrder && [self.order.orderId intValue] == 0) {
        return NewOrderCancelled;
    } else if (self.newOrder) {
        return NewOrderCreated;
    } else if (self.order.isPartial && [self.order.orderId intValue] == 0) {
        return PartialOrderCancelled;
    } else if (self.order.isPartial && [self.order.orderId intValue] != 0) {
        return PartialOrderSaved;
    } else if ([self.order.orderId intValue] != 0 && (self.order.hasNontransientChanges || self.orderSubmitted)) {
        return PersistentOrderUpdated;
    } else {
        return PersistentOrderUnchanged;
    }
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
        [self cancel];
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
    [self.productTableViewController filterToVendorId:currentVendor bulletinId:currentBulletin inCart:self.filterCartSwitch.on queryTerm:searchTerm];
}

- (void)updateFilterButtonState {
    ((CIBarButton *) self.filterBarButtonItem.customView).active = (0 != currentBulletin ||
            initialVendor != currentVendor ||
            self.filterCartSwitch.on);
}

@end