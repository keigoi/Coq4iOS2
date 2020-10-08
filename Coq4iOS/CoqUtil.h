//
//  CoqUtil.h
//  Coq4iOS

#ifndef CoqUtil_h
#define CoqUtil_h
#import <UIKit/UIKit.h>

void startCoq(void);
void readStdout(void (^cb)(NSString*));
void eval(NSString* str, void (^cb)(BOOL, NSString*));
void nextPhraseRange(NSString* text, void (^cb)(NSRange));
NSInteger lastPos(void);
void back(void);

#endif /* CoqUtil_h */
