//  CICartViewController.m
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import <JSONKit/JSONKit.h>
#import "Order.h"
#import "CICartViewController.h"
#import "config.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "ShowConfigurations.h"
#import "CIProductViewControllerHelper.h"
#import "NumberUtil.h"
#import "FarrisCartViewCell.h"
#import "SettingsManager.h"
#import "Cart.h"
#import "Order+Extensions.h"
#import "CoreDataUtil.h"
#import "Product+Extensions.h"
#import "DiscountLineItem.h"
#import "ALineItem.h"


@interface CICartViewController ()
@property(strong, nonatomic) Order *coreDataOrder;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSNumber *selectedVendorId;
@property(strong, nonatomic) NSString *loggedInVendorId;
@property(strong, nonatomic) NSString *loggedInVendorGroupId;
@property(strong, nonatomic) AnOrder *savedOrder;
@property(nonatomic) BOOL unsavedChangesPresent;
@property(nonatomic, strong) NSArray *productsInCart;
@property(nonatomic, strong) NSArray *discountsInCart;
@property(nonatomic) BOOL initialized;

@property (strong, nonatomic) IBOutlet UIView *totalsView;
@property (strong, nonatomic) IBOutlet UILabel *totalsLabel;

@property (strong, nonatomic) AnOrder *workingOrder;
@property (assign) float totalGross;
@property (assign) float totalDiscounts;
@property (assign) float totalFinal;
@end

@implementation CICartViewController {
    __weak IBOutlet UILabel *customerInfoLabel;
    __weak IBOutlet UIImageView *logo;
    NSIndexPath *selectedItemRowIndexPath;
    CIProductViewControllerHelper *helper;
    BOOL keyboardUp;
    float keyboardHeight;
}
@synthesize productsUITableView;
@synthesize authToken;
@synthesize navBar;
@synthesize title;
@synthesize showPrice;
@synthesize indicator;
@synthesize customer;
@synthesize delegate;
@synthesize tOffset;
@synthesize finishTheOrder;
@synthesize multiStore;
@synthesize popoverController;
@synthesize storeQtysPO;
@synthesize lblShipDate1, lblShipDate2, lblShipDateCount;
@synthesize tableHeaderPigglyWiggly, tableHeaderFarris;

- (id)initWithOrder:(Order *)coreDataOrder customer:(NSDictionary *)customerDictionary authToken:(NSString *)token selectedVendorId:(NSNumber *)selectedVendorId loggedInVendorId:(NSString *)loggedInVendorId loggedInVendorGroupId:(NSString *)loggedInVendorGroupId andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    self = [super initWithNibName:@"CICartViewController" bundle:nil];
    if (self) {
        showPrice = YES;
        tOffset = 0;
        helper = [[CIProductViewControllerHelper alloc] init];
        self.coreDataOrder = coreDataOrder;
        self.productsInCart = [[NSArray alloc] init];
        self.discountsInCart = [[NSArray alloc] init];
        self.managedObjectContext = managedObjectContext;
        self.customer = customerDictionary;
        self.authToken = token;
        self.selectedVendorId = selectedVendorId;
        self.loggedInVendorId = loggedInVendorId;
        self.loggedInVendorGroupId = loggedInVendorGroupId;
        keyboardUp = NO;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.indicator startAnimating];
    navBar.topItem.title = self.title;
    self.showShipDates = [[ShowConfigurations instance] shipDates];
    self.allowPrinting = [ShowConfigurations instance].printing;
    self.allowSignature = [ShowConfigurations instance].captureSignature;
    self.multiStore = [[self.customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [self.customer objectForKey:kStores]) count] > 0;
    logo.image = [ShowConfigurations instance].logo;
    self.discountTotal.hidden = self.discountTotalLabel.hidden = ![ShowConfigurations instance].discounts;
    self.netTotal.hidden = self.netTotalLabel.hidden = ![ShowConfigurations instance].discounts;
    self.voucherTotal.hidden = self.voucherTotalLabel.hidden = ![ShowConfigurations instance].vouchers;
    self.grossTotalLabel.text = [ShowConfigurations instance].discounts ? @"Gross Total" : @"Total";
    if ([kShowCorp isEqualToString:kPigglyWiggly]) {
        tableHeaderPigglyWiggly.hidden = NO;
        tableHeaderFarris.hidden = YES;
    } else {
        tableHeaderPigglyWiggly.hidden = YES;
        tableHeaderFarris.hidden = NO;
        self.zeroVouchers.hidden = YES;
        self.tableHeaderMinColumn.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    }
    customerInfoLabel.text = customer != nil &&
            customer[kBillName] != nil &&
            ![customer[kBillName] isKindOfClass:[NSNull class]] ? customer[kBillName] : @"";
    self.vendorLabel.text = [helper displayNameForVendor:self.selectedVendorId];
    self.unsavedChangesPresent = NO;

    self.productsUITableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewWillAppear:(BOOL)animated {
    [self refreshView];
    [self.indicator stopAnimating];
    self.indicator.hidden = YES;
    if (keyboardUp) {
        //if the frame size was decreased to accomodate the keyboard right before cart was launched,
        //when the view reappears, the keyboard would have been hidden (without keyboard hide notification being sent out it seems)
        //so it is important to undo the frame resize at this point.
        [self keyboardDidHide];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification object:nil];

    [self setupNavBar];
}

- (void)setupNavBar {
    UINavigationController *navController = self.navigationController;
    UINavigationItem *navItem = self.navigationItem;

    navController.navigationBar.barTintColor = [UIColor colorWithRed:0.235 green:0.247 blue:0.251 alpha:1];

    if ([self.customer objectForKey:kBillName] != nil) {
//        navItem.title = [self.customer objectForKey:kBillName];
        navItem.title = [NSString stringWithFormat:@"Products in Cart - %@", [self.customer objectForKey:kCustID]];
    }

    [navController.navigationBar setTitleTextAttributes:@{ NSFontAttributeName: [UIFont regularFontOfSize:24],
                                                           NSForegroundColorAttributeName: [UIColor whiteColor] }];

    UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] bk_initWithTitle:@"\uf00d" style:UIBarButtonItemStylePlain handler:^(id sender) {
        [self Cancel:nil];
    }];
    [menuItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont iconFontOfSize:20],
                                        NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateNormal];

    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] bk_initWithImage:[[UIImage imageNamed:@"ico-bar-done"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain handler:^(id sender) {
        [self finishOrder:nil];
    }];
    [addItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont iconFontOfSize:20],
                                       NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateNormal];

    navItem.leftBarButtonItems = @[menuItem];
    navItem.rightBarButtonItems = @[addItem];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.initialized) {
        [self saveOrderOnFirstLoad];
    }
}

- (void)saveOrderOnFirstLoad {
    if ([helper isOrderReadyForSubmission:self.coreDataOrder]) {
        self.coreDataOrder.status = @"pending";
        [[CoreDataUtil sharedManager] saveObjects];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:[self.coreDataOrder asJSONReqParameter]];
        parameters[kAuthToken] = self.authToken;
        NSString *method = [self.coreDataOrder.orderId intValue] > 0 ? @"PUT" : @"POST";
        NSString *url = [self.coreDataOrder.orderId intValue] == 0 ? kDBORDER : kDBORDEREDITS([self.coreDataOrder.orderId intValue]);
        void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, id json) {
            self.savedOrder = [self loadJson:json];
            self.unsavedChangesPresent = NO;
        };
        void(^failureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id json) {
            if (json) {
                [self loadJson:json];
            }
        };
        [helper sendRequest:method url:url parameters:parameters successBlock:successBlock failureBlock:failureBlock view:self.view loadingText:@"Saving order"];
    }
    self.initialized = YES;
}

- (AnOrder *)loadJson:(id)json {
    AnOrder *anOrder = [[AnOrder alloc] initWithJSONFromServer:(NSDictionary *) json];
    self.workingOrder = anOrder;
    [self.managedObjectContext deleteObject:self.coreDataOrder];//delete existing core data representation
    self.coreDataOrder = [helper createCoreDataCopyOfOrder:anOrder customer:self.customer loggedInVendorId:self.loggedInVendorId loggedInVendorGroupId:self.loggedInVendorGroupId managedObjectContext:self.managedObjectContext];//create fresh new core data representation
    [[CoreDataUtil sharedManager] saveObjects];
    [self refreshView];
    return anOrder;
}

- (void)refreshView {
    self.productsInCart = [helper sortProductsByinvtId:[self.coreDataOrder productIds]];
    self.discountsInCart = [helper sortDiscountsByLineItemId:[self.coreDataOrder discountLineItemIds]];
    [self reloadTable];
    [self updateTotals];
}

- (void)reloadTable {
    [self.productsUITableView reloadData];
    if (keyboardUp) {
        [self addInsetToTable:keyboardHeight - 95];//width because landscape. 69 is height of the view that contains totals at the end of the table.
    }
}

- (void)updateTotals {
    NSArray *totals = [helper getTotals:self.coreDataOrder];
    self.grossTotal.text = [NumberUtil formatDollarAmount:totals[0]];
    self.discountTotal.text = [NumberUtil formatDollarAmount:totals[2]];
    double netTotal = [(NSNumber *) totals[0] doubleValue] + [(NSNumber *) totals[2] doubleValue];
    self.netTotal.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:netTotal]];
    self.voucherTotal.text = [NumberUtil formatDollarAmount:totals[1]];

    self.totalGross = [totals[0] floatValue];
    self.totalDiscounts = fabs([totals[2] floatValue]);
    self.totalFinal = netTotal;

    CoreDataUtil *coreDataUtil = [CoreDataUtil sharedManager];
    NSMutableDictionary *dateProducts = [NSMutableDictionary dictionary];
    NSMutableArray *orderedDates = [NSMutableArray array];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];

    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.000Z'"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSDate *earliestDate = nil;

    for (ALineItem *line in self.workingOrder.lineItems) {
        Product *product = (Product *) [coreDataUtil fetchObject:@"Product" withPredicate:[NSPredicate predicateWithFormat:@"(productId == %@)", line.productId]];

        NSDictionary *quantities = [NSJSONSerialization JSONObjectWithData:[line.quantity dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if ([quantities isKindOfClass:[NSDictionary class]]) {
            for (NSString *d in quantities.allKeys) {
                NSDate *date = [dateFormatter dateFromString:d];
                int quantity = [quantities[d] intValue];

                if (earliestDate == nil) {
                    earliestDate = date;
                } else {
                    earliestDate = [earliestDate earlierDate:date];
                }

                if(quantity) {
                    NSMutableArray *products = [dateProducts objectForKey:date];
                    if (!products) {
                        products = [NSMutableArray array];
                        dateProducts[date] = products;
                        [orderedDates addObject:date];
                    }
                    [products addObject:@[product, @(quantity)]];
                }
            }
        }
    }

    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentRight;
    paragraph.lineSpacing = 5;
    paragraph.tabStops = @[[[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentRight
                                                           location:self.totalsLabel.bounds.size.width - 700
                                                            options:nil],
                           [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentRight
                                                           location:self.totalsLabel.bounds.size.width - 200
                                                            options:nil]];

    NSMutableAttributedString *attributedString = [NSMutableAttributedString new];

    [orderedDates sortUsingSelector:@selector(compare:)];
    for (int i = 0; i < orderedDates.count; i++) {
        NSDate *date = (NSDate*)[orderedDates objectAtIndex:i];

        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Shipping on %@\t", [dateFormatter stringFromDate:date]]
                                                                                 attributes:@{ NSParagraphStyleAttributeName: paragraph, NSFontAttributeName : [UIFont regularFontOfSize:13], NSForegroundColorAttributeName: [UIColor colorWithRed:0.165 green:0.176 blue:0.180 alpha:1] }]];

        float total = 0;
        for (NSArray *pair in dateProducts[date]) {
            Product *product = pair[0];
            int quantity = [pair[1] intValue];

            if (date == earliestDate) {
                total += quantity * [product.showprc intValue];
            } else {
                total += quantity * [product.regprc intValue];
            }
        }

        NSString *priceString = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:total / 100.0] numberStyle:NSNumberFormatterCurrencyStyle];

        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:priceString
                                                                                 attributes:@{ NSParagraphStyleAttributeName: paragraph, NSFontAttributeName : [UIFont regularFontOfSize:15], NSForegroundColorAttributeName: [UIColor colorWithRed:0.165 green:0.176 blue:0.180 alpha:1] }]];
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];
    }

    NSString *s = nil;
    s = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:self.totalGross] numberStyle:NSNumberFormatterCurrencyStyle];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"SUBTOTAL\t%@", s]
                                                                             attributes:@{ NSParagraphStyleAttributeName: paragraph, NSFontAttributeName : [UIFont regularFontOfSize:16], NSForegroundColorAttributeName: [UIColor colorWithRed:0.165 green:0.176 blue:0.180 alpha:1] }]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];

    s = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:fabsf(self.totalDiscounts)] numberStyle:NSNumberFormatterCurrencyStyle];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"DISCOUNT\t%@", s]
                                                                             attributes:@{ NSParagraphStyleAttributeName: paragraph, NSFontAttributeName : [UIFont regularFontOfSize:16], NSForegroundColorAttributeName: [UIColor colorWithRed:0.165 green:0.176 blue:0.180 alpha:1] }]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];

    s = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:self.totalGross] numberStyle:NSNumberFormatterCurrencyStyle];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"TOTAL\t"]
                                                                             attributes:@{ NSParagraphStyleAttributeName: paragraph, NSFontAttributeName : [UIFont regularFontOfSize:18], NSForegroundColorAttributeName: [UIColor colorWithRed:0.165 green:0.176 blue:0.180 alpha:1] }]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", s]
                                                                             attributes:@{ NSParagraphStyleAttributeName: paragraph, NSFontAttributeName : [UIFont semiboldFontOfSize:18], NSForegroundColorAttributeName: [UIColor colorWithRed:0.165 green:0.176 blue:0.180 alpha:1] }]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];

    self.totalsLabel.attributedText = attributedString;
    self.totalsLabel.textAlignment = NSTextAlignmentRight;
    [self.totalsLabel sizeToFit];
    self.totalsView.frame = CGRectMake(0, self.view.frame.size.height - self.totalsLabel.frame.size.height + 5, self.view.frame.size.width, self.totalsLabel.frame.size.height - 5);
    self.totalsLabel.frame = CGRectMake(0, 0, self.totalsView.bounds.size.width - 10, self.totalsView.bounds.size.height);

    self.productsUITableView.frame = CGRectMake(0, 85, 1024, 683 - self.totalsView.frame.size.height);
}

- (void)dismissSelf {
    [self.indicator startAnimating];
    [self.delegate cartViewDismissedWith:self.coreDataOrder savedOrder:self.savedOrder unsavedChangesPresent:self.unsavedChangesPresent orderCompleted:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Table stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.productsInCart.count : self.discountsInCart.count;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) { //product items
        NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
        Cart *cart = [self.coreDataOrder findCartForProductId:productId];
        FarrisCartViewCell *cell = (FarrisCartViewCell *) [helper dequeueReusableCartViewCell:myTableView];
        [cell initializeWithCart:cart tag:[indexPath row] ProductCellDelegate:self];
        return cell;
    } else { //discount items
        NSNumber *lineItemId = self.discountsInCart[(NSUInteger) [indexPath row]];
        DiscountLineItem *discountLineItem = [self.coreDataOrder findDiscountForLineItemId:lineItemId];
        FarrisCartViewCell *cell = (FarrisCartViewCell *) [helper dequeueReusableCartViewCell:myTableView];
        [cell initializeWithDiscount:discountLineItem tag:[indexPath row] ProductCellDelegate:self];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
        Cart *cart = [self.coreDataOrder findCartForProductId:productId];
        if (cart.warnings.count > 0 || cart.errors.count > 0)
            return 44 + ((cart.warnings.count + cart.errors.count) * 42);
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
        Cart *cart = [self.coreDataOrder findCartForProductId:productId];
        [helper updateCellBackground:cell order:self.coreDataOrder cart:cart];
    }

    if(indexPath.row % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1];
    }
}

#pragma mark - Other

- (IBAction)Cancel:(id)sender {
    self.indicator.hidden = NO;
    [self.indicator startAnimating];
    [self.delegate cartViewDismissedWith:self.coreDataOrder savedOrder:self.savedOrder unsavedChangesPresent:self.unsavedChangesPresent orderCompleted:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)finishOrder:(id)sender {
    if ([helper isOrderReadyForSubmission:self.coreDataOrder]) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:[self.coreDataOrder asJSONReqParameter]];
        parameters[kAuthToken] = self.authToken;
        NSString *method = [self.coreDataOrder.orderId intValue] > 0 ? @"PUT" : @"POST";
        NSString *url = [self.coreDataOrder.orderId intValue] == 0 ? kDBORDER : kDBORDEREDITS([self.coreDataOrder.orderId intValue]);
        void (^successBlock)(NSURLRequest *, NSHTTPURLResponse *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, id JSON) {
            [self.managedObjectContext deleteObject:self.coreDataOrder];//delete existing core data representation
            [[CoreDataUtil sharedManager] saveObjects];
            self.savedOrder = [[AnOrder alloc] initWithJSONFromServer:JSON];
            self.coreDataOrder = [helper createCoreDataCopyOfOrder:self.savedOrder customer:self.customer loggedInVendorId:self.loggedInVendorId loggedInVendorGroupId:self.loggedInVendorGroupId managedObjectContext:self.managedObjectContext];
            self.indicator.hidden = NO;
            self.unsavedChangesPresent = NO;
            if (self.allowSignature) {
                [self displaySignatureScreen];
            } else {
                [self dismissSelf];
            }
        };
        void (^failureBlock)(NSURLRequest *, NSHTTPURLResponse *, NSError *, id) = ^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error, id json) {
            if (json) {
                [self loadJson:json];
            }
        };
        [helper sendRequest:method url:url parameters:parameters successBlock:successBlock failureBlock:failureBlock view:self.view loadingText:@"Submitting order"];
    }
}

- (IBAction)clearVouchers:(id)sender {
    if ([helper isOrderReadyForSubmission:self.coreDataOrder]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Zero out all vouchers?" delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                for (int i = 0; i <= self.productsInCart.count; i++) {
                    NSNumber *productId = self.productsInCart[(NSUInteger) i];
                    [self.coreDataOrder updateItemVoucher:@(0) productId:productId context:self.managedObjectContext];
                    self.unsavedChangesPresent = YES;
                }
                [self reloadTable];
            }
        }];
    }
}

- (IBAction)handleTap:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (![kShowCorp isEqualToString:kPigglyWiggly]) {
            for (FarrisCartViewCell *cell in self.productsUITableView.visibleCells) {
                if ([cell.quantity isFirstResponder]) {
                    [cell.quantity resignFirstResponder];//so the keyboard will hide
                    break;
                }
            }
        }
    }
}

- (void)VoucherChange:(double)voucherPrice forIndex:(int)idx {
    NSNumber *productId = self.productsInCart[(NSUInteger) idx];
    [self.coreDataOrder updateItemVoucher:@(voucherPrice) productId:productId context:self.managedObjectContext];
    self.unsavedChangesPresent = YES;
}

- (void)ShowPriceChange:(double)price forIndex:(int)idx {
    NSNumber *productId = self.productsInCart[(NSUInteger) idx];
    [self.coreDataOrder updateItemShowPrice:@(price) productId:productId context:self.managedObjectContext];
    self.unsavedChangesPresent = YES;
}

- (void)QtyChange:(int)qty forIndex:(int)idx {
    NSNumber *productId = self.productsInCart[(NSUInteger) idx];
    [self.coreDataOrder updateItemQuantity:[NSString stringWithFormat:@"%i", qty] productId:productId context:self.managedObjectContext];
    self.unsavedChangesPresent = YES;
    Cart *cart = [self.coreDataOrder findCartForProductId:productId];
    ProductCell *cell = (ProductCell *) [self.productsUITableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(NSUInteger) idx inSection:0]];
    [helper updateCellBackground:cell order:self.coreDataOrder cart:cart];
}

- (void)QtyTouchForIndex:(int)idx {
    if ([popoverController isPopoverVisible]) {
        [popoverController dismissPopoverAnimated:YES];
    } else {
        if (!storeQtysPO) {
            storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }
        NSNumber *productId = self.productsInCart[(NSUInteger) idx];
        Cart *cart = [self.coreDataOrder findCartForProductId:productId];
        storeQtysPO.stores = [[cart.editableQty objectFromJSONString] mutableCopy];
        storeQtysPO.tag = idx;
        storeQtysPO.editable = NO;
        storeQtysPO.delegate = (id <CIStoreQtyTableDelegate>) self;
        CGRect frame = [self.productsUITableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0]];
        frame = CGRectOffset(frame, 750, 0);
        popoverController = [[UIPopoverController alloc] initWithContentViewController:storeQtysPO];
        [popoverController presentPopoverFromRect:frame inView:self.productsUITableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma signature

- (void)displaySignatureScreen {
    NSArray *totals = [helper getTotals:self.coreDataOrder];
    double netTotal = [(NSNumber *) totals[0] doubleValue] + [(NSNumber *) totals[2] doubleValue];

    static CISignatureViewController *signatureViewController;
    static dispatch_once_t loadSignatureViewControllerOnce;
    dispatch_once(&loadSignatureViewControllerOnce, ^{
        signatureViewController = [[CISignatureViewController alloc] init];
        signatureViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    });

    [signatureViewController reinitWithTotal:[NSNumber numberWithDouble:netTotal] authToken:self.authToken orderId:self.coreDataOrder.orderId andDelegate:(id <SignatureDelegate>) self];
    [self presentViewController:signatureViewController animated:YES completion:nil];
}

- (void)signatureViewDismissed {
    [self dismissSelf];
}

#pragma Keyboard

- (void)setSelectedRow:(NSIndexPath *)index {
    selectedItemRowIndexPath = index;
}

- (void)keyboardWillShow:(NSNotification *)note {
    // Reducing the frame height by 300 causes it to end above the keyboard, so the keyboard cannot overlap any content. 300 is the height occupied by the keyboard.
    // In addition scroll the selected row into view.
    NSDictionary *info = [note userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
//    CGRect frame = self.productsUITableView.frame;
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationBeginsFromCurrentState:YES];
//    [UIView setAnimationDuration:0.3f];
//    frame.size.height -= (kbSize.width - 95); //width because landscape. 95 is height of the view that contains totals at the end of the table.
//    self.productsUITableView.frame = frame;
//    [self.productsUITableView scrollToRowAtIndexPath:selectedItemRowIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
//    [UIView commitAnimations];
//todo: can be moved to helper method and reused
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    [self addInsetToTable:kbSize.width - 95]; //width because landscape. 95 is height of the view that contains totals at the end of the table.
    [self.productsUITableView scrollToRowAtIndexPath:selectedItemRowIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    keyboardUp = YES;
    keyboardHeight = kbSize.width;
    [UIView commitAnimations];
}

- (void)addInsetToTable:(float)insetHeight {
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, insetHeight, 0.0); //width because landscape. 69 is height of the view that contains totals at the end of the table.
    self.productsUITableView.contentInset = contentInsets;
    self.productsUITableView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardDidHide {
//    CGRect frame = self.productsUITableView.frame;
//    [UIView beginAnimations:nil context:NULL];
//    [UIView setAnimationBeginsFromCurrentState:YES];
//    [UIView setAnimationDuration:0.3f];
//    CGRect tbFrame = [self.productsUITableView frame];
//    tbFrame.size.height = 459;
//    [self.productsUITableView setFrame:tbFrame];
//    [UIView commitAnimations];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.productsUITableView.contentInset = contentInsets;
    self.productsUITableView.scrollIndicatorInsets = contentInsets;
    keyboardUp = NO;
    [UIView commitAnimations];
}

@end
