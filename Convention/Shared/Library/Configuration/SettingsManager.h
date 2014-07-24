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

-(id)lookupSettingByString: (NSString *)setting;
 
-(void)refresh;
-(void)processDefaults;
-(void)updateSetting: (NSString *)setting value:(NSString*)value;

-(void)saveSetting: (NSString *)setting value:(id)value;
-(id)retrieveSetting: (NSString *)setting;

-(bool)boolForKey: (NSString *)setting;

 
@end
