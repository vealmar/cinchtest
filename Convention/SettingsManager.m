//
//  SettingsManager.m
//  PreopEval
//
//  Created by Chris Hardin on 2/9/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import "SettingsManager.h"
#import "StringManipulation.h"
#import "config.h"

static SettingsManager *sharedInstance;


@implementation SettingsManager
 

#pragma mark Singleton Implementation

+ (SettingsManager*)sharedManager
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}



- (id)init
{
    if (self = [super init])
    {
		[self initialize];
    }
    return self;
}
 
 

#pragma mark -
#pragma mark Description Override

- (NSString *)description {
	return @"SettingsManager";
}



-(void)processDefaults{
	
	NSString  *mainBundlePath = [[NSBundle mainBundle] bundlePath];
	NSString  *settingsPropertyListPath = [mainBundlePath
										   stringByAppendingPathComponent:@"Settings.bundle/Root.plist"];
	
	NSDictionary *settingsPropertyList = [NSDictionary 
										  dictionaryWithContentsOfFile:settingsPropertyListPath];
	
	NSMutableArray      *preferenceArray = [settingsPropertyList objectForKey:@"PreferenceSpecifiers"];
	NSMutableDictionary *registerableDictionary = [NSMutableDictionary dictionary];
	
	for (int i = 0; i < [preferenceArray count]; i++)  { 
		NSString  *key = [[preferenceArray objectAtIndex:i] objectForKey:@"Key"];
		
		if (key)  {
			id  value = [[preferenceArray objectAtIndex:i] objectForKey:@"DefaultValue"];
			[registerableDictionary setObject:value forKey:key];
		}
	}
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:registerableDictionary]; 
	[[NSUserDefaults standardUserDefaults] synchronize];  
}





//This is Necessary if you want Settings to be initialized on First launch of the app
- (void)initialize
{
	 if (![[NSUserDefaults standardUserDefaults] objectForKey:@"username"] || ![[NSUserDefaults standardUserDefaults] objectForKey:SERVER])
		[self processDefaults];

 
}

 


-(id)lookupSettingByString: (NSString *)setting {
	
	
 
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:setting];
 
	
}

-(bool)boolForKey: (NSString *)setting {
	
	
	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:setting];
	
	
}




 
-(void)updateSetting: (NSString *)setting value:(NSString*)value {
	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setValue:value forKey:setting];
	
	[self refresh];
	

}


-(void)saveSetting: (NSString *)setting value:(id)value {
	
	
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setValue:value forKey:setting];
	[defaults synchronize];
 
	
}



-(id)retrieveSetting: (NSString *)setting  {
	
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults objectForKey:setting];
	
	
	
	
}


 

-(void)refresh{
	
	
	
	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults synchronize];
	
	
}


 



@end
