//
//  CIProductViewController.m
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <Underscore.m/Underscore.h>
#import "CISlidingProductDetailViewController.h"
#import "CIProductViewController.h"
#import "config.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "Configurations.h"
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
#import "OrderManager.h"
#import "OrderTotals.h"
#import "LineItem+Extensions.h"
#import "CIFinalCustomerFormViewController.h"
#import "CIApplication.h"
#import "CIButton.h"
#import "CISelectPricingTierViewController.h"
#import "CIAlertView.h"
#import "MASConstraintMaker.h"
#import "View+MASAdditions.h"

@interface CIProductViewController () {
    NSInteger initialVendor;
    NSInteger currentVendor; //Logged in vendor's id or the vendor selected in the bulletin drop down
    int currentBulletin; //Bulletin selected in the bulletin drop down
    NSArray *vendorsData; //Vendors belonging to the same vendor group as the logged in vendors. These vendors are displayed in the bulletins drop down.
    NSDictionary *bulletins;
    CIProductViewControllerHelper *helper;
    CIFinalCustomerFormViewController *customerInfoViewController;

}

@property CISlidingProductDetailViewController *slidingProductDetailViewController;
@property CINavViewManager *navViewManager;
@property BOOL isLoadingProducts;

@property (strong, nonatomic) UIBarButtonItem *filterBarButtonItem;
@property (strong, nonatomic) JMStaticContentTableViewController *filterStaticController;
@property (strong, nonatomic) UISwitch *filterCartSwitch;

@property CIButton *changePriceTierButton;
@property CIButton *changeCustomerButton;

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
    // Return: YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)reinit {
    self.delegate = nil;
    self.order = nil;
    self.viewInitialized = NO;
//    initialVendor = ![ShowConfigurations instance].vendorMode &&
//            [CurrentSession instance].vendorId &&
//            ![[CurrentSession instance].vendorId isKindOfClass:[NSNull class]] ?
//            [[CurrentSession instance].vendorId intValue] : 0;
    initialVendor = 0;
    self.orderSubmitted = NO;
    self.selectedLineItems = [NSMutableSet set];
    
    currentVendor = initialVendor;
    currentBulletin = 0;
    if (self.filterCartSwitch) self.filterCartSwitch.on = NO;
    [self updateFilterButtonState];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.slidingProductDetailViewController = [[CISlidingProductDetailViewController alloc] initWithTopViewController:self];

    self.isLoadingProducts = NO;
    self.view.backgroundColor = [UIColor colorWithRed:0.133 green:0.129 blue:0.137 alpha:1];

//    initialVendor = ![ShowConfigurations instance].vendorMode &&
//            [CurrentSession instance].vendorId &&
//            ![[CurrentSession instance].vendorId isKindOfClass:[NSNull class]] ?
//            [[CurrentSession instance].vendorId intValue] : 0;
    initialVendor = 0;
    currentVendor = initialVendor;
    self.tableHeader.hidden = NO;
    self.tableHeaderMinColumnLabel.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    self.tableHeaderPrice1Label.text = [[Configurations instance] price1Label];
    self.tableHeaderPrice2Label.text = [[Configurations instance] price2Label];
    if (![Configurations instance].isOrderShipDatesType) self.btnSelectShipDates.hidden = YES;

    [self initializeOrderActions];
}

- (void)initializeOrderActions {
    self.changeCustomerButton = [[CIButton alloc] initWithOrigin:CGPointMake(8.0F, 5.0F)
                                                            title:@"Change Customer"
                                                             size:CIButtonSizeLarge
                                                            style:CIButtonStyleCancel];
    [self.changeCustomerButton setTitle:@"Change" subtitle:@"Customer"];
    [self.summaryView addSubview:self.changeCustomerButton];
    [self.changeCustomerButton bk_whenTapped:^{
        if (self.order) {
            CISelectCustomerViewController *ci = [[CISelectCustomerViewController alloc] initWithNibName:@"CICustomerInfoViewController" bundle:nil];
            ci.delegate = self;
            [self presentViewController:ci animated:YES completion:nil];
            ci.selectTitle.text = @"Change Customer";
        }
    }];

    if ([Configurations instance].isTieredPricing) {
        self.changePriceTierButton = [[CIButton alloc] initWithOrigin:CGPointZero
                                                                title:@"Select Tier"
                                                                 size:CIButtonSizeLarge
                                                                style:CIButtonStyleCancel];
        [self.summaryView addSubview:self.changePriceTierButton];
        [self.changePriceTierButton bk_whenTapped:^{
            if (self.order) {
                CISelectPricingTierViewController *changeTierVC = [[CISelectPricingTierViewController alloc] init];
                changeTierVC.modalPresentationStyle = UIModalPresentationFormSheet;
                changeTierVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                [changeTierVC prepareForDisplay:self.order];
                [self presentViewController:changeTierVC animated:YES completion:nil];
            }
        }];
        [self.changePriceTierButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.changeCustomerButton.mas_right).offset(8);
            make.bottom.equalTo(self.summaryView).offset(-5);
            make.height.equalTo(@(self.changePriceTierButton.frame.size.height));
            make.width.equalTo(@(self.changePriceTierButton.frame.size.width));
        }];
    }
}

- (void)customerSelected:(NSDictionary *)customer {
    NSString *customerName = customer[kBillName];
    if (customerName) {
        if (customerName.length > 17) {
            customerName = [customerName stringByReplacingCharactersInRange:NSMakeRange(14, customerName.length - 14) withString:@""];
            customerName = [NSString stringWithFormat:@"%@...", customerName];
        }
        [self.changeCustomerButton setTitle:@"Customer" subtitle:customerName];

    } else {
        [self.changeCustomerButton setTitle:@"Change Customer"];

    }
    self.customer = customer;
    self.order.customerId = customer[kID];
    self.order.custId = customer[kCustID];
    self.order.customerName = customer[kBillName];
    [self updateNavigationTitle];
    [CIAlertView alertSaveEvent:[NSString stringWithFormat:@"Customer changed to \n%@", customer[kBillName]]];
}

- (void)updatePriceTierButtonTitle {
    self.changePriceTierButton.title = [[Configurations instance] priceTierLabelAt:self.order.pricingTierIndex.intValue];
}

- (void)productsReloading:(NSNotification *)notification {
    [self.navViewManager clearSearch];
    [self reset];
    self.isLoadingProducts = YES;
}

- (void)productsReloadComplete:(NSNotification *)notification {
    self.isLoadingProducts = NO;
    [self loadProductsForCurrentVendorAndBulletin];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsReloading:) name:ProductsLoadRequestedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsReloadComplete:) name:ProductsLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePriceTierButtonTitle) name:OrderPriceTierChangedNotification object:nil];

    if (!self.viewInitialized) {

        if (self.order == nil) {
            if (self.newOrder) {
                self.order = [Order newOrderForCustomer:self.customer];
            }
            else {
                [self loadOrder:OrderRecoverySelectionNone];
            }
        }
        
        [self.productTableViewController prepareForDisplay:self];
        [self loadVendors];
        [self loadBulletins];
        self.viewInitialized = YES;
    }
    
    [self deserializeOrder];
    [self updatePriceTierButtonTitle];
    
    self.vendorLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:kUsernameSetting];
    [self.vendorTable reloadData];
    [self updateErrorsView];

    if (self.customer[kBillName] != nil) self.customerLabel.text = self.customer[kBillName];

    // notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGrossTotalChangeUpdate:) name:LineQuantityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGrossTotalChangeUpdate:) name:LinePriceChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLineDeselection:) name:LineDeselectionNotification object:nil];

    CINavViewManager *navViewManager = self.navViewManager = [[CINavViewManager alloc] init:YES];
    navViewManager.delegate = self;
    [navViewManager setupNavBar];
    [self updateNavigationTitle];

    [self.productTableViewController viewWillAppear:animated];
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

    [self.productTableViewController viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.productTableViewController viewDidDisappear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.productTableViewController viewWillDisappear:animated];
}

# pragma mark - Initialization

- (void)loadVendors {
    NSArray *vendors = [CoreDataManager getVendors:[CurrentSession mainQueueContext]];
    if (vendors && vendors.count > 0) {//todo use AVendor objects
        NSMutableArray *vendorDataMutable = [[NSMutableArray alloc] init];
        for (Vendor *vendor in vendors) {
            if ([vendor.broker_id isEqualToNumber:@([CurrentSession instance].brokerId.intValue)]) {
                [vendorDataMutable addObject:[vendor asDictionary]];
            }
        }
        [vendorDataMutable insertObject:@{@"name" : @"Any", @"id" : @"0"} atIndex:0];
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
//            [OrderCoreDataManager headOrder:self.order.orderId updatedAt:self.order.updatedAt onSuccess:^{
//
//            }];
        }
    } else if (!self.order) {
        NSLog(@"Invalid state, product view has no order.");
    }
}

- (void)loadProductsForCurrentVendorAndBulletin {
    [self.productTableViewController filterToVendorId:currentVendor bulletinId:currentBulletin inCart:self.filterCartSwitch.on queryTerm:nil summarySearch:NO];
    [self updateNavigationTitle];
}

- (void)deserializeOrder {
    [self reloadTable];
    [self updateTotals];
}

- (void)updateNavigationTitle {
    if (self.filterCartSwitch.on) {
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%s %b - %s", @"Products in", @"Cart", self.customer[kBillName], nil];
    } else if (currentBulletin) {
        NSArray *currentBulletins;
        if (currentVendor) {
            currentBulletins = bulletins[@(currentVendor)];
        } else {
            currentBulletins = Underscore.array([bulletins allValues]).flatten.unwrap;
        }
        NSDictionary *bulletin = Underscore.array(currentBulletins).find(^BOOL(NSDictionary *bulletin_dictionary) {
            NSNumber *bulletinId = (NSNumber *) [NilUtil nilOrObject:bulletin_dictionary[kBulletinId]];
            return bulletinId && [bulletinId integerValue] == currentBulletin;
        });
        if (bulletin) {
            NSString *bulletinName = (NSString *) [NilUtil nilOrObject:bulletin[kBulletinName]];
            self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%b %s - %s", bulletinName, @"Products", self.customer[kBillName], nil];
        } else {
            self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%s - %s", @"Products", self.customer[kBillName], nil];
        }
    } else if (currentVendor && vendorsData) {
        NSDictionary *vendorDict = Underscore.array(vendorsData).find(^BOOL(NSDictionary *vendor) {
            NSNumber *vendorId = (NSNumber *) [NilUtil nilOrObject:vendor[kVendorID]];
            return [NilUtil nilOrObject:vendor[kVendorID]] && [vendorId integerValue] == currentVendor;
        });
        NSString *vendorName = (NSString *) [NilUtil nilOrObject:vendorDict[kVendorName]];
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%b %s - %s", vendorName, @"Products", self.customer[kBillName], nil];
    } else {
        self.navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%b %s - %s", @"All", @"Products", self.customer[kBillName], nil];
    }
}

- (void)loadBulletins {
    NSArray *coreDataBulletins = [CoreDataManager getBulletins:[CurrentSession mainQueueContext]];
    if (coreDataBulletins && coreDataBulletins.count > 0) {//todo use ABulletin objects
        NSMutableDictionary *bulls = [[NSMutableDictionary alloc] init];
        for (Bulletin *bulletin in coreDataBulletins) {
            NSDictionary *dict = [bulletin asDictionary];
            NSNumber *vendid = bulletin.vendor_id;
            if (bulls[vendid] == nil) {
                NSDictionary *any = @{@"name" : @"Any", @"id" : @0};
                NSMutableArray *arr = [[NSMutableArray alloc] init];
                [arr addObject:any];
                bulls[vendid] = arr;
            }
            [bulls[vendid] addObject:dict];
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

-(void)reset {
    [self deselectAllLines];
    [self.view endEditing:YES];
    [self.slidingProductDetailViewController close];
}

-(void)selectLine:(LineItem *)lineItem {
    if (![self.selectedLineItems containsObject:lineItem]) {
        [self.selectedLineItems addObject:lineItem];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            @autoreleasepool {
                [[NSNotificationCenter defaultCenter] postNotificationName:LineSelectionNotification object:lineItem];
//            }
//        });
    }
}

-(void)deselectAllLines {
    [self.selectedLineItems enumerateObjectsUsingBlock:^(LineItem *lineItem, BOOL *stop) {
        [self.selectedLineItems removeObject:lineItem];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            @autoreleasepool {
                [[NSNotificationCenter defaultCenter] postNotificationName:LineDeselectionNotification object:lineItem];
//            }
//        });
    }];
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
    [self toggleFilterView];
}

- (void)setBulletin:(NSInteger)bulletinId {
    currentBulletin = bulletinId;
    [((UINavigationController*)self.poController.contentViewController) popViewControllerAnimated:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.filterStaticController.tableView reloadData];
    });

    [self loadProductsForCurrentVendorAndBulletin];
    [self updateFilterButtonState];
    [self toggleFilterView];
}

- (void)dismissVendorPopover {
}

- (void)filterCartSwitchChanged {
    if (self.filterCartSwitch.on) {
        // Save order to update any changed line items so we can see what's in the cart.
        // The fetched results controller does watch for changes in the same context which aren't
        // saved to the store, but this only applies to the primary entity and not the children.
        // In this case, our fetch is on products, not lineitems.
        [OrderManager saveOrder:self.order inContext:self.order.managedObjectContext];
    }
    [self loadProductsForCurrentVendorAndBulletin];
    [self updateFilterButtonState];
    [self toggleFilterView];
}

/**
* SG: This is the Bulletins drop down.
*/
- (void)toggleFilterView {

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

            if (![Configurations instance].vendorMode) {
                [section addCell:^(JMStaticContentTableViewCell *staticContentCell, UITableViewCell *cell, NSIndexPath *indexPath) {
                    staticContentCell.cellStyle = UITableViewCellStyleValue1;
                    staticContentCell.reuseIdentifier = @"DetailTextCell";

                    cell.textLabel.text = @"Vendor";


                } whenSelected:^(NSIndexPath *indexPath) {
                    VendorViewController *vendorViewController = [[VendorViewController alloc] initWithNibName:@"VendorViewController" bundle:nil];
                    vendorViewController.vendors = [NSArray arrayWithArray:vendorsData];
                    if (bulletins != nil) vendorViewController.bulletins = [NSDictionary dictionaryWithDictionary:bulletins];
                    vendorViewController.delegate = self;

                    [self.filterStaticController.navigationController pushViewController:vendorViewController animated:YES];
                }];
            }

            [section addCell:^(JMStaticContentTableViewCell *staticContentCell, UITableViewCell *cell, NSIndexPath *indexPath) {
                staticContentCell.cellStyle = UITableViewCellStyleValue1;
                staticContentCell.reuseIdentifier = @"DetailTextCell";

                cell.textLabel.text = @"Brand";

            }   whenSelected:^(NSIndexPath *indexPath) {
                BulletinViewController *bulletinViewController = [[BulletinViewController alloc] initWithNibName:@"BulletinViewController" bundle:nil];
                bulletinViewController.bulletins = [NSDictionary dictionaryWithDictionary:bulletins];
                bulletinViewController.currentVendId = currentVendor;
                bulletinViewController.delegate = self;

                [self.filterStaticController.navigationController pushViewController:bulletinViewController animated:YES];
            }];
        }];

        NSIndexPath *vendorCellPath = [NSIndexPath indexPathForRow:1 inSection:0];
        NSIndexPath *bulletinCellPath = [NSIndexPath indexPathForRow:2 inSection:0];
        if ([Configurations instance].vendorMode) bulletinCellPath = vendorCellPath;

        [self.filterStaticController aspect_hookSelector:@selector(viewWillAppear:) withOptions:AspectPositionAfter usingBlock:^(id instance, NSArray *args) {
            self.filterStaticController.tableView.separatorColor = [UIColor colorWithRed:0.839 green:0.839 blue:0.851 alpha:1];
            self.filterStaticController.navigationController.navigationBarHidden = YES;

            UITableViewCell *cell = [self.filterStaticController.tableView cellForRowAtIndexPath:vendorCellPath];

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

            cell = [self.filterStaticController.tableView cellForRowAtIndexPath:bulletinCellPath];
            
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
            
        }                                          error:nil];

        [self.filterStaticController aspect_hookSelector:@selector(viewWillDisappear:) withOptions:AspectPositionAfter usingBlock:^(id instance, NSArray *args) {

        }                                          error:nil];


        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.filterStaticController];
        nav.navigationBarHidden = NO;
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
        nav.navigationItem.backBarButtonItem = backButton;

        self.poController = [[UIPopoverController alloc] initWithContentViewController:nav];
        [self.poController setPopoverContentSize:CGSizeMake(320, 480) animated:YES];
    }

    if (self.poController.isPopoverVisible) {
        [self.poController dismissPopoverAnimated:NO];
    } else {
        [self.poController presentPopoverFromBarButtonItem:self.filterBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
    }
}

#pragma mark - Events

- (void)cancel {
    if (self.isLoadingProducts) {
        [[[UIAlertView alloc] initWithTitle:@"Products Reloading" message:@"Products are currently being reloaded from the server in the background. Product searches cannot be conducted until complete." delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }

    if (self.order.hasNontransientChanges || !self.order.inSync) {
        NSMutableArray *options = [NSMutableArray array];
        NSString *title;
        if (self.order.hasNontransientChanges) {
            title = @"Unsaved Changes";
        } else {
            title = @"Unsynced Changes";
        }
        
        [options addObject:@"Continue Working"];
        
        if (!self.order.updatedAt) {
            // if this is blank, the order has never been saved
            [options addObject:@"Delete Order"];
        } else {
            [options addObject:@"Save Locally & Resume Later"]; //would prefer this elsewhere but not working otherwise
            [options addObject:@"Undo Changes Since Last Sync"];
        }
        
        __weak CIProductViewController *weakSelf = self;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:@"You have unsaved or unsynced changes to this order. How would you like to proceed?"
                                                       delegate:self
                                              cancelButtonTitle:options.firstObject
                                              otherButtonTitles:nil];
        for (NSString *option in [options subarrayWithRange:NSMakeRange(1, options.count - 1)]) {
            [alert addButtonWithTitle:option];
        }
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
            NSString *action = [alert buttonTitleAtIndex:buttonIndex];
            if ([action isEqualToString:@"Delete Order"]) {
                [OrderManager deleteOrder:weakSelf.order onSuccess:^{
                    [self Return:NO];
                }               onFailure:^{
                    // do nothing
                }];
            } else if ([action isEqualToString:@"Undo Changes Since Last Sync"]) {
                [OrderManager fetchOrder:weakSelf.order.orderId attachHudTo:weakSelf.view onSuccess:^(Order *order) {
                    weakSelf.order = order;
                    [weakSelf Return:NO];
                }              onFailure:^{
                    // do nothing
                }];
            } else if ([action isEqualToString:@"Save Locally & Resume Later"]) {
                [[CurrentSession mainQueueContext] performBlock:^{
                    if (weakSelf.order.isComplete) weakSelf.order.status = @"pending";
                    [OrderManager saveOrder:weakSelf.order inContext:[CurrentSession mainQueueContext]];
                    [weakSelf Return:NO];
                }];
            } else if ([action isEqualToString:@"Submit This Order Now"]) {
                [weakSelf reviewCart];
            } else if ([action isEqualToString:@"Continue Working"]) {
                // do nothing
            } else {
                [weakSelf Return:NO];
            }
        }];
    } else {
        [self Return:YES];
    }
}

- (void)loadNotesForm {
    if ([helper isOrderReadyForSubmission:self.order]) {
        if (customerInfoViewController == nil) {
            customerInfoViewController = [[CIFinalCustomerFormViewController alloc] init];
            customerInfoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            customerInfoViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            customerInfoViewController.delegate = self;
        }
        customerInfoViewController.order = self.order;
        [self presentViewController:customerInfoViewController animated:YES completion:nil];
    }
}

- (BOOL)hasOrderConfirmationFields {
    Configurations *configurations = [Configurations instance];
    return configurations.enableOrderNotes ||
            configurations.enableOrderAuthorizedBy ||
            [configurations orderCustomFields].count > 0;
}

- (void)reviewCart {
    if (self.isLoadingProducts) {
        [[[UIAlertView alloc] initWithTitle:@"Products Reloading" message:@"Products are currently being reloaded from the server in the background. Product searches cannot be conducted until complete." delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }

    if ([helper isOrderReadyForSubmission:self.order]) {

        [self reset];

        if (self.poController && self.poController.isPopoverVisible) {
            [self.poController dismissPopoverAnimated:NO];
        }
        
        CICartViewController *cart = [[CICartViewController alloc] initWithOrder:self.order
                                                                        customer:self.customer
                                                                       authToken:[CurrentSession instance].authToken
                                                                selectedVendorId:@(currentVendor)
                                                         andManagedObjectContext:[CurrentSession mainQueueContext]];
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
    if (self.order) {
        OrderTotals *totals = [self.order calculateTotals];
        self.totalCost.text = [NumberUtil formatDollarAmount:totals.grossTotal];
    }
}

#pragma mark - Keyboard

- (void)keyPressed:(KeyPressType)keyPressType withValue:(NSString *)value {
    NSLog(@"key pressed: %@", value);
    if (!self.navViewManager.inSearchMode) {
//        [self.navViewManager clearSearch];
//        [self.navViewManager enterSearchMode];
    }
}

#pragma mark - CIFinalCustomerDelegate

- (void)dismissFinalCustomerViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSDictionary *)getCustomerInfo {
    return [self.customer copy];
}

//Called from the authorization, notes etc. popup
- (IBAction)submit:(NSString *)sendEmailTo {
    if ([helper isOrderReadyForSubmission:self.order]) {
        __weak CIProductViewController *weakSelf = self;
        [OrderManager syncOrderDetails:self.order sendEmailTo:sendEmailTo attachHudTo:self.view onSuccess:^{
            [weakSelf reloadTable];
            [weakSelf updateErrorsView];
            [weakSelf Return:NO];
        } onFailure:nil];
    }
}

#pragma mark - ProductCellDelegate

- (void)onGrossTotalChangeUpdate:(NSNotification *)notification {
    LineItem *lineItem = notification.object;
    if (lineItem && lineItem.order && self.order && [self.order.objectID isEqual:lineItem.order.objectID]) {

        __weak CIProductViewController *weakSelf = self;

        NSString *previousTotalCostValue = self.totalCost.text; // in case error

        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf) {
                if (weakSelf) weakSelf.totalCost.text = @"Recalculating...";
            }
        });

        void (^error)() = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (weakSelf) {
                    weakSelf.totalCost.text = previousTotalCostValue;
                }
            });
        };

        double newLineSubtotal = lineItem.subtotal;

        [[CurrentSession privateQueueContext] performBlock:^{
            if (weakSelf && weakSelf.order) {
                Order *asyncOrder = (Order *) [[CurrentSession privateQueueContext] existingObjectWithID:weakSelf.order.objectID error:nil];
                LineItem *asyncLine = (LineItem *) [[CurrentSession privateQueueContext] existingObjectWithID:lineItem.objectID error:nil];
                
                if (asyncOrder && asyncLine) {
                    asyncOrder.grossTotal = nil;
                    OrderTotals *totals = [asyncOrder calculateTotals];
                    double oldLineSubtotal = asyncLine.subtotal;
                    double newTotal = totals.grossTotal.doubleValue + newLineSubtotal - oldLineSubtotal;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakSelf) {
                            weakSelf.totalCost.text = [NumberUtil formatDollarAmount:@(newTotal)];
                        } else {
                            error();
                        }
                    });
                } else {
                    error();
                    
                }
            } else {
                error();
            }
        }];
    }
}

- (void)onLineDeselection:(NSNotification *)notification {
    if (self.order) {
        NSLog(@"Triggering Autosave...");
        [OrderManager saveOrder:self.order async:NO beforeSave:nil onSuccess:nil];
    }
}

- (void)toggleProductDetail:(NSNumber *)productId lineItem:(LineItem *)lineItem {
    if (self.isLoadingProducts) {
        [[[UIAlertView alloc] initWithTitle:@"Products Reloading" message:@"Products are currently being reloaded from the server in the background. Product searches cannot be conducted until complete." delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        return;
    }

    if (!lineItem) {
        lineItem = [self.order createLineForProductId:productId context:self.order.managedObjectContext];
        [OrderManager saveOrder:self.order inContext:self.order.managedObjectContext];
    }

    if (self.selectedLineItems.count == 1) {
        [self deselectAllLines];
        [self.slidingProductDetailViewController close];
    } else {
        [self selectLine:lineItem];
    }

    [self.slidingProductDetailViewController open:self.order lineItem:lineItem];
    [self.searchText resignFirstResponder];
}

- (Order *)currentOrderForCell {
    return self.order;
}

- (BOOL)isLineSelected:(LineItem *)lineItem {
    return [self.selectedLineItems containsObject:lineItem];
}

- (void)setEditingMode:(BOOL)isEditing {
//    self.productTableViewController.isEditingQuantity = isEditing;
    [self.productTableViewController.tableView setEditing:isEditing animated:NO];
}


- (void)showPriceChanged:(double)price productId:(NSNumber *)productId lineItem:(LineItem *)lineItem {
//    if (!lineItem) {
//        lineItem = [self.order createLineForProductId:productId context:[CurrentSession mainQueueContext]];
//    }
//    lineItem.price = @(price);
//    [self updateTotals];
    //deprecated
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"]) {
        [self Return:NO];
    }
}

#pragma CICartViewDelegate

- (void)cartViewDismissedWith:(Order *)order orderCompleted:(BOOL)orderCompleted {
    self.order = order;
    self.orderSubmitted = orderCompleted;
}

#pragma Return:

- (void)Return:(BOOL)isCancel {

    [self reset];

    if (self.poController && self.poController.isPopoverVisible) {
        [self.poController dismissPopoverAnimated:NO];
    }
    
    //@todo orders think about what we want to get out of this
    OrderUpdateStatus status = [self orderStatus];
    BOOL inSync = self.order.inSync;
    NSString *orderStatus = self.order.status;
    if (PartialOrderCancelled == status || NewOrderCancelled == status) {
        if (self.order) [self.order.managedObjectContext deleteObject:self.order];
        self.order = nil;
    } else {
        [self.order removeZeroQuantityLines];
        [self.order calculateTotals];
        [OrderManager saveOrder:self.order inContext:self.order.managedObjectContext];
    }

    NSManagedObjectID *orderObjectID = self.order ? self.order.objectID : nil;
    __weak CIProductViewController *weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.delegate) {
            if (isCancel || PartialOrderCancelled == status || NewOrderCancelled == status) {
//                [CIAlertView alertWarningEvent:@"Order Cancelled"];
            } else {
                if (inSync && [orderStatus isEqualToString:@"complete"]) {
                    [CIAlertView alertSyncEvent:weakSelf.newOrder ? @"Order Created and Synced" : @"Order Updated and Synced"];
                } else {
                    [CIAlertView alertSaveEvent:weakSelf.newOrder ? @"Pending, Unsynced Order Created" : @"Pending, Unsynced Order Updated"];
                }
            }

            [weakSelf.delegate returnOrder:orderObjectID updateStatus:status];
            [weakSelf reinit]; //clear up memory
        }
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:ProductSelectionCompleteNotification object:nil];
}

- (OrderUpdateStatus)orderStatus {
    if (!self.order || (self.newOrder && [self.order.orderId intValue] == 0)) {
        return NewOrderCancelled;
    } else if (self.newOrder) {
        return NewOrderCreated;
    } else if (self.order.isFault || (self.order.isPartial && [self.order.orderId intValue] == 0)) {
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
    return self.navigationItem;
}

- (NSArray *)leftActionItems {
    UIBarButtonItem *cancelItem = [CIBarButton buttonItemWithText:@"\uf053" style:CIBarButtonStyleTextButton orientation:CIBarButtonOrientationLeft handler:^(id sender) {
        [self cancel];
    }];
    return @[cancelItem];
}

- (NSArray *)rightActionItems {
    if (!self.filterBarButtonItem) {
        CIBarButton *filterBarButton = [[CIBarButton alloc] initWithText:@"" style:CIBarButtonStyleRoundButton orientation:(CIBarButtonOrientationRight) handler:^(id sender) {
            [self toggleFilterView];
        }];
        NSDictionary *labelAttributes = [ThemeUtil navigationRightActionButtonTextAttributes];
        filterBarButton.label.attributedText = [[NSAttributedString alloc] initWithString:@"\ue140" attributes:Underscore.extend(labelAttributes, @{
            NSFontAttributeName: [UIFont iconAltFontOfSize:14],
        })];
        [filterBarButton setBackgroundColor:[ThemeUtil offWhiteColor] borderColor:[ThemeUtil offWhiteBorderColor] textColor:[ThemeUtil offBlackColor] forControlState:UIControlStateNormal];
        [filterBarButton setBackgroundColor:[ThemeUtil lightBlueColor] borderColor:[ThemeUtil lightBlueBorderColor] textColor:nil forControlState:UIControlStateHighlighted];

        self.filterBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:filterBarButton];
    }

    UIBarButtonItem *addItem = [CIBarButton buttonItemWithText:@"\uf07a" style:CIBarButtonStyleRoundButton orientation:(CIBarButtonOrientationRight) handler:^(id sender) {
        [self.productTableViewController.tableView endEditing:YES];
        [self reviewCart];
    }];
    return @[addItem, self.filterBarButtonItem];
}

- (void)navViewDidSearch:(NSString *)searchTerm inputCompleted:(BOOL)inputCompleted {
    if (!self.isLoadingProducts) {
        [self.productTableViewController filterToVendorId:currentVendor bulletinId:currentBulletin inCart:self.filterCartSwitch.on queryTerm:searchTerm summarySearch:!inputCompleted];
    }
}

- (BOOL)navViewWillSearch {
    if (self.isLoadingProducts) {
        [[[UIAlertView alloc] initWithTitle:@"Products Reloading" message:@"Products are currently being reloaded from the server in the background. Product searches cannot be conducted until complete." delegate:nil
                          cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else {
        if (self.poController && self.poController.isPopoverVisible) {
            [self.poController dismissPopoverAnimated:NO];
        }
    }
    return !self.isLoadingProducts;
}

- (void)updateFilterButtonState {
    ((CIBarButton *) self.filterBarButtonItem.customView).active = (0 != currentBulletin ||
            initialVendor != currentVendor ||
            self.filterCartSwitch.on);
}

@end