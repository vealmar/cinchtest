//
//  ReachabilityDelegation.m
//  BestPickReports
//
//  Created by Chris Hardin on 10/1/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import "ReachabilityDelegation.h"


@interface ReachabilityDelegation(private)
 
	
	- (void)registerForNetworkReachabilityNotifications;	
   
	
	
@end


@implementation ReachabilityDelegation

@synthesize delegate;
@synthesize reach;


 


- (id)initWithDelegate:(id<ReachabilityDelegate>)del withUrl:(NSString*)url{ // make this whatever you want
	if (self = [super init]){
	 
        delegate = del; // this defines what class listens to the 'notification'
		
		SCNetworkReachabilityRef reachRef = SCNetworkReachabilityCreateWithName(NULL, [url UTF8String]);
		reach = [[Reachability alloc] initWithReachabilityRef:reachRef]; 
		[reach startNotifier];
		 
		[self registerForNetworkReachabilityNotifications];
	}
    return self;
}



- (void)registerForNetworkReachabilityNotifications
{
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}


- (void)unsubscribeFromNetworkReachabilityNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (BOOL)isNetworkReachable
{
	
 	
	return (![reach currentReachabilityStatus] == NotReachable);	
}

- (void)reachabilityChanged:(NSNotification *)note
{
	//[bandwidthThrottlingLock lock];
	bool isReachable = [self isNetworkReachable];
 
	
	if (!isReachable){
	 
		
		[delegate networkLost];
		
	} else {
		
		 		
		[delegate networkRestored];
	}
	
	//[bandwidthThrottlingLock unlock];
}

-(void)dealloc{
	
	[self unsubscribeFromNetworkReachabilityNotifications];
	delegate = nil;
	
	 
}





@end
