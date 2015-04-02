//
//  SettingsManager.m
//  PreopEval
//
//  Created by Chris Hardin on 2/9/11.
//  Copyright 2011 Dapper Dapple Mobile LLC. All rights reserved.
//

#import "SettingsManager.h"
#import "config.h"
#import "CinchJSONAPIClient.h"

static SettingsManager *sharedInstance;


@implementation SettingsManager


#pragma mark Singleton Implementation

+ (SettingsManager *)sharedManager {
    @synchronized (self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized (self) {
        if (sharedInstance == nil) {
            sharedInstance = (SettingsManager *) [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}


- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}


#pragma mark -
#pragma mark Description Override

- (NSString *)description {
    return @"SettingsManager";
}


- (void)processDefaults {
    NSString *mainBundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *settingsPropertyListPath = [mainBundlePath stringByAppendingPathComponent:@"Settings.bundle/Root.plist"];
    NSDictionary *settingsPropertyList = [NSDictionary dictionaryWithContentsOfFile:settingsPropertyListPath];
    NSMutableArray *preferenceArray = settingsPropertyList[@"PreferenceSpecifiers"];
    NSMutableDictionary *registerableDictionary = [NSMutableDictionary dictionary];
    for (int i = 0; i < [preferenceArray count]; i++) {
        NSString *key = [preferenceArray[(NSUInteger) i] objectForKey:@"Key"];
        if (key) {
            id value = [preferenceArray[(NSUInteger) i] objectForKey:@"DefaultValue"];
            registerableDictionary[key] = value;
        }
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:registerableDictionary];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


//This is Necessary if you want Settings to be initialized on First launch of the app
- (void)initialize {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:ServerSetting])
        [self processDefaults];
}


- (void)setServerUrl:(NSString *)serverUrl{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *beforeValue = [defaults stringForKey:ServerSetting];
    [defaults setValue:serverUrl forKey:ServerSetting];
    [defaults synchronize]; //todo sg do we really need to call it?
    if(![beforeValue isEqualToString:serverUrl]){
        [[CinchJSONAPIClient sharedInstance] reload];
        [[CinchJSONAPIClient sharedInstanceWithJSONRequestSerialization] reload];
    }
}

- (void)setHostId:(NSString *)hostId{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:hostId forKey:HostIdSetting];
    [defaults synchronize];
}

- (void)setCode:(NSString *)code{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:code forKey:CodeSetting];
    [defaults synchronize];
}

- (void)setShowId:(NSNumber *)showId{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[showId stringValue] forKey:ShowIdSetting];
    [defaults synchronize];
}

- (NSInteger)getShowIdInteger{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:ShowIdSetting];
}
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
- (NSNumber *)getShowIdNumber{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *string = [defaults stringForKey:ShowIdSetting];
    if([string length] > 0){
     return @([self getShowIdInteger]);
    }
    return nil;
}
#pragma clang diagnostic pop
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"
- (NSString *)getShowIdString{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:ShowIdSetting];
}
#pragma clang diagnostic pop
- (NSString *)getServerUrl{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:ServerSetting];
}

- (NSString *)getCode{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults stringForKey:CodeSetting];
}

@end
