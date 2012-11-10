//
//  CIStoreQtyTableViewController.m
//  Convention
//
//  Created by Matthew Clark on 8/16/12.
//  Copyright (c) 2012 MotionMobs. All rights reserved.
//

#import "CIStoreQtyTableViewController.h"
#import "CIStoreQtyCell.h"

@interface CIStoreQtyTableViewController ()

@end

@implementation CIStoreQtyTableViewController
@synthesize stores;
@synthesize delegate;
@synthesize tag;
@synthesize editable;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        stores = nil;
        self.contentSizeForViewInPopover = CGSizeMake(200, 145);
        self.editable = YES;
    }
    return self;
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        stores = nil;
        self.contentSizeForViewInPopover = CGSizeMake(200, 145);
        self.editable = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    DLog(@"numberOfSections with stores:%@",stores);
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
//    DLog(@"numberOfRowsInSection with stores:%@",stores);
    if (stores&&([stores isKindOfClass:[NSMutableDictionary class]]||[stores isKindOfClass:[NSDictionary class]])) {
        return stores.allKeys.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    DLog(@"cellForRowAtIndexPath with stores:%@",stores);
    if(stores == nil||![stores isKindOfClass:[NSMutableDictionary class]])
        return nil;
    
    static NSString *CellIdentifier = @"StoreQty";
    CIStoreQtyCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    
    if (cell == nil) {
        NSArray* arr = [[NSBundle mainBundle] loadNibNamed:@"CIStoreQtyCell" owner:self options:nil];
        cell = (CIStoreQtyCell*)[arr objectAtIndex:0];
    }
    cell.tag = indexPath.row;
    
    NSArray* keys = [stores.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber* n1 = (NSNumber*)obj1;NSNumber* n2 = (NSNumber*)obj2;
        return [n1 compare:n2];
    }];
    
//    DLog(@"keys: %@",keys);
    
    NSString* key = [keys objectAtIndex:indexPath.row];
//    DLog(@"key:%@ value:%@",key, [stores objectForKey:key]);
    cell.Key.text = key;
    cell.Qty.text = [[stores objectForKey:key] stringValue];
    cell.lblQty.text = cell.Qty.text;
    if (!self.editable) {
//        DLog(@"tap");
        cell.Qty.hidden = YES;
    }
    
    cell.delegate = self;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

-(void)QtyChange:(double)qty forIndex:(int)idx{
    NSArray* keys = [stores.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber* n1 = (NSNumber*)obj1;NSNumber* n2 = (NSNumber*)obj2;
        return [n1 compare:n2];
    }];
    NSString* key = [keys objectAtIndex:idx];
    [self.stores setObject:[NSNumber numberWithDouble:qty] forKey:key];
    if (self.delegate) {
        [self.delegate QtyTableChange:stores forIndex:self.tag];
    }
}

@end
