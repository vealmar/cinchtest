//
// Created by David Jafari on 5/31/14.
// Copyright (c) 2014 Urban Coding. All rights reserved.
//

#import "ProductSearchQueue.h"
#import "CIProductViewController.h"
#import "ProductSearch.h"
#import "CoreDataManager.h"

@interface ProductSearchOperation : NSOperation

@property ProductSearch *search;
@property NSArray *results;

+ (ProductSearchOperation *)search:(ProductSearch *)search;

@end

@implementation ProductSearchOperation

+ (ProductSearchOperation *)search:(ProductSearch *)search {
    ProductSearchOperation *operation = [[ProductSearchOperation alloc] init];
    operation.search = search;
    return operation;
}


- (void)main {
    @autoreleasepool {
        if (!self.isCancelled) {
            self.results = [CoreDataManager getProductIdsMatching:self.search];
        }
    }
}

@end

@interface ProductSearchQueue ()

@property NSOperationQueue *operationQueue;
@property CIProductViewController *productController;

@end

@implementation ProductSearchQueue

- (id)initWithProductController:(CIProductViewController *)productController {
    self = [super init];
    if (self) {
        self.productController = productController;
        self.operationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)search:(ProductSearch *)search {
    [self.operationQueue cancelAllOperations];

    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSMutableArray *searchOperations = [NSMutableArray array];
            [[search split:@","] enumerateObjectsUsingBlock:^(ProductSearch *search, NSUInteger idx, BOOL *stop) {
                if (search.queryString.length > 0) {
                    ProductSearchOperation *searchOperation = [ProductSearchOperation search:search];
                    [searchOperations addObject:searchOperation];
                }
            }];

            NSOperation *setResultsOperation = [[NSOperation alloc] init];
            [searchOperations enumerateObjectsUsingBlock:^(id searchOperation, NSUInteger idx, BOOL *stop) {
                [setResultsOperation addDependency:searchOperation];
            }];
            __weak NSOperation *weakSetResultsOperation = setResultsOperation;
            setResultsOperation.completionBlock = ^{
                if (!weakSetResultsOperation.isCancelled) {
                    NSMutableArray *newResults = [NSMutableArray array];
                    [weakSetResultsOperation.dependencies enumerateObjectsUsingBlock:^(ProductSearchOperation *searchOperation, NSUInteger idx, BOOL *stop) {
                        NSArray *results = searchOperation.results;
                        if (newResults.count == 0) {
                            [newResults addObjectsFromArray:results];
                        } else {
                            NSSet *resultsSet = [NSSet setWithArray:results];
                            NSMutableArray *objectsToRemove = [NSMutableArray array];
                            [newResults enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                if (![resultsSet containsObject:obj]) {
                                    [objectsToRemove addObject:obj];
                                }
                            }];
                            [newResults removeObjectsInArray:objectsToRemove];
                        }
                    }];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.productController.resultData = newResults;
                    });
                }
            };

            [self.operationQueue addOperation:setResultsOperation];
            [self.operationQueue addOperations:searchOperations waitUntilFinished:NO];
        }
    });
}


@end

