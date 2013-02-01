//
//  CIOrderViewController.h
//  Convention
//
//  Created by Matthew Clark on 12/8/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CIItemEditCell.h"
#import "CIProductViewController.h"
#import "CIStoreQtyTableViewController.h"
#import "PullToRefreshView.h"
#import "PrinterSelectionViewController.h"

@interface CIOrderViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate,
    UISearchBarDelegate, UITextViewDelegate, UIAlertViewDelegate, ItemEditDelegate, CIProductViewDelegate, CIStoreQtyTableDelegate,
    CIStoreQtyDelegate, PullToRefreshViewDelegate, ReachabilityDelegate, UIPrinterSelectedDelegate>
{
	ReachabilityDelegation *reachDelegation;
}
@property (nonatomic, strong) IBOutlet UISearchBar *sBar;
@property (nonatomic, strong) IBOutlet UIImageView *ciLogo;
@property (nonatomic, strong) NSMutableArray* orders;
@property (nonatomic, strong) NSMutableArray* orderData;
@property (nonatomic, strong) NSString* authToken;
@property (nonatomic) BOOL showPrice;
@property (nonatomic, strong) NSDictionary* vendorInfo;
@property (nonatomic, strong) NSString* vendorGroup;
@property BOOL masterVender;
@property int currentVender;
@property (nonatomic, strong) NSDictionary* itemsDB;
@property (nonatomic, strong) NSMutableArray* itemsQty;
@property (nonatomic, strong) NSMutableArray* itemsPrice;
@property (nonatomic, strong) NSMutableArray* itemsVouchers;
@property (nonatomic, strong) NSMutableArray* itemsShipDates;
@property (nonatomic, strong) NSMutableArray* itemsDiscounts;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) CIStoreQtyTableViewController *storeQtysPO;
@property (nonatomic, weak) NSManagedObjectContext* managedObjectContext;

@property (nonatomic) BOOL allowPrinting;
@property (nonatomic) BOOL showShipDates;

@property (weak, nonatomic) IBOutlet UITextView *shipdates;
@property (weak, nonatomic) IBOutlet UITableView *sideTable;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveBtn;
@property (weak, nonatomic) IBOutlet UIView *EditorView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolWithSave;
@property (weak, nonatomic) IBOutlet UIToolbar *toolPlain;
@property (weak, nonatomic) IBOutlet UITextField *customer;
@property (weak, nonatomic) IBOutlet UITextField *authorizer;
@property (weak, nonatomic) IBOutlet UITableView *itemsTable;
@property (weak, nonatomic) IBOutlet UITextView *shipNotes;
@property (weak, nonatomic) IBOutlet UITextView *notes;
@property (weak, nonatomic) IBOutlet UILabel *SCtotal;
@property (weak, nonatomic) IBOutlet UILabel *total;
@property (weak, nonatomic) IBOutlet UILabel *NoOrders;
@property (weak, nonatomic) IBOutlet UILabel *NoOrdersLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *ordersAct;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *itemsAct;
@property (strong, nonatomic) IBOutlet UIScrollView *OrderDetailScroll;
@property (weak, nonatomic) IBOutlet UIView *sideContainer;
@property (weak, nonatomic) IBOutlet UIView *placeholderContainer;
@property (weak, nonatomic) IBOutlet UIView *orderContainer;
@property (weak, nonatomic) IBOutlet UILabel *lblCompany;
@property (weak, nonatomic) IBOutlet UILabel *lblAuthBy;
@property (weak, nonatomic) IBOutlet UILabel *lblNotes;
@property (weak, nonatomic) IBOutlet UILabel *lblVoucher;
@property (weak, nonatomic) IBOutlet UILabel *lblItems;
@property (weak, nonatomic) IBOutlet UILabel *lblTotalPrice;
@property (weak, nonatomic) IBOutlet UIButton *printButton;
@property (weak, nonatomic) IBOutlet UILabel *headerVoucherLbl;
@property (weak, nonatomic) IBOutlet UILabel *grossTotal;
@property (weak, nonatomic) IBOutlet UILabel *discountTotal;

- (IBAction)AddNewOrder:(id)sender;
- (IBAction)logout:(id)sender;
- (IBAction)Save:(id)sender;
- (IBAction)Refresh:(id)sender;
- (IBAction)Print:(id)sender;
- (IBAction)Delete:(id)sender;

-(void)setSelectedPrinter:(NSString *)printer;

-(void)UpdateTotal;
-(void)Return;

@end
