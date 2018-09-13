//
//  wrapModels.h
//  Merops
//
//  Created by sho sumioka on 2018/08/29.
//  Copyright © 2018 sho sumioka. All rights reserved.
//

#ifndef wrapModels_h
#define wrapModels_h

@interface ScriptEngine : NSObject
{
    int val;
    id obj;
}

+ (void)classMethod:(id)arg;  // クラスメソッド
- (id)method:(NSObject*)arg1 with:(int)arg2;  // インスタンスメソッド。arg1は型付き
@end

#endif /* wrapModels_h */
