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
#import "CIProductCell.h"
#import "CIStoreQtyTableViewController.h"
#import "ReachabilityDelegation.h"
#import "PrinterSelectionViewController.h"
#import "VendorViewController.h"

@class CIViewController;
@class Order;

@protocol CIProductViewDelegate <NSObject>

-(void) Return;

@end

@interface CIProductViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
    UISearchBarDelegate, UIAlertViewDelegate, CICustomerDelegate, CIProductCellDelegate,
    CIFinalCustomerDelegate, CICartViewDelegate, CIStoreQtyTableDelegate, ReachabilityDelegate, UIPrinterSelectedDelegate, VendorViewDelegate>
{
	ReachabilityDelegation *reachDelegation;
}

@property (nonatomic, strong) IBOutlet UITableView *products;
@property (nonatomic, strong) IBOutlet UIImageView *ciLogo;
@property (nonatomic, strong) IBOutlet UITextField *hiddenTxt;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray* productData;
@property (nonatomic, strong) NSMutableArray* resultData;
@property (nonatomic, strong) NSDictionary* customer;
@property (nonatomic, strong) NSString* authToken;
@property (nonatomic, strong) NSString* vendorGroup;
@property (nonatomic, strong) NSArray* customerDB;
@property (nonatomic, strong) NSMutableDictionary* productCart;
@property (nonatomic) BOOL showPrice;
@property (nonatomic) BOOL showCustomers;
@property (nonatomic) BOOL backFromCart;
@property (nonatomic) BOOL finishOrder;
@property (nonatomic) BOOL multiStore;
@property (nonatomic) int tOffset;
@property (nonatomic) int customerId;
@property (nonatomic) int printStationId;
@property (nonatomic, strong) NSDictionary *availablePrinters;

@property (unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) CIStoreQtyTableViewController *storeQtysPO;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) Order *order;

@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) IBOutlet UIView *vendorView;
@property (strong, nonatomic) IBOutlet UITableView *vendorTable;
@property (strong, nonatomic) IBOutlet UIButton *dismissVendor;
@property (strong, nonatomic) IBOutlet UILabel *customerLabel;
@property (strong, nonatomic) IBOutlet UILabel *vendorLabel;
@property (weak, nonatomic) IBOutlet UIButton *vendorDropdown;

@property (nonatomic, assign) id<CIProductViewDelegate> delegate;

-(void)PriceChange:(double)price forIndex:(int)idx;
-(void)QtyChange:(double)qty forIndex:(int)idx;

- (IBAction)Cancel:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *cartButton;

//- (IBAction)logout:(id)sender;
- (IBAction)submit:(id)sender;
- (IBAction)finishOrder:(id)sender;
- (IBAction)reviewCart:(id)sender;
- (IBAction)vendorTouch:(id)sender;
- (IBAction)dismissVendorTouched:(id)sender;

//@property (weak, nonatomic) IBOutlet UIToolbar *vendorNav;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *vendorNavBack;
//-(IBAction)backToVendors:(id)sender;

- (IBAction)shipdatesTouched:(id)sender;

-(void)setCustomerInfo:(NSDictionary*)info;
-(void)setVendor:(NSInteger)vendorId;
-(void)setBulletin:(NSInteger)bulletinId;
-(void)dismissVendorPopover;

@end
