//
//  CICustomerInfoViewController.h
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CICustomerDelegate <NSObject>

-(void)setCustomerInfo:(NSDictionary*)info;
- (IBAction)Cancel:(id)sender;

@end

@interface CICustomerInfoViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,UISearchBarDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet UIView *tablelayer;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *customerID;
@property (unsafe_unretained, nonatomic) IBOutlet UITableView *custTable;
@property (strong, nonatomic) IBOutlet UIScrollView *scroll;
@property (strong, nonatomic) IBOutlet UIView *custView;
@property (unsafe_unretained, nonatomic) IBOutlet UISearchBar *search;

@property (nonatomic, strong) NSArray* tableData;
@property (nonatomic, strong) NSMutableArray* filteredtableData;

@property (nonatomic, strong) NSString* authToken;

-(void) setCustomerData:(NSArray *)customerData;
- (IBAction)back:(id)sender;
- (IBAction)refresh:(id)sender;

@property (nonatomic, assign) id<CICustomerDelegate> delegate;

- (IBAction)submit:(id)sender;

@end
