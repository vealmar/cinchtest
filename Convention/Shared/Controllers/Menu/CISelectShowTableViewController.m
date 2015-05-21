//
// Created by septerr on 3/27/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectShowTableViewController.h"
#import "ThemeUtil.h"
#import "NilUtil.h"
#import "DateUtil.h"
#import "Show.h"


@implementation CISelectShowTableViewController {

}
- (NSFetchRequest *)query:(NSString *)queryString {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Show"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"begin_date" ascending:NO]];
    NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:4];
    if (queryString && queryString.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", queryString]];
        [predicates addObject:[NSPredicate predicateWithFormat:@"showDescription CONTAINS[cd] %@", queryString]];
    }
    if (predicates.count > 0) {
        fetchRequest.predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
    }
    self.fetchRequest = fetchRequest;
    return fetchRequest;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Show *show = [self objectAtIndexPath:indexPath];
    static NSString *CellIdentifier = @"CustCell";
    UITableViewCell *cell = [myTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.font = [UIFont regularFontOfSize:16];
    cell.textLabel.textColor = [UIColor colorWithRed:0.086 green:0.082 blue:0.086 alpha:1];
    NSDateFormatter *dateFormatter = [DateUtil createFormatter:@"MM/dd/yyyy"];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", show.title];
    if (show.begin_date) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", [NilUtil objectOrEmptyString:[dateFormatter stringFromDate:show.begin_date]], [NilUtil objectOrEmptyString:[dateFormatter stringFromDate:show.end_date]]];
        cell.detailTextLabel.font = [UIFont regularFontOfSize:12];
        cell.detailTextLabel.textColor = [ThemeUtil noteColor];
    }
    return cell;
}
@end