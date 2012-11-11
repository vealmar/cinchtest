//
//  OrderList.m
//  Convention
//
//  Created by Matthew Clark on 12/7/11.
//  Copyright (c) 2011 MotionMobs. All rights reserved.
//

#import "OrderList.h"
#import "config.h"
#import "ASIHTTPRequest.h"
#import "CIProductViewController.h"
#import "JSONKit.h"
#import "SettingsManager.h"

@implementation OrderList
@synthesize authToken;
@synthesize showPrice;
@synthesize navBar;
@synthesize title;
@synthesize venderInfo;
@synthesize table;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    NSString* url = [NSString stringWithFormat:@"%@?%@=%@",kDBORDER,kAuthToken,self.authToken];
    DLog(@"Sending %@",url);
    ASIHTTPRequest* __weak request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request setCompletionBlock:^{
        //DLog(@"response:%@",[request responseString]);
        dispatch_async(dispatch_get_main_queue(), ^{
        orders = [[request responseString] objectFromJSONString];
        DLog(@"orders Json:%@",orders);
        [self.table reloadData];
        });
    }];
    
    [request setFailedBlock:^{
       // DLog(@"error:%@", [request error]);
    }];
    
    [request startAsynchronous];
    navBar.topItem.title = self.title;
    
}

- (void)viewDidUnload
{
    [self setNavBar:nil];
    [self setTable:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [orders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSDictionary* data = [orders objectAtIndex:[indexPath row]];
    DLog(@"data:%@",data);
    cell.textLabel.text = [NSString stringWithFormat:@"%@,%@,%@,%@,%@",[data objectForKey:kCustID],[[data objectForKey:@"customer"] objectForKey:kBillName],[data objectForKey:kAuthorizedBy],[data objectForKey:kItemCount],[data objectForKey:kTotal]];
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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

- (IBAction)AddNewOrder:(id)sender {
    CIProductViewController* page;
    //                if (IS_IPAD) {
    //                    page = [[CIProductViewController alloc] initWithNibName:@"CIProductViewController-iPad" bundle:nil];
    //                }
    //                else
    //                {
    //                    page = [[CIProductViewController alloc] initWithNibName:@"CIProductViewController-iPhone" bundle:nil];
    //                }
    
    page = [[CIProductViewController alloc] initWithNibName:@"CIProductViewController-iPhone" bundle:nil];
    
    page.authToken = self.authToken;
    
    [page setTitle:[venderInfo objectForKey:kName]];
    if([venderInfo objectForKey:kVenderHidePrice] != nil){
        if ([[venderInfo objectForKey:kVenderHidePrice] boolValue]) {
            page.showPrice = NO;
        }
    }
    
    DLog(@"Vendor Name:%@, navTitle:%@",[venderInfo objectForKey:kName],page.navBar.topItem.title);
    [self presentViewController:page animated:YES completion:nil];
}
-(void)logout
{
    NSString* url = kDBLOGOUT;
    if (authToken) {
        url = [NSString stringWithFormat:@"%@?%@=%@",kDBLOGOUT,kAuthToken,authToken];
    }
    
    DLog(@"Signout url:%@",url);
    
    __block ASIHTTPRequest* signout = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [signout setRequestMethod:@"DELETE"];
    
    [signout setCompletionBlock:^{
         //DLog(@"Signout:%@",[signout responseString]);
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [signout setFailedBlock:^{
        //DLog(@"Signout Error:%@",[signout error]);
    }];
    
    [signout startAsynchronous];
}

- (IBAction)logout:(id)sender {
    [self logout];
}
@end
