//
//  wrapModels.m
//  Merops
//
//  Created by sho sumioka on 2018/08/29.
//  Copyright © 2018 sho sumioka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "wrapModels.h"
#import "Merops-Swift.h"

@implementation ScriptEngine
+ (void)classMethod:(id)arg
{
    // some operation
}

- (id)method:(NSObject*)arg1 with:(int)args2
{
    return obj;
}

// 典型的なinit
- (id)init
{
    self = [super init]; // スーパークラスの呼びだし
    if (self != nil)
    {
        id overray = [GameViewOverlay alloc];
        val = 1;
//        obj = [[SomeClass alloc] init];
    }
    return self;
}

// deallocは自身のリソースを解放してからスーパークラスに回す
- (void)dealloc
{
//    [obj release];
//    [super dealloc];
}
@end
