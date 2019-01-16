//
//  CoreModel.m
//  Merops
//
//  Created by sho sumioka on 2019/01/09.
//  Copyright © 2019 sho sumioka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreModel.h"

@implementation CoreModel

-(id)init
{
    self = [super init];
    self.Id = 12345;
    self.transform = 0;
    return self;
}

- (void)SetAttr:(id)attr
{
    self.attr = attr;
    [self _Update];
}

- (void)SetName:(NSString *)name
{
    self.name = name;
    [self _Update];
}

-(id)Create:(NSString *)name
{
    return self;
}

-(void)Delete
{
    
}

-(id)Copy
{
    return self;
}

-(id)Select:(NSString *)name
{
    return [self Copy];
}

- (void)_Update
{

}

-(id)Import
{
    return self;
}

-(NSString *)Export
{
    return self.name;
}

-(void)Hide
{
    
}

-(void)Lock{
    
}

@end
