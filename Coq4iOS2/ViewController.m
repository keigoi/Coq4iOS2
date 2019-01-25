//
//  ViewController.m
//  Coq4iOS2
//
//  Created by keigoi on 2018/10/24.
//  Copyright © 2018 keigoi. All rights reserved.
//

#import "ViewController.h"
#import "CQWrapper.h"
#import "CQUtil.h"
#import "LZMASDK/LZMAExtractor.h"
#import "dup.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)startCoqAt:(NSString*)coqroot
{
    // [CQWrapper setDelegate:self];
    // self.status.text = @"Initializing..";
    [CQWrapper startRuntime];
    [CQWrapper startCoq:coqroot callback:^(BOOL result){
    }];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    //unix_pipe();
    // If stdlib does not exist in cache directory, expand it from the 7z archive
    NSString* coqroot = [[CQUtil cacheDir] stringByAppendingPathComponent:@"coq-8.8.2"];

    [CQWrapper runInQueue:^{
        
        [LZMAExtractor extract7zArchive:[CQUtil fullPathOf:@"coq-8.8.2-standard-libs-for-coq4ios.7z"] dirName:coqroot preserveDir:TRUE];
        
        // and start Coq
        dispatch_async(dispatch_get_main_queue(), ^{
            // self.status.text = [self.status.text stringByAppendingString:@"Done.\n"];
            [self startCoqAt:coqroot];
        });
    }];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
