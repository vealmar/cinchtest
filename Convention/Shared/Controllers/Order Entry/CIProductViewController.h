//
//  CIProductViewController.h
//  Convention
//
//  Created by Matthew Clark on 10/31/11. <-- this guy === retard
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CICustomerInfoViewController.h"
#import "CIFinalCustomerInfoViewController.h"
#import "CICartViewController.h"
#import "ReachabilityDelegation.h"
#import "PrinterSelectionViewController.h"
#import "VendorViewController.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "CISlidingProductViewController.h"
#import "CINavViewManager.h"

@class CIViewController;
@class Order;
@class AnOrder;
@class CIProductTableViewController;
@protocol CISlidingProductViewControllerDelegate;

typedef NS_ENUM(NSInteger, OrderUpdateStatus) {
    PartialOrderSaved,
    PartialOrderCancelled,
    PersistentOrderUpdated,
    PersistentOrderUnchanged,
    NewOrderCreated,
    NewOrderCancelled
};

@protocol CIProductViewDelegate <NSObject>

- (void)Return:(NSNumber *)orderId order:(AnOrder *)savedOrder updateStatus:(OrderUpdateStatus)updateStatus;

@end

@interface CIProductViewController : UIViewController <
        UIAlertViewDelegate,
        ProductCellDelegate,
        CIFinalCustomerDelegate,
        CICartViewDelegate,
        UIPrinterSelectedDelegate,
        VendorViewDelegate,
        CISlidingProductViewControllerDelegate,
        CINavViewManagerDelegate
        > {

}

@property (nonatomic, weak) CISlidingProductViewController *slidingProductViewControllerDelegate;
@property(nonatomic, strong) IBOutlet UITextField *hiddenTxt;
@property(weak, nonatomic) IBOutlet UITextField *searchText;
@property(unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property(strong, nonatomic) IBOutlet UITableView *vendorTable;
@property(strong, nonatomic) IBOutlet UILabel *customerLabel;
@property(strong, nonatomic) IBOutlet UILabel *vendorLabel; //todo: this does not seem to be associated to any ui element
@property(weak, nonatomic) IBOutlet UIButton *btnSelectShipDates;
@property(weak, nonatomic) IBOutlet UILabel *totalCost;

@property(weak, nonatomic) IBOutlet UIView *tableHeader;
@property(weak, nonatomic) IBOutlet UILabel *tableHeaderMinColumnLabel;
@property(weak, nonatomic) IBOutlet UILabel *tableHeaderPrice1Label;
@property(weak, nonatomic) IBOutlet UILabel *tableHeaderPrice2Label;

@property(strong, nonatomic) IBOutlet CIProductTableViewController *productTableViewController;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeightFooter; // used on bottom of Toolbar

@property(weak, nonatomic) IBOutlet UIButton *cartButton;

@property(nonatomic, assign) id <CIProductViewDelegate> delegate;
@property(nonatomic, strong) UIPopoverController *poController;
@property(nonatomic, strong) NSArray *resultData; //Array of all products displayed (filtered by search criteria, selected vendor, bulletin etc.)
@property(nonatomic, strong) NSMutableArray *vendorProductIds; //key is product_id. All products for the selected vendor or foe all vendors if the selected vendor is 'Any'. This is used when performing Search, so that the search is limited to the selected vendor's products.
@property(nonatomic, strong) NSMutableArray *vendorProducts; //AProducts
@property(nonatomic, strong) NSDictionary *customer;
@property(nonatomic, strong) NSString *authToken;
@property(nonatomic, strong) NSString *loggedInVendorId; //vendor#id of logged in vendor
@property(nonatomic, strong) NSString *loggedInVendorGroupId;
//vendor#vendorgroup_id of logged in vendor
@property(nonatomic) BOOL viewInitialized;
@property(nonatomic) BOOL orderSubmitted;
@property(nonatomic) NSInteger orderId;
@property(nonatomic) int selectedPrintStationId;
@property(nonatomic, strong) NSDictionary *availablePrinters;
@property(nonatomic) BOOL allowPrinting;
@property(nonatomic) BOOL useShipDates;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
//Order selected in the order view controller
@property(nonatomic, strong) AnOrder *selectedOrder;
@property(nonatomic) BOOL newOrder;

//Working copy of selected or new order
@property(nonatomic, strong) Order *coreDataOrder;
//Cart objects (in the coreDataOrder) which have been selected by the user.
@property(nonatomic, strong) NSMutableSet *selectedCarts;

@property(weak, nonatomic) IBOutlet UITextView *errorMessageTextView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *errorMessageHeightConstraint;

- (void)reinit;

- (void)toggleCartSelection:(Cart *)cart;

- (void)setVendor:(NSInteger)vendorId;

- (void)setBulletin:(NSInteger)bulletinId;

- (void)dismissVendorPopover;

- (void)reviewCart;

- (IBAction)Cancel:(id)sender;
- (IBAction)submit:(id)sender;

@end
