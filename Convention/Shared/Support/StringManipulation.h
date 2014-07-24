//
//  StringManipulation.h
//  iCareCommon
//
//  Created by Chris Hardin on 3/21/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 
 
 Lots of String manipulation functions that are in the tradition of Java ad C# to make things easier for programmers 
 to transition. 
 
 */

@interface NSString (StringManipulation) 
	
/**
 
  Only checks to see if a string is empty... checking for null is not possible
 
 */
	- (BOOL)isEmpty;

/**
 
 Appending Strings
 
 */
	+ (NSString *)stringWithStrings:(NSString*) first, ... ;

/**
 
 Appending Strings
 
 */
	- (NSString *)stringByAppendingStrings:(NSString*)first, ... ;

/**
 
 @deprecated use KeychainUtil
 */
	- (NSString *)obscuredString;

/**
 
 @deprecated use KeychainUtil
 */
	- (NSString *)encryptedString;

/**
 
 @deprecated use KeychainUtil
 */
	- (NSString *)decryptedString;


/**
 
 Getting a parameter from a url string
 
 */
	- (NSString *)valueOfURLParameter:(NSString*)paramName;

/**
 
 
   
 */
	- (NSString *)stringWithTenDigitPhoneWith:(NSString*)leadingDigits;


/**
 
 
 Does a String contain a certain String
 
 */
    -(BOOL)contains:(NSString *)element;



/**
 
 
  Gets the last Character of String
 
 
 */
    -(NSString *)lastCharacter;


    -(NSString *)firstCharacter;

/**
 
 Does a String start with a certain string
 
 */
    -(BOOL)startsWith:(NSString *)prefix;

/**
 
 Does a String end with a certain string
 
 */
    -(BOOL)endsWith:(NSString *)suffix;


	-(int) lastIndexOf:(NSString *)lastIndexOf;


	
	
    
 

@end
