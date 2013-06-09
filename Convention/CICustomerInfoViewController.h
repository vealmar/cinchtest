//
//  CICustomerInfoViewController.h
//  Convention
//
//  Created by Matthew Clark on 11/2/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CICustomerDelegate <NSObject>

- (void)setCustomerInfo:(NSDictionary*)info;
- (void)Cancel;

@end

@interface CICustomerInfoViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet UIView *tablelayer;
@property (unsafe_unretained, nonatomic) IBOutlet UITableView *custTable;
@property (strong, nonatomic) IBOutlet UIView *custView;

@property (nonatomic, strong) NSArray* tableData;
@property (nonatomic, strong) NSMutableArray* filteredtableData;
@property (weak, nonatomic) IBOutlet UITextField *searchText;

@property (nonatomic, strong) NSString* authToken;

-(void) setCustomerData:(NSArray *)customerData;
- (IBAction)back:(id)sender;
- (IBAction)refresh:(id)sender;
- (IBAction)handleTap:(UITapGestureRecognizer *)sender;

@property (nonatomic, assign) id<CICustomerDelegate> delegate;

- (IBAction)submit:(id)sender;

@end
