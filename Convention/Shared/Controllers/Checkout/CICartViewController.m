//  CICartViewController.m
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CICartViewController.h"
#import "config.h"
#import "ShowConfigurations.h"
#import "CIProductViewControllerHelper.h"
#import "NumberUtil.h"
#import "FarrisCartViewCell.h"
#import "SettingsManager.h"
#import "CoreDataUtil.h"
#import "ThemeUtil.h"
#import "CIBarButton.h"
#import "Order+Extensions.h"
#import "OrderCoreDataManager.h"
#import "EditableEntity+Extensions.h"
#import "OrderSubtotalsByDate.h"
#import "OrderTotals.h"
#import "LineItem+Extensions.h"


@interface CICartViewController ()

@property(strong, nonatomic) Order *order;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSNumber *selectedVendorId;
@property(nonatomic, strong) NSArray *productsInCart;
@property(nonatomic, strong) NSArray *discountsInCart;
@property(nonatomic) BOOL initialized;

@property (assign) float totalGross;
@property (assign) float totalDiscounts;
@property (assign) float totalFinal;

@property BOOL savingOrder;

@property (strong, nonatomic) NSMutableArray *subtotalLines;
@end

@implementation CICartViewController {
    __weak IBOutlet UILabel *customerInfoLabel;
    __weak IBOutlet UIImageView *logo;
    CIProductViewControllerHelper *helper;
    BOOL keyboardUp;
    float keyboardHeight;
}

- (id)initWithOrder:(Order *)coreDataOrder customer:(NSDictionary *)customerDictionary authToken:(NSString *)token selectedVendorId:(NSNumber *)selectedVendorId andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    self = [super initWithNibName:@"CICartViewController" bundle:nil];
    if (self) {
        helper = [[CIProductViewControllerHelper alloc] init];
        self.order = coreDataOrder;
        self.productsInCart = [[NSArray alloc] init];
        self.discountsInCart = [[NSArray alloc] init];
        self.subtotalLines = [NSMutableArray array];
        self.managedObjectContext = managedObjectContext;
        self.customer = customerDictionary;
        self.authToken = token;
        self.selectedVendorId = selectedVendorId;
        self.savingOrder = NO;
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
    self.navBar.topItem.title = self.title;
    self.allowSignature = [ShowConfigurations instance].captureSignature;
    logo.image = [ShowConfigurations instance].logo;
    self.discountTotal.hidden = self.discountTotalLabel.hidden = ![ShowConfigurations instance].discounts;
    self.netTotal.hidden = self.netTotalLabel.hidden = ![ShowConfigurations instance].discounts;
    self.voucherTotal.hidden = self.voucherTotalLabel.hidden = ![ShowConfigurations instance].vouchers;
    self.grossTotalLabel.text = [ShowConfigurations instance].discounts ? @"Gross Total" : @"Total";
    self.tableHeaderPigglyWiggly.hidden = YES;
    self.tableHeaderFarris.hidden = NO;
    self.zeroVouchers.hidden = YES;
    self.tableHeaderMinColumn.hidden = YES; //Bill Hicks demo is using the Farris Header and we have decided to hide the Min column for now since they do not use it.
    customerInfoLabel.text = self.customer != nil &&
            self.customer[kBillName] != nil &&
            ![self.customer[kBillName] isKindOfClass:[NSNull class]] ? self.customer[kBillName] : @"";
    self.vendorLabel.text = [helper displayNameForVendor:self.selectedVendorId];
    self.tableHeaderPrice1Label.text = [[ShowConfigurations instance] price1Label];
    self.tableHeaderPrice2Label.text = [[ShowConfigurations instance] price2Label];

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

    CINavViewManager *navViewManager = [[CINavViewManager alloc] init:NO];
    navViewManager.delegate = self;
    [navViewManager setupNavBar];
    navViewManager.title = [ThemeUtil titleTextWithFontSize:18 format:@"%s - %b", @"Order Summary", [self.customer objectForKey:kBillName], nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.initialized) {
        [self saveOrderOnFirstLoad];
    }
}

- (void)saveOrderOnFirstLoad {
    if ([helper isOrderReadyForSubmission:self.order]) {
        __weak CICartViewController *weakSelf = self;
        self.savingOrder = YES;
        self.order.status = @"pending";
        [OrderCoreDataManager syncOrder:self.order attachHudTo:self.view onSuccess:^(Order *order) {
//            weakSelf.order = order;
            [weakSelf refreshView];
        } onFailure:^{
            weakSelf.savingOrder = NO;
        }];
    }
    self.initialized = YES;
}

- (void)refreshView {
    NSMutableArray *productLinesBuilder = [NSMutableArray array]; //uses product id
    NSMutableArray *discountLinesBuilder = [NSMutableArray array]; //uses lineitemid
    for (LineItem *lineItem in self.order.lineItems) {
        if (lineItem.isDiscount) {
            [discountLinesBuilder addObject:lineItem.lineItemId];
        } else if (lineItem.productId) {
            [productLinesBuilder addObject:lineItem.productId];
        }
    }
    
    self.savingOrder = NO;
    self.productsInCart = [helper sortProductsBySequenceAndInvtId:[NSArray arrayWithArray:productLinesBuilder]];
    self.discountsInCart = [helper sortDiscountsByLineItemId:[NSArray arrayWithArray:discountLinesBuilder]];
    [self updateTotals];
    [self reloadTable];
}

- (void)reloadTable {
    [self.productsUITableView reloadData];
    if (keyboardUp) {
        [self addInsetToTable:keyboardHeight - 95];//width because landscape. 69 is height of the view that contains totals at the end of the table.
    }
}

- (void)updateTotals {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    
    [self.subtotalLines removeAllObjects];

    [self.order.calculateShipDateSubtotals each:^(NSDate *shipDate, NSNumber *totalOnShipDate) {
        [self.subtotalLines addObject:@[
                [NSString stringWithFormat:@"Shipping on %@", [dateFormatter stringFromDate:shipDate]],
                [NumberUtil formatDollarAmount:totalOnShipDate]
        ]];
    }];

    OrderTotals *totals = self.order.calculateTotals;
    if (self.totalDiscounts > 0) {
        [self.subtotalLines addObject:@[@"SUBTOTAL", [NumberUtil formatDollarAmount:totals.grossTotal]]];
        [self.subtotalLines addObject:@[@"DISCOUNT", [NumberUtil formatDollarAmount:totals.discountTotal]]];
    }
    [self.subtotalLines addObject:@[@"TOTAL", [NumberUtil formatDollarAmount:totals.total]]];

    [self.productsUITableView reloadData];

    self.grossTotal.text = [NumberUtil formatDollarAmount:totals.grossTotal];
    self.discountTotal.text = [NumberUtil formatDollarAmount:totals.discountTotal];
    self.voucherTotal.text = [NumberUtil formatDollarAmount:totals.voucherTotal];
    self.netTotal.text = [NumberUtil formatDollarAmount:totals.total];

    self.totalGross = [totals.grossTotal floatValue];
    self.totalDiscounts = [totals.discountTotal floatValue];
    self.totalFinal = [totals.total floatValue];
}

- (void)dismissSelf {
    [self.indicator startAnimating];
    [self.delegate cartViewDismissedWith:self.order orderCompleted:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Table stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            return self.productsInCart.count;
        }
        case 1: {
            return self.discountsInCart.count;
        }
        case 2: {
            return self.subtotalLines.count + 1;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
            LineItem *newLineItem = [self.order findLineByProductId:productId];
            FarrisCartViewCell *cell = (FarrisCartViewCell *) [helper dequeueReusableCartViewCell:myTableView];
            [cell initializeWithCart:newLineItem tag:[indexPath row] ProductCellDelegate:self];
            return cell;
        }
        case 1: {
            NSNumber *lineItemId = self.discountsInCart[(NSUInteger) [indexPath row]];
            LineItem *discountLineItem = [self.order findLineById:lineItemId];
            FarrisCartViewCell *cell = (FarrisCartViewCell *) [helper dequeueReusableCartViewCell:myTableView];
            [cell initializeWithDiscount:discountLineItem tag:[indexPath row] ProductCellDelegate:self];
            return cell;
        }
        case 2: {
            static NSString *odcId = @"stlId";

            int index = indexPath.row - 1;

            UILabel *cleftLabel = nil;
            UILabel *crightLabel = nil;

            UITableViewCell *cell = [myTableView dequeueReusableCellWithIdentifier:odcId];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:odcId];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;

                cleftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 880, 44)];
                cleftLabel.tag = 1001;
                cleftLabel.backgroundColor = [UIColor clearColor];
                cleftLabel.font = [UIFont regularFontOfSize:14];
                cleftLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                cleftLabel.numberOfLines = 1;
                cleftLabel.textAlignment = NSTextAlignmentRight;
                [cell.contentView addSubview:cleftLabel];

                crightLabel = [[UILabel alloc] initWithFrame:CGRectMake(920, 0, 90, 44)];
                crightLabel.tag = 1002;
                crightLabel.backgroundColor = [UIColor clearColor];
                crightLabel.font = [UIFont semiboldFontOfSize:14];
                crightLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                crightLabel.numberOfLines = 1;
                crightLabel.textAlignment = NSTextAlignmentRight;
                crightLabel.adjustsFontSizeToFitWidth = YES;
                [cell.contentView addSubview:crightLabel];
            } else {
                cleftLabel = (UILabel*)[cell.contentView viewWithTag:1001];
                crightLabel = (UILabel*)[cell.contentView viewWithTag:1002];
            }

            if (index >= 0) {
                NSArray *subtotalLine = self.subtotalLines[index];
                cleftLabel.text = subtotalLine[0];
                crightLabel.text = subtotalLine[1];
            } else {
                cleftLabel.text = @"";
                crightLabel.text = @"";
            }

            return cell;
        }
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
        LineItem *lineItem = [self.order findLineByProductId:productId];
        if (lineItem.warnings.count > 0 || lineItem.errors.count > 0)
            return 44 + ((lineItem.warnings.count + lineItem.errors.count) * 42);
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
        LineItem *lineItem = [self.order findLineByProductId:productId];
        [helper updateCellBackground:cell order:self.order lineItem:lineItem];
    }

    if(indexPath.row % 2 == 0) {
        cell.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1];
    } else {
        cell.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1];
    }

    if(indexPath.section == 2) {
        if (indexPath.row > 0) {
            cell.backgroundColor = [UIColor colorWithRed:0.976 green:0.976 blue:0.976 alpha:1];
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
    }
}

#pragma mark - Other

- (IBAction)Cancel:(id)sender {
    self.indicator.hidden = NO;
    [self.indicator startAnimating];
    [self.delegate cartViewDismissedWith:self.order orderCompleted:NO];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)finishOrder {
    if ([helper isOrderReadyForSubmission:self.order]) {
        __weak CICartViewController *weakSelf = self;
        self.order.status = @"complete";
        self.savingOrder = YES;
        [OrderCoreDataManager syncOrder:self.order attachHudTo:self.view onSuccess:^(Order *order) {
            [weakSelf finishOrderSyncComplete:weakSelf.order];
            weakSelf.savingOrder = NO;
        } onFailure:^{
            weakSelf.savingOrder = NO;
        }];
    }
}

- (void)finishOrderSyncComplete:(Order *)order {
    self.order = order;
    self.indicator.hidden = YES;
    if (order.hasErrors) {
        [self refreshView];
    } else {
        if (self.allowSignature) {
            [self displaySignatureScreen];
        } else {
            [self dismissSelf];
        }
    }
}

- (IBAction)handleTap:(UITapGestureRecognizer *)sender {
//    if (sender.state == UIGestureRecognizerStateEnded) {
//        for (FarrisCartViewCell *cell in self.productsUITableView.visibleCells) {
//            if ([cell.quantity isFirstResponder]) {
//                [cell.quantity resignFirstResponder];//so the keyboard will hide
//                break;
//            }
//        }
//    }
}

- (void)ShowPriceChange:(double)price productId:(NSNumber *)productId {
    [self.order updateItemShowPrice:@(price) productId:productId context:self.managedObjectContext];
}

- (void)QtyTouchForIndex:(NSNumber *)productId {

}

- (Order *)currentOrderForCell {
    return self.order;
}

#pragma signature

- (void)displaySignatureScreen {
    OrderTotals *totals1 = [(self.order) calculateTotals];
    NSArray *totals = @[totals1.grossTotal, totals1.voucherTotal, totals1.discountTotal];
    double netTotal = [(NSNumber *) totals[0] doubleValue] + [(NSNumber *) totals[2] doubleValue];

    static CISignatureViewController *signatureViewController;
    static dispatch_once_t loadSignatureViewControllerOnce;
    dispatch_once(&loadSignatureViewControllerOnce, ^{
        signatureViewController = [[CISignatureViewController alloc] init];
        signatureViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    });

    [signatureViewController reinitWithTotal:[NSNumber numberWithDouble:netTotal] authToken:self.authToken orderId:self.order.orderId andDelegate:(id <SignatureDelegate>) self];
    [self presentViewController:signatureViewController animated:YES completion:nil];
}

- (void)signatureViewDismissed {
    [self dismissSelf]; //@todo orders handle order signature
}

#pragma Keyboard

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
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.productsUITableView.contentInset = contentInsets;
    self.productsUITableView.scrollIndicatorInsets = contentInsets;
    keyboardUp = NO;
    [UIView commitAnimations];
}

#pragma mark - CINavViewManagerDelegate

- (UINavigationController *)navigationControllerForNavViewManager {
    return self.navigationController;
}

- (UINavigationItem *)navigationItemForNavViewManager {
    return self.navigationItem;
}

- (NSArray *)leftActionItems {
    UIBarButtonItem *menuItem = [CIBarButton buttonItemWithText:@"\uf053" style:CIBarButtonStyleTextButton orientation:CIBarButtonOrientationLeft handler:^(id sender) {
        if (!self.savingOrder) [self Cancel:nil];
    }];

    return @[ menuItem ];
}

- (NSArray *)rightActionItems {
    UIBarButtonItem *addItem = [CIBarButton buttonItemWithText:@"\uf00c" style:CIBarButtonStyleRoundButton orientation:(CIBarButtonOrientationRight) handler:^(id sender) {
        if (!self.savingOrder) [self finishOrder];
    }];

    return @[ addItem ];
}


@end
