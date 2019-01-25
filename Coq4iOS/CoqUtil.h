//
//  CoqUtil.h
//  Coq4iOS
//
//  Created by 後藤宗一朗 on 2018/11/05.
//  Copyright © 2018年 後藤宗一朗. All rights reserved.
//

#ifndef CoqUtil_h
#define CoqUtil_h
#import <UIKit/UIKit.h>

void startCoq(void);
void readStdout(void (^cb)(NSString*));
void eval(NSString* str, void (^cb)(BOOL, NSString*));

#endif /* CoqUtil_h */
