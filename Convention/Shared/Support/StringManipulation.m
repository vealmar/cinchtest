//
//  NSStringAdditions.m
//  //
//
//  Created by Chris Hardin on 12/4/09.
//  Copyright 2009 Dapper Dapple Mobile LLC. All rights reserved.
//

#import "StringManipulation.h"

@implementation NSString (StringManipulation)


- (BOOL)isEmpty {
    return [self length] == 0;
}

-(BOOL)contains:(NSString *)element {
	
	
		return [self rangeOfString:element].location != NSNotFound;
	
}

-(NSString *)lastCharacter {
	
	 
	return [self substringFromIndex: [self length] - 1];
}

-(NSString *)firstCharacter {
	
	
	return [self substringToIndex: 1];
}


-(int) lastIndexOf:(NSString *)lastIndexOf {
	
	
	NSRange range = [self rangeOfString:lastIndexOf options:NSBackwardsSearch];
	
	return range.location;
	
	
}




-(BOOL)startsWith:(NSString *)prefix {
	
	
	return [self hasPrefix:prefix];
}

-(BOOL)endsWith:(NSString *)suffix {
	
	
	return [self hasSuffix:suffix];
}

 



+ (NSString *)stringWithStrings:(NSString*) first, ... 
{
    va_list args;
    va_start(args, first);
	
    NSString * value = first;
    NSMutableString * result = [NSMutableString string];
    
    while (value != nil){
        [result appendString: value];
        value = va_arg(args,id);
    }
	
    va_end(args);
    
    return result;
	
}

- (NSString *)stringByAppendingStrings:(NSString*) first, ... 
{
    va_list args;
    va_start(args, first);
	
    NSString *value = nil;
    NSMutableString * result = [NSMutableString stringWithString: self];
	
    while (value != nil){
        [result appendString: value];
        value = va_arg(args,id);
    }
	
    va_end(args);
    
    return result;
}

- (NSString *)obscuredString
{
    NSMutableString * result = [NSMutableString stringWithCapacity: [self length]];
    for (int ii = 0; ii < [self length]; ii++)
        [result appendString:@"•"];
    return result;
}

-(NSString *)encryptedString
{
	const char *_string = [self cStringUsingEncoding:NSASCIIStringEncoding];
	int stringLength = [self length];
	char newString[stringLength+1];
	
	int x;
	for( x=0; x<stringLength; x++ )
	{
		unsigned int aCharacter = _string[x];
        newString[x] = ((aCharacter - 13) + 255) % 255;
    }
	
	newString[x] = '\0';
	return [NSString stringWithCString:newString encoding:NSASCIIStringEncoding];
}

-(NSString *)decryptedString
{
	const char *_string = [self cStringUsingEncoding:NSASCIIStringEncoding];
	int stringLength = [self length];
	char newString[stringLength+1];
	
	int x;
	for( x=0; x<stringLength; x++ )
	{
		unsigned int aCharacter = _string[x];
        newString[x] = (aCharacter + 13) % 255;
	}
	
	newString[x] = '\0';
	return [NSString stringWithCString:newString encoding:NSASCIIStringEncoding];
}

- (NSString*)valueOfURLParameter:(NSString*)paramName
{
    NSRange range = [self rangeOfString:[NSString stringWithFormat: @"%@=", paramName]];
    
    int valueStart = range.location + range.length;
    int valueEnd = [self length];
    
    NSRange endRange = [self rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString:@"?&\n\r "]
											 options:NSCaseInsensitiveSearch range:NSMakeRange(valueStart, [self length] - valueStart)];
    if (endRange.location != NSNotFound)
        valueEnd = endRange.location;
	
    if ([self length] >= valueEnd)
        return [self substringWithRange:NSMakeRange(valueStart, valueEnd - valueStart)];
    else
        return nil;
	
}

- (NSString *)stringWithTenDigitPhoneWith:(NSString*)leadingDigits
{
    NSString * fixed = [self stringByReplacingOccurrencesOfString:@"-" withString:@""];
    if ([fixed length] < 10)
        fixed = [NSString stringWithFormat:@"%@%@",[leadingDigits substringToIndex: (10-[fixed length])], fixed];
    return fixed;
}

@end
