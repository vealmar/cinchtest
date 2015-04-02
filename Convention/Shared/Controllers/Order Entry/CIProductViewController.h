//
//  CIProductViewController.h
//  Convention
//
//  Created by Matthew Clark on 10/31/11. <-- this guy === retard
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CISelectCustomerViewController.h"
#import "CIFinalCustomerInfoViewController.h"
#import "CICartViewController.h"
#import "ReachabilityDelegation.h"
#import "VendorViewController.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "CISlidingProductDetailViewController.h"
#import "CINavViewManager.h"

@class CILoginViewController;
@class CIProductTableViewController;
@class Order;

typedef NS_ENUM(NSInteger, OrderUpdateStatus) {
    PartialOrderSaved,
    PartialOrderCancelled,
    PersistentOrderUpdated,
    PersistentOrderUnchanged,
    NewOrderCreated,
    NewOrderCancelled
};

@protocol CIProductViewDelegate <NSObject>

- (void)returnOrder:(NSManagedObjectID *)savedOrder updateStatus:(OrderUpdateStatus)updateStatus;

@end

@interface CIProductViewController : UIViewController <
        UIAlertViewDelegate,
        ProductCellDelegate,
        CIFinalCustomerDelegate,
        CICartViewDelegate,
        VendorViewDelegate,
        CINavViewManagerDelegate
        >

@property(weak, nonatomic) IBOutlet UITextField *searchText;
@property(strong, nonatomic) IBOutlet UITableView *vendorTable;
@property(strong, nonatomic) IBOutlet UILabel *customerLabel;
@property(strong, nonatomic) IBOutlet UILabel *vendorLabel; //todo: this does not seem to be associated to any ui element
@property(weak, nonatomic) IBOutlet UIButton *btnSelectShipDates;

@property(weak, nonatomic) IBOutlet UIView *tableHeader;
@property(weak, nonatomic) IBOutlet UIView *summaryView;
@property(weak, nonatomic) IBOutlet UITextView *errorMessageTextView;
@property(weak, nonatomic) IBOutlet UILabel *totalCost;
@property(weak, nonatomic) IBOutlet UILabel *tableHeaderMinColumnLabel;
@property(weak, nonatomic) IBOutlet UILabel *tableHeaderPrice1Label;
@property(weak, nonatomic) IBOutlet UILabel *tableHeaderPrice2Label;

@property(strong, nonatomic) IBOutlet CIProductTableViewController *productTableViewController;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeightFooter; // used on bottom of Toolbar

@property(nonatomic, assign) id <CIProductViewDelegate> delegate;
@property(nonatomic, strong) UIPopoverController *poController;
@property(nonatomic, strong) NSDictionary *customer;
//vendor#vendorgroup_id of logged in vendor
@property(nonatomic) BOOL viewInitialized;
@property(nonatomic) BOOL orderSubmitted;
@property(nonatomic) NSInteger orderId; //@todo orders dump this and just use order.orderId
//Order selected in the order view controller
@property(nonatomic) BOOL newOrder;

//Working copy of selected or new order
@property(nonatomic, strong) Order *order;
//Cart objects (in the coreDataOrder) which have been selected by the user.
@property(nonatomic, strong) NSMutableSet *selectedLineItems;

- (void)reinit;

-(void)deselectAllLines;

- (void)setVendor:(NSInteger)vendorId;

- (void)setBulletin:(NSInteger)bulletinId;

- (void)dismissVendorPopover;

- (void)reviewCart;

- (IBAction)submit:(NSString *)sendEmailTo;

@end
