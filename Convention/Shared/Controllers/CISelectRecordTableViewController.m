//
// Created by David Jafari on 2/6/15.
// Copyright (c) 2015 Urban Coding. All rights reserved.
//

#import "CISelectRecordTableViewController.h"


@implementation CISelectRecordTableViewController

- (NSFetchRequest *)initialFetchRequest {
    return [self query:@""];
}

- (NSFetchRequest *)query:(NSString *)queryString {
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *selectedRecord = [self objectAtIndexPath:indexPath];
    [self.delegate recordSelected:selectedRecord];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)myTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end