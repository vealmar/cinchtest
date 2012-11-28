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
#import "Order.h"
#import "ReachabilityDelegation.h"

@class CIViewController;

@protocol CIProductViewDelegate <NSObject>

-(void) Return;

@end

@interface CIProductViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
    UISearchBarDelegate, UIAlertViewDelegate, CICustomerDelegate, CIProductCellDelegate,
    CIFinalCustomerDelegate, CICartViewDelegate, CIStoreQtyTableDelegate, ReachabilityDelegate>
{
	ReachabilityDelegation *reachDelegation;
}

@property (unsafe_unretained, nonatomic) IBOutlet UITableView *products;
@property (nonatomic, strong) IBOutlet UIImageView *ciLogo;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *hiddenTxt;
@property (unsafe_unretained, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray* productData;
@property (nonatomic, strong) NSMutableArray* resultData;
@property (nonatomic, strong) NSDictionary* customer;
@property (nonatomic, strong) NSString* authToken;
@property (nonatomic, strong) NSString* vendorGroup;
@property (nonatomic, strong) NSArray* customerDB;
@property (nonatomic, strong) NSMutableDictionary* productCart;
@property (nonatomic) BOOL showPrice;

@property (nonatomic) BOOL backFromCart;
@property (nonatomic) BOOL finishOrder;
@property (nonatomic) BOOL multiStore;
@property (nonatomic) int tOffset;

@property (unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) CIStoreQtyTableViewController *storeQtysPO;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) Order *order;

@property (unsafe_unretained, nonatomic) IBOutlet UINavigationBar *navBar;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *vendorView;
@property (unsafe_unretained, nonatomic) IBOutlet UITableView *vendorTable;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *dismissVendor;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *customerLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *vendorLabel;

@property (nonatomic, assign) id<CIProductViewDelegate> delegate;

-(void)PriceChange:(double)price forIndex:(int)idx;
-(void)QtyChange:(double)qty forIndex:(int)idx;

- (IBAction)Cancel:(id)sender;

//- (IBAction)logout:(id)sender;
- (IBAction)submit:(id)sender;
- (IBAction)finishOrder:(id)sender;
- (IBAction)reviewCart:(id)sender;
- (IBAction)vendorTouch:(id)sender;
- (IBAction)dismissVendorTouched:(id)sender;

- (IBAction)shipdatesTouched:(id)sender;


-(void)setCustomerInfo:(NSDictionary*)info;

 

@end
