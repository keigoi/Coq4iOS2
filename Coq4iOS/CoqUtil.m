//
//  CoqUtil.m
//  Coq4iOS
//

#import <Foundation/Foundation.h>
#import "CoqUtil.h"
#import "LZMASDK/LZMAExtractor.h"
#import "Worker.h"
#include <libgen.h> // dirname

#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/config.h>
#include <caml/misc.h>
#include <caml/mlvalues.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/threads.h>

#undef alloc

static Worker* worker;

/**
 * backstack (i.e. "undo" stack) of evaluation
 */
@interface BackInfo : NSObject
// status string of that time
@property(strong,nonatomic) NSString* status;
// range of the added line(s) in console
@property(assign, nonatomic) NSRange range;
+ (BackInfo*)range:(NSRange)range status:(NSString*)status;
@end

@implementation BackInfo
+ (BackInfo*)range:(NSRange)range status:(NSString*)status
{
    BackInfo* me = [[BackInfo alloc] init];
    me.range = range;
    me.status = status;
    return me;
}
@end

static NSMutableArray* backStack;

static NSString* coqRoot() {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSCachesDirectory
                                             inDomains:NSUserDomainMask];
    if ([possibleURLs count] < 1) {
        @throw @"no cache directory found";
    }
    
    NSURL* cachesUrl = [possibleURLs objectAtIndex:0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString* dir = [[cachesUrl URLByAppendingPathComponent:appBundleID] path];
    
    return [dir stringByAppendingPathComponent:@"coq-8.8.2"];
}

static void startCoqBody() {
    [worker enqueue:^{
        CAMLparam0();
        CAMLlocal1(res);
        NSString* coqroot = coqRoot();
        const char* path = [coqroot cStringUsingEncoding:NSASCIIStringEncoding];
        
        value* startFunc = caml_named_value("start");
        res = caml_callback(*startFunc, caml_copy_string(path));
        
        //BOOL result = Bool_val(res);
        CAMLreturn0;
    }];
}

void startCoq() {
    backStack = [[NSMutableArray alloc] init];
    worker = [[Worker alloc] init];
    [worker start];
    
    [worker enqueue:^{
        NSLog(@"startRuntime");
        const char* argv[] = {
            "coqlib",
            0
        };
        caml_main((char**)argv);
        NSLog(@"startRuntime done");
    }];
    
    [worker enqueue:^{
        NSString* archivePath =
            [[NSBundle mainBundle]
             pathForResource:@"coq-8.8.2-standard-libs-for-coq4ios.7z"
             ofType:nil
             inDirectory:@"."];
        
        NSString* coqRootPath = coqRoot();
        
        
        [LZMAExtractor
            extract7zArchive:archivePath
            dirName:coqRootPath
            preserveDir:TRUE];

    }];

    startCoqBody();
}

void readStdout(void (^cb)(NSString*)) {
    [worker enqueue:^{
        CAMLparam0();
        CAMLlocal1(res);
        
        value* func = caml_named_value("read_stdout");
        res = caml_callback(*func, Val_unit);
        
        const char* cmsg = String_val(res);
        NSString* msg = [NSString stringWithUTF8String:cmsg];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cb(msg);
        });
        CAMLreturn0;
    }];
}

NSInteger lastPos(void)
{
    NSRange lastRange = {.location=0, .length=0};
    lastRange = backStack.count>0 ? ((BackInfo*)backStack.lastObject).range : lastRange;
    NSUInteger pos = lastRange.location + lastRange.length;
    return (NSInteger)pos;
}

NSRange nextPhraseRangeRaw(NSString* text)
{
    CAMLparam0();
    CAMLlocal1(retval_);
    __block const char* text_ = [text UTF8String];
   
    retval_ = caml_callback(*caml_named_value("next_phranse_range"), caml_copy_string(text_));
    int start = Int_val(Field(retval_, 0)),
        end = Int_val(Field(retval_, 1));
    
    NSRange range = {.location=start, .length=(end-start)};
    CAMLreturnT(NSRange, range);
}

void nextPhraseRange(NSString* text, void (^cb)(NSRange))
{
    [worker enqueue:^{
        NSRange range = nextPhraseRangeRaw(text);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cb(range);
        });
    }];
}

/**
 * Evaluate the string str in Coq runtime.
 * To correctly track the backstack, the string `str` should be at the point right after the last evaluated range in the buffer.
 */
void eval(NSString* str, void (^cb)(BOOL, NSString*)) {
    
    [worker enqueue:^{
        CAMLparam0();
        CAMLlocal1(msg_raw);
        
        NSRange range = nextPhraseRangeRaw(str);
        if(-1==range.location) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cb(FALSE, @"Syntax error");
            });
            CAMLreturn0;
        }
        
        NSLog(@"eval:%@", str);
        const char* strln = [[str stringByAppendingString:@"\n"] UTF8String];
        msg_raw = caml_callback(*caml_named_value("eval"), caml_copy_string(strln));
        
        BOOL success = Int_val(Field(msg_raw, 0));
        NSString* msg = [NSString stringWithUTF8String:String_val(Field(msg_raw, 1))];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) { // 評価に成功していれば BackStack を追加する
                NSUInteger lastpos = lastPos();
                NSRange newRange = {.location=lastpos + range.location, .length=range.length};
                [backStack addObject:[BackInfo range:newRange status:msg]];
            }
            cb(success, msg);
        });
        NSLog(@"eval done");
        CAMLreturn0;
    }];
}

void back()
{
    if(backStack.count>0) {
        [backStack removeLastObject];
        [worker enqueue:^{
            CAMLparam0();
            CAMLlocal1(extra_raw);
            extra_raw = caml_callback(*caml_named_value("rewind"), Val_int(1));
            int extra = Int_val(extra_raw);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // if Coq rewinds more than one, remove more from the stack
                NSRange range = {.location=backStack.count-extra, .length=extra};
                if(range.length>0) {
                    [backStack removeObjectsInRange:range];
                }
            });
            CAMLreturn0;
        }];
    }
}
