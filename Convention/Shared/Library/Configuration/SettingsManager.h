//
//  SettingsManager.h
//  PreopEval
//
//  Created by Chris Hardin on 2/9/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 
 
 Very Important class in the system. This class is designed to be a central place where you can
 retrieve and store settings
 
 
 */

@interface SettingsManager : NSObject <UIAlertViewDelegate>{
	
 
	
}


 

#pragma mark Singleton
+ (SettingsManager*)sharedManager;
+ (id)allocWithZone:(NSZone *)zone;
- (id)copyWithZone:(NSZone *)zone;
 

- (id)init;
-(void)initialize;

- (NSInteger)getShowIdInteger;

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
- (NSNumber *)getShowIdNumber;
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
- (NSString *)getShowIdString;
#pragma clang diagnostic pop

- (NSString *)getServerUrl;

- (NSString *)getCode;

-(void)processDefaults;

- (void)setServerUrl:(NSString *)serverUrl;

- (void)setHostId:(NSString *)hostId;

- (void)setCode:(NSString *)code;

- (void)setShowId:(NSNumber *)showId;


@end
