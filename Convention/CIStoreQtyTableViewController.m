//
//  CIStoreQtyTableViewController.m
//  Convention
//
//  Created by Matthew Clark on 8/16/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CIStoreQtyTableViewController.h"

@interface CIStoreQtyTableViewController () {
    NSArray *keys;
}

@end

@implementation CIStoreQtyTableViewController
@synthesize stores = _stores;
@synthesize delegate;
@synthesize tag;
@synthesize editable;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _stores = nil;
        //self.contentSizeForViewInPopover = CGSizeMake(200, 145);
        self.editable = YES;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _stores = nil;
        //self.contentSizeForViewInPopover = CGSizeMake(200, 145);
        self.editable = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setStores:(NSMutableDictionary *)stores {
    _stores = stores;
    keys = [stores.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber *n1 = (NSNumber *) obj1;
        NSNumber *n2 = (NSNumber *) obj2;
        return [n1 compare:n2];
    }];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.stores && ([self.stores isKindOfClass:[NSMutableDictionary class]] || [self.stores isKindOfClass:[NSDictionary class]])) {
        return self.stores.allKeys.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"StoreQty";
    CIStoreQtyCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        NSArray *arr = [[NSBundle mainBundle] loadNibNamed:@"CIStoreQtyCell" owner:self options:nil];
        cell = (CIStoreQtyCell *) [arr objectAtIndex:0];
    }
    cell.tag = indexPath.row;

    NSString *key = [keys objectAtIndex:indexPath.row];
    cell.Key.text = key;
    cell.Qty.text = [[self.stores objectForKey:key] stringValue];
    cell.lblQty.text = cell.Qty.text;
    if (!self.editable) {
        cell.Qty.hidden = YES;
    }

    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.row == keys.count - 1) {
//        float height = 0;
//        for (int i = 0; i < [tableView numberOfSections]; i++)
//        {
//            CGRect sectionRect = [tableView rectForSection:i];
//            height += sectionRect.size.height;
//        }
//        if (height > 250) height = 200;
//        self.contentSizeForViewInPopover = CGSizeMake(252, height);
//    }
}

#pragma mark - CIStoreQtyDelegate methods

- (void)QtyChange:(double)qty forIndex:(int)index {
    NSString *key = [keys objectAtIndex:index];
    [self.stores setObject:[NSNumber numberWithDouble:qty] forKey:key];
    if (self.delegate) {
        [self.delegate QtyTableChange:self.stores forIndex:self.tag];
    }
}

//-(void)selectNextRow:(int)fromIndex {
//    int row = fromIndex;
//    int section = 0;
//    ++row;
//    if(row >= [self.tableView numberOfRowsInSection:section])
//    {
//        row = 0;
////        ++section;
////        if(section >= [self.tableView numberOfSections])
////        {
////            row = 0;
////            section = 0;
////        }
//    }
//    NSIndexPath *rowToSelect = [self tableView:self.tableView willSelectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
//    [self.tableView selectRowAtIndexPath:rowToSelect animated:YES scrollPosition:UITableViewScrollPositionMiddle];
//    [self tableView:self.tableView didSelectRowAtIndexPath:rowToSelect];
//}
@end
