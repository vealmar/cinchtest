//
//  DispatchMessage.h
//  iBoost
//
//  iBoost - The iOS Booster!
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>


@interface DispatchMessage : NSObject {
	NSString *_name;
	NSMutableDictionary *_userInfo;
	BOOL _asynchronous;
}

@property (unsafe_unretained, nonatomic, readonly) NSString *name;
@property (unsafe_unretained, nonatomic, readonly) NSMutableDictionary *userInfo;
@property (nonatomic, assign, getter=isAsynchronous) BOOL asynchronous;

- (id)initWithName:(NSString *)name userInfo:(NSDictionary *)userInfo;
+ (id)messageWithName:(NSString *)name userInfo:(NSDictionary *)userInfo;

- (NSString *)name;
- (NSDictionary *)userInfo;

- (void)inputData:(NSData *)input;
- (NSData *)outputData;

- (void)debug:(NSString *)message, ...;

@end
