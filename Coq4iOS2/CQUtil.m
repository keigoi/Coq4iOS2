//
//  CQUtil.m
//  Coq4iPad
//
//  Created by Keigo IMAI on 2/4/13.
//  Copyright (c) 2013 Keigo IMAI. All rights reserved.
//

#import "CQUtil.h"
#include <sys/param.h>
#include <libgen.h>

#pragma mark private class UIAlertViewWithCallback implementation


#pragma mark CQUtil implementation

@implementation CQUtil

+(NSString*)dirnameOf:(NSString*)path
{
    char tmp[MAXPATHLEN];
    strcpy(tmp, [path UTF8String]);
    return [NSString stringWithUTF8String:dirname(tmp)];
}

+(NSString*)basenameOf:(NSString*)path
{
    char tmp[MAXPATHLEN];
    strcpy(tmp, [path UTF8String]);
    return [NSString stringWithUTF8String:basename(tmp)];
}


+(NSString*)fullPathOf:(NSString*)path
{
    if([path isAbsolutePath])
        return path;
    
    return [[NSBundle mainBundle] pathForResource:[self basenameOf:path] ofType:nil inDirectory:[self dirnameOf:path]];
}


+(NSString*)cacheDir
{
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSCachesDirectory
                                             inDomains:NSUserDomainMask];
    if ([possibleURLs count] < 1) {
        @throw @"no cache directory found";
    }
    
    NSURL* cachesUrl = [possibleURLs objectAtIndex:0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString* dir = [[cachesUrl URLByAppendingPathComponent:appBundleID] path];
    
    return dir;
}

// Returns the URL to the application's Documents directory.
+(NSString *)docDir
{
    NSURL* docUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [docUrl path];
}

+(void)runInMainThread:(void(^)(void))callback
{
    if(!callback) return;
    if([NSThread isMainThread]) {
        callback();
    } else {
        dispatch_async(dispatch_get_main_queue(), callback);
    }
}

+(void) showDialogWithMessage:(NSString*)message error:(NSError*)error callback:(void (^)(void))callback
{
    NSString* text =
    error == nil
    ? message
    : [NSString stringWithFormat:@"%@ (%@)", message, [error localizedDescription]];
    
    [self runInMainThread:^{
        // TODO なんかみせる
    }];
}

+(void) showDialogWithMessage:(NSString*)message error:(NSError*)error
{
    [self showDialogWithMessage:message error:error callback:nil];
}

+(void) showDialogWithMessage:(NSString*)message textboxWithString:(NSString*)text callback:(void(^)(NSString*))callback;
{
    [self runInMainThread:^{
        // TODO なんかみせる
    }];
}

@end
