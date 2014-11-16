//
//  CICustomerInfoViewController.h
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullToRefreshView.h"

@protocol CICustomerDelegate <NSObject>

- (void)customerSelected:(NSDictionary *)info;

@end

@interface CICustomerInfoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, PullToRefreshViewDelegate>
@property(unsafe_unretained, nonatomic) IBOutlet UIView *tablelayer;
@property(unsafe_unretained, nonatomic) IBOutlet UITableView *custTable;
@property(strong, nonatomic) IBOutlet UIView *custView;

@property(nonatomic, strong) NSArray *tableData;
@property(nonatomic, strong) NSMutableArray *filteredtableData;
@property(weak, nonatomic) IBOutlet UITextField *searchText;
@property(strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property(nonatomic, strong) NSString *authToken;

- (void)setCustomerData:(NSArray *)customerData;

- (IBAction)back:(id)sender;

- (IBAction)handleTap:(UITapGestureRecognizer *)sender;

@property(nonatomic, assign) id <CICustomerDelegate> delegate;

- (IBAction)submit:(id)sender;

@end