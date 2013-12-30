//
//  CICartViewController.m
//  Convention
//
//  Created by Matthew Clark on 5/11/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CICartViewController.h"
#import "config.h"
#import "UIAlertViewDelegateWithBlock.h"
#import "ShowConfigurations.h"
#import "ALineItem.h"
#import "CIProductViewControllerHelper.h"
#import "NumberUtil.h"
#import "PWCartViewCell.h"
#import "FarrisCartViewCell.h"
#import "SettingsManager.h"
#import "Cart.h"

@interface CICartViewController () {
    __weak IBOutlet UILabel *customerInfoLabel;
    __weak IBOutlet UIImageView *logo;
    NSIndexPath *selectedItemRowIndexPath;
    CIProductViewControllerHelper *helper;
}

@end

@implementation CICartViewController
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        showPrice = YES;
        tOffset = 0;
        helper = [[CIProductViewControllerHelper alloc] init];
        self.productsInCart = [[NSArray alloc] init];
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - View lifecycle

- (void)adjustTotals {
    NSMutableArray *visibleTotalFields = [[NSMutableArray alloc] init];
    if (!self.grossTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.grossTotal, @"label" : self.grossTotalLabel}];
    if (!self.discountTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.discountTotal, @"label" : self.discountTotalLabel}];
    if (!self.voucherTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.voucherTotal, @"label" : self.voucherTotalLabel}];
    if (!self.netTotal.hidden) [visibleTotalFields addObject:@{@"field" : self.netTotal, @"label" : self.netTotalLabel}];
    int availableHeight = 84;
    int heightPerField = availableHeight / visibleTotalFields.count;
    int marginBottomPerField = 2;
    heightPerField = heightPerField - marginBottomPerField;
    int y = 4;
    for (NSDictionary *totalField in visibleTotalFields) {
        ((UILabel *) [totalField objectForKey:@"label"]).frame = CGRectMake(766, y, 129, heightPerField);
        UITextField *textField = ((UITextField *) [totalField objectForKey:@"field"]);
        textField.text = @"0";
        textField.frame = CGRectMake(875, y, 101, heightPerField);
        y = y + heightPerField + marginBottomPerField;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    logo.image = [ShowConfigurations instance].logo;
    self.discountTotal.hidden = self.discountTotalLabel.hidden = ![ShowConfigurations instance].discounts;
    self.netTotal.hidden = self.netTotalLabel.hidden = ![ShowConfigurations instance].discounts;
    self.voucherTotal.hidden = self.voucherTotalLabel.hidden = ![ShowConfigurations instance].vouchers;
    self.grossTotalLabel.text = [ShowConfigurations instance].discounts ? @"Gross Total" : @"Total";
    [self adjustTotals];
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
    NSArray *totals = [delegate getTotals];
    self.grossTotal.text = [NumberUtil formatDollarAmount:totals[0]];
    self.discountTotal.text = [NumberUtil formatDollarAmount:totals[2]];
    double netTotal = [(NSNumber *) totals[0] doubleValue] + [(NSNumber *) totals[2] doubleValue];
    self.netTotal.text = [NumberUtil formatDollarAmount:[NSNumber numberWithDouble:netTotal]];
    self.voucherTotal.text = [NumberUtil formatDollarAmount:totals[1]];
    [self.productsUITableView reloadData];
    [self.indicator stopAnimating];
    self.indicator.hidden = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.indicator startAnimating];
    navBar.topItem.title = self.title;
    self.showShipDates = [[ShowConfigurations instance] shipDates];
    self.allowPrinting = [ShowConfigurations instance].printing;
    self.multiStore = [[self.customer objectForKey:kStores] isKindOfClass:[NSArray class]] && [((NSArray *) [self.customer objectForKey:kStores]) count] > 0;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark - Table stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)myTableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.productsInCart.count : [self.delegate getDiscountItemsCount];
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) { //product items
        NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
        NSDictionary *product = [self.delegate getProduct:productId];
        Cart *cart = [delegate getCoreDataForProduct:productId];
        if ([kShowCorp isEqualToString:kPigglyWiggly]) {
            PWCartViewCell *cell = (PWCartViewCell *) [helper dequeueReusableCartViewCell:myTableView];
            [cell initializeWith:multiStore showPrice:self.showPrice product:product tag:[indexPath row] quantity:cart.editableQty
                           price:@([cart.editablePrice intValue] / 100.0) voucher:@([cart.editableVoucher intValue] / 100.0)
                       shipDates:cart.shipdates.count productCellDelegate:self];
            return cell;
        } else {
            FarrisCartViewCell *cell = (FarrisCartViewCell *) [helper dequeueReusableCartViewCell:myTableView];
            [cell initializeWith:product cart:cart tag:[indexPath row] ProductCellDelegate:self];
            return cell;
        }
    } else { //discount items
        NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
        NSDictionary *product = [self.delegate getProduct:productId];
        ALineItem *discountItem = [delegate getDiscountItemAt:[indexPath row]];
        FarrisCartViewCell *cell = (FarrisCartViewCell *) [helper dequeueReusableCartViewCell:myTableView];
        [cell initializeForDiscountWithProduct:product quantity:discountItem.quantity price:discountItem.price tag:[indexPath row] ProductCellDelegate:self];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
        NSDictionary *product = [self.delegate getProduct:productId];
        Cart *cart = [delegate getCoreDataForProduct:productId];
        if (cart.errors.count > 0)
            return 44 + cart.errors.count * 42;
    }
    return 44;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSNumber *productId = self.productsInCart[(NSUInteger) [indexPath row]];
        NSDictionary *product = [self.delegate getProduct:productId];
        Cart *cart = [delegate getCoreDataForProduct:productId];
        [helper updateCellBackground:cell product:product cart:cart];
    }
}

#pragma mark - Other

- (void)Cancel {
    self.indicator.hidden = NO;
    [self.indicator startAnimating];
    [self.delegate setOrderSubmitted:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)Cancel:(id)sender {
    [self Cancel];
}


- (IBAction)finishOrder:(id)sender {
    if ([self.delegate orderReadyForSubmission]) {
        [self.delegate setOrderSubmitted:YES];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)clearVouchers:(id)sender {
    if ([self.delegate orderReadyForSubmission]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Zero out all vouchers?" delegate:nil cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [UIAlertViewDelegateWithBlock showAlertView:alert withCallBack:^(NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                [self zeroAllVouchers];
            }
        }];
    }
}

- (void)zeroAllVouchers {
    for (int i = 0; i <= self.productsInCart.count; i++) {
        [delegate changeVoucherTo:0 forProductId:self.productsInCart[(NSUInteger) i]];
    }
    [self.productsUITableView reloadData];
}

- (void)VoucherChange:(double)voucherPrice forIndex:(int)idx {
    [self.delegate changeVoucherTo:voucherPrice forProductId:self.productsInCart[(NSUInteger) idx]];
}

- (void)QtyChange:(int)qty forIndex:(int)idx {
    self.grossTotal.textColor = [UIColor redColor];
    self.discountTotal.textColor = [UIColor redColor];
    self.netTotal.textColor = [UIColor redColor];
    [self.delegate changeQuantityTo:qty forProductId:self.productsInCart[(NSUInteger) idx]];
    NSNumber *productId = self.productsInCart[(NSUInteger) idx];
    NSDictionary *product = [self.delegate getProduct:productId];
    Cart *cart = [self.delegate getCoreDataForProduct:productId];
    ProductCell *cell = (ProductCell *) [self.productsUITableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(NSUInteger) idx inSection:0]];
    [helper updateCellBackground:cell product:product cart:cart];
}

- (void)QtyTouchForIndex:(int)idx {
    if ([popoverController isPopoverVisible]) {
        [popoverController dismissPopoverAnimated:YES];
    } else {
        if (!storeQtysPO) {
            storeQtysPO = [[CIStoreQtyTableViewController alloc] initWithNibName:@"CIStoreQtyTableViewController" bundle:nil];
        }
        NSNumber *productId = self.productsInCart[(NSUInteger) idx];
        Cart *cart = [delegate getCoreDataForProduct:productId];
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
#pragma Keyboard

- (void)setSelectedRow:(NSUInteger)index {
    selectedItemRowIndexPath = [NSIndexPath indexPathForRow:index inSection:0]; //todo: this view has two sections now
}

- (void)keyboardWillShow:(NSNotification *)note {
    // Reducing the frame height by 300 causes it to end above the keyboard, so the keyboard cannot overlap any content. 300 is the height occupied by the keyboard.
    // In addition scroll the selected row into view.
    CGRect frame = self.productsUITableView.frame;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    frame.size.height -= 300;
    self.productsUITableView.frame = frame;
    [self.productsUITableView scrollToRowAtIndexPath:selectedItemRowIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [UIView commitAnimations];
}

- (void)keyboardDidHide:(NSNotification *)note {
    CGRect frame = self.productsUITableView.frame;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3f];
    frame.size.height += 300;
    self.productsUITableView.frame = frame;
    [UIView commitAnimations];
}
@end
