//
//  ErrorHandler.h
//  PreopEval
//
//  Created by Chris Hardin on 2/10/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 
 
 If you have an error and need to display it, log it or whatever, use this class.
 
 */
@interface ErrorHandler : NSObject {

}

#pragma mark Singleton
+ (ErrorHandler*)sharedManager;
 
 
/**
 
  Display an Alert message with the contents of an error object
 
 */
- (void)displayAlertWithError:(NSError *)error;

/**
 
 Display and Alert message with a String
 
 */
- (void)displayAlertWithMessage:(NSString *)message;

/**
 
 Display a message and customize the title to whatever you want it to be
 
 */
-(void)displayAlertWithTitleAndMessage:(NSString*)title withMessage:(NSString *)message;

@end
