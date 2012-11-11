//
//  ReachabilityDelegation.h
//  BestPickReports
//
//  Created by Chris Hardin on 10/1/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@protocol ReachabilityDelegate;


/**
 
 
  Implement this delegate in order to receive Reachability events. This is a standard objective-C delegate
 pattern. 
 
 example usage...
 
 reachDelegation = 
 [[ReachabilityDelegation alloc] initWithDelegate:self withUrl:[[SettingsManager sharedManager] lookupSettingByString:CHECK_URL]];	
 
 
 
 */
@interface ReachabilityDelegation : NSObject {
	
	id <ReachabilityDelegate> delegate;
	Reachability *reach;
    
}

@property (assign) id <ReachabilityDelegate> delegate;

@property (nonatomic, retain) Reachability *reach;

- (id)initWithDelegate:(id<ReachabilityDelegate>)del withUrl:(NSString*)url;

- (BOOL)isNetworkReachable;

@end


 


@protocol ReachabilityDelegate <NSObject>

//@optional


- (void)networkLost;

- (void)networkRestored;


 

@end
