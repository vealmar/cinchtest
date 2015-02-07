//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectVendorTableViewController.h"
#import "Vendor.h"
#import "ThemeUtil.h"


@implementation CISelectVendorTableViewController

- (NSFetchRequest *)query:(NSString *)queryString {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Vendor"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:4];
    if (queryString && queryString.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"vendid CONTAINS[cd] %@", queryString]];
        [predicates addObject:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", queryString]];
    }
    if (predicates.count > 0) {
        fetchRequest.predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
    }

    self.fetchRequest = fetchRequest;
    return fetchRequest;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Vendor *vendor = [self objectAtIndexPath:indexPath];
    static NSString *CellIdentifier = @"CustCell";
    UITableViewCell *cell = [myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.font = [UIFont regularFontOfSize:16];
    cell.textLabel.textColor = [UIColor colorWithRed:0.086 green:0.082 blue:0.086 alpha:1];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", vendor.name, vendor.vendid];
    if (vendor.groupName) {
        cell.detailTextLabel.text = vendor.groupName;
        cell.detailTextLabel.font = [UIFont regularFontOfSize:12];
        cell.detailTextLabel.textColor = [ThemeUtil noteColor];
    }
    return cell;
}

@end