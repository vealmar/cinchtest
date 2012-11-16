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


@interface CIOrderViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,CIItemEditDelegate,CIProductViewDelegate, UITextFieldDelegate, UITextViewDelegate,CIStoreQtyTableDelegate, CIStoreQtyDelegate,UIAlertViewDelegate, ReachabilityDelegate>{
	
	ReachabilityDelegation *reachDelegation;
    
}
@property (nonatomic, strong) IBOutlet UIImageView *ciLogo;
@property (nonatomic, strong) NSArray* orders;
@property (nonatomic, strong) NSString* authToken;
@property (nonatomic) BOOL showPrice;
@property (nonatomic, strong) NSMutableArray* venderInfo;
@property (nonatomic, strong) NSString* vendorGroup;
@property BOOL masterVender;
@property int currentVender;
@property (nonatomic, strong) NSDictionary* itemsDB;
@property (nonatomic, strong) NSMutableArray* itemsQty;
@property (nonatomic, strong) NSMutableArray* itemsPrice;
@property (nonatomic, strong) NSMutableArray* itemsVouchers;
@property (nonatomic, strong) NSMutableArray* itemsShipDates;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) CIStoreQtyTableViewController *storeQtysPO;
@property (nonatomic, unsafe_unretained) NSManagedObjectContext* managedObjectContext;

@property (unsafe_unretained, nonatomic) IBOutlet UITextView *shipdates;
@property (unsafe_unretained, nonatomic) IBOutlet UITableView *sideTable;
@property (unsafe_unretained, nonatomic) IBOutlet UIBarButtonItem *saveBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *EditorView;
@property (unsafe_unretained, nonatomic) IBOutlet UIToolbar *toolWithSave;
@property (unsafe_unretained, nonatomic) IBOutlet UIToolbar *toolPlain;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *customer;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *authorizer;
@property (unsafe_unretained, nonatomic) IBOutlet UITableView *itemsTable;
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *shipNotes;
@property (unsafe_unretained, nonatomic) IBOutlet UITextView *notes;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *SCtotal;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *total;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *NoOrders;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *NoOrdersLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *ordersAct;
@property (unsafe_unretained, nonatomic) IBOutlet UIActivityIndicatorView *itemsAct;
@property (unsafe_unretained, nonatomic) IBOutlet UIScrollView *OrderDetailScroll;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *sideContainer;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *placeholderContainer;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *orderContainer;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblCompany;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblAuthBy;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblNotes;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblShipNotes;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblVoucher;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblItems;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *lblTotalPrice;

- (IBAction)AddNewOrder:(id)sender;
- (IBAction)logout:(id)sender;
- (IBAction)Save:(id)sender;
- (IBAction)Refresh:(id)sender;
- (IBAction)Print:(id)sender;
- (IBAction)Delete:(id)sender;

-(void)UpdateTotal;
-(void)Return;

@end
