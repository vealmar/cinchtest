//
// Created by David Jafari on 12/20/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "CITableViewController.h"
#import "CITableViewColumns.h"
#import "CITableViewHeader.h"
#import "CITableViewCell.h"

@implementation CITableViewController

static NSString *STATIC_CELL_REUSE_KEY = @"STATIC_CELL_REUSE_KEY";

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
    
    }

    return self;
}

- (void)setTableView:(UITableView *)tableView {
    [super setTableView:tableView];
    [self.tableView registerClass:[CITableViewCell class] forCellReuseIdentifier:STATIC_CELL_REUSE_KEY];
}


- (void)prepareForDisplay {
    self.columns = [self createColumns];

    if (self.header) {
        [self.header prepareForDisplay:self.columns];
        self.fixedData = [NSArray array];
    }
}

- (CITableViewColumns *)createColumns {
    CITableViewColumns *columns = [CITableViewColumns new];
    return columns;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 0) [NSException raise:NSInvalidArgumentException format:@"Base implementation of CITableViewController will only manage 1 section."];
    return self.fixedData[(NSUInteger) indexPath.row];
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[CITableViewCell class]]) {
        [((CITableViewCell *)cell) updateRowHighlight:indexPath];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:STATIC_CELL_REUSE_KEY forIndexPath:indexPath];
    [cell prepareForDisplay:self.columns];
    [cell render:[self objectAtIndexPath:indexPath]];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fixedData.count;
}

@end