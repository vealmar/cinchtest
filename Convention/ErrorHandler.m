//
//  ErrorHandler.m
//  PreopEval
//
//  Created by Chris Hardin on 2/10/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import "ErrorHandler.h"

static ErrorHandler *sharedInstance;

@implementation ErrorHandler


#pragma mark Singleton Implementation

+ (ErrorHandler*)sharedManager
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}

 

#pragma mark -
#pragma mark Description Override

- (NSString *)description {
	return @"ErrorHandler";
}



#pragma mark -
#pragma mark ClassInstanceMethods

-(void)displayAlertWithError:(NSError *)error {
   
 
	
	if (error != nil) {
		
	   	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error localizedFailureReason] message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
		 
		
	} else {
		
		[self displayAlertWithMessage:@"An Unknown Error has Occured!"];
	}
	   

	   
	
}

-(void)displayAlertWithMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
     
}

-(void)displayAlertWithTitleAndMessage:(NSString*)title withMessage:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
     
}


@end
