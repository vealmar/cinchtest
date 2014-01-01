//
//  CIProductViewController.h
//  Convention
//
//  Created by Matthew Clark on 10/31/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CICustomerInfoViewController.h"
#import "CIFinalCustomerInfoViewController.h"
#import "CICartViewController.h"
#import "PWProductCell.h"
#import "CIStoreQtyTableViewController.h"
#import "ReachabilityDelegation.h"
#import "PrinterSelectionViewController.h"
#import "VendorViewController.h"
#import "UIView+FindAndResignFirstResponder.h"

@class CIViewController;
@class Order;
@class AnOrder;
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

@interface CIProductViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
        UIAlertViewDelegate, ProductCellDelegate,
        CIFinalCustomerDelegate, CICartViewDelegate, CIStoreQtyTableDelegate, ReachabilityDelegate,
        UIPrinterSelectedDelegate, VendorViewDelegate, PullToRefreshViewDelegate> {
    ReachabilityDelegation *reachDelegation;

}

@property(nonatomic, strong) IBOutlet UITableView *productsTableView;
@property(nonatomic, strong) IBOutlet UIImageView *ciLogo;
@property(nonatomic, strong) IBOutlet UITextField *hiddenTxt;
@property(weak, nonatomic) IBOutlet UITextField *searchText;
@property(unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property(strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property(strong, nonatomic) IBOutlet UIView *vendorView;
@property(strong, nonatomic) IBOutlet UITableView *vendorTable;
//SG: This is the Bulletins drop down.
@property(strong, nonatomic) IBOutlet UIButton *dismissVendor;
@property(strong, nonatomic) IBOutlet UILabel *customerLabel;
@property(strong, nonatomic) IBOutlet UILabel *vendorLabel; //todo: this does not seem to be associated to any ui element
@property(weak, nonatomic) IBOutlet UIButton *vendorDropdown;
@property(weak, nonatomic) IBOutlet UILabel *lblShipDate1;
@property(weak, nonatomic) IBOutlet UILabel *lblShipDate2;
@property(weak, nonatomic) IBOutlet UILabel *lblShipDateCount;
@property(weak, nonatomic) IBOutlet UIButton *btnSelectShipDates;
@property(weak, nonatomic) IBOutlet UILabel *totalCost;
@property(weak, nonatomic) IBOutlet UIView *tableHeaderPigglyWiggly;
@property(weak, nonatomic) IBOutlet UIView *tableHeaderFarris;
@property(weak, nonatomic) IBOutlet UILabel *tableHeaderMinColumnLabel;

@property(weak, nonatomic) IBOutlet UILabel *bulletinVendorLabel;

- (IBAction)Cancel:(id)sender;

@property(weak, nonatomic) IBOutlet UIButton *cartButton;

- (IBAction)submit:(id)sender;

- (IBAction)reviewCart:(id)sender;

- (IBAction)vendorTouch:(id)sender;

- (IBAction)dismissVendorTouched:(id)sender;

- (IBAction)searchProducts:(id)sender;

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer;

- (IBAction)shipdatesTouched:(id)sender;

@property(nonatomic, assign) id <CIProductViewDelegate> delegate;
@property(nonatomic, strong) UIPopoverController *poController;
@property(nonatomic, strong) CIStoreQtyTableViewController *storeQtysPO;
@property(nonatomic, strong) NSArray *resultData; //Array of all products displayed (filtered by search criteria, selected vendor, bulletin etc.)
@property(nonatomic, strong) NSMutableArray *vendorProductIds; //key is product_id. All products for the selected vendor or foe all vendors if the selected vendor is 'Any'. This is used when performing Search, so that the search is limited to the selected vendor's products.
@property(nonatomic, strong) NSDictionary *customer;
@property(nonatomic, strong) NSString *authToken;
@property(nonatomic, strong) NSString *loggedInVendorId; //vendor#id of logged in vendor
@property(nonatomic, strong) NSString *loggedInVendorGroupId;
//vendor#vendorgroup_id of logged in vendor
@property(nonatomic, strong) NSMutableDictionary *productCart; //key is product_id. Value is ALineItem. Line items get added or removed from the cart when quantity changes. They are added or removed irrespective of ship dates.
@property(nonatomic, strong) NSMutableDictionary *discountItems;
@property(nonatomic) BOOL viewInitialized;
@property(nonatomic) BOOL orderSubmitted;
@property(nonatomic) BOOL multiStore;
@property(nonatomic) NSInteger orderId;
@property(nonatomic) int selectedPrintStationId;
@property(nonatomic, strong) NSDictionary *availablePrinters;
@property(nonatomic) BOOL allowPrinting;
@property(nonatomic) BOOL showShipDates;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
//Order selected in the order view controller
@property(nonatomic, strong) AnOrder *selectedOrder;
@property(nonatomic) BOOL newOrder;
@property(weak, nonatomic) IBOutlet UITextView *errorMessageTextView;

@property(weak, nonatomic) IBOutlet NSLayoutConstraint *errorMessageHeightConstraint;

- (void)QtyChange:(int)qty forIndex:(int)idx;

- (void)setVendor:(NSInteger)vendorId;

- (void)setBulletin:(NSInteger)bulletinId;

- (void)dismissVendorPopover;
@end
