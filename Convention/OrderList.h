//
//  OrderList.h
//  Convention
//
//  Created by Matthew Clark on 12/7/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrderList : UIViewController{
    NSArray* orders;
}
@property (nonatomic, strong) NSString* authToken;
@property (nonatomic, strong) NSString* title;
@property (nonatomic) BOOL showPrice;
@property (unsafe_unretained, nonatomic) IBOutlet UINavigationBar *navBar;
@property (nonatomic, strong) NSDictionary* venderInfo;
@property (unsafe_unretained, nonatomic) IBOutlet UITableView *table;
- (IBAction)AddNewOrder:(id)sender;
- (IBAction)logout:(id)sender;

@end
