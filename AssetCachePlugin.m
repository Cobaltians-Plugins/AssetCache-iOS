//
//  AssetCachePlugin.m
//  Forms
//
//  Created by Vincent Rifa on 27/03/2019.
//  Copyright © 2019 Kristal. All rights reserved.
//

#import "AssetCachePlugin.h"
#import "NSString+MD5.h"

#define BACKGROUND_URL_SESSION_ID   @"io.kristal.forms.backgroundURLSession"
#define TIMEOUT   5*60

@implementation AssetCachePlugin

- (id)init{
    if (self = [super init]) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:BACKGROUND_URL_SESSION_ID];
        [sessionConfig setTimeoutIntervalForResource:TIMEOUT];
        _session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                               delegate:self
                                                          delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (void)onMessageFromCobaltController:(CobaltViewController *)viewController andData: (NSDictionary *)message {
    
    _viewController = viewController;
    NSString *callback = [message objectForKey:kJSCallback];
    NSDictionary *data = [message objectForKey:kJSData];
    NSString *action = [message objectForKey:kJSAction];
    
    if (data != nil && [message isKindOfClass:[NSDictionary class]]) {
        NSString *assetUrl;
        NSString *assetPath;
        // Retrieving assets information
        if (data[@"url"]!=nil){
            assetUrl = [NSString stringWithString:data[@"url"]];
            
            // Retrieving Root Directory
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            
            NSString *fileName = [assetUrl MD5String];
            NSLog(@"DefaultViewController - %@ is MD5 convert as %@", assetUrl, fileName);
            assetPath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
        } else if (data[@"path"]!=nil) {
            assetPath = [NSString stringWithString:data[@"path"]];
        }
        
        if (action != nil && [action isEqualToString:@"download"]) {
            // Task creation and start
            NSURL *url = [NSURL URLWithString:assetUrl];
            NSURLSessionDownloadTask *task = [_session downloadTaskWithURL:url];
            task.taskDescription = callback;
            [task resume];
        } else if (action != nil && [action isEqualToString:@"delete"]) {
            NSError *error;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if([fileManager fileExistsAtPath:assetPath]){
                [fileManager removeItemAtPath:assetPath error:&error];
                if(error){
                    NSLog(@"DefaultViewController - Error, Cannot delete file : %@",error);
                    [_viewController sendCallback:callback withData:@{@"status":@"error", @"cause":@"unknownError"}];
                }
                else {
                    NSLog(@"DefaultViewController - Successfully removed file at %@",assetPath);
                    [_viewController sendCallback:callback withData:@{@"path":assetPath, @"status":@"success"}];
                }
            } else {
                NSLog(@"DefaultViewController - Error, file doesn't exists at %@",assetPath);
                [_viewController sendCallback:callback withData:@{@"status":@"error", @"cause":@"fileNotFound"}];
            }
        }
    }
}

    
////////////////////////////////////////////////////////////////////////////////////////////////
    
#pragma mark -
#pragma mark NSURLSESSION DELEGATE
    
////////////////////////////////////////////////////////////////////////////////////////////////
    
////////////////////////////////////////////////////////////////////////////////////////////////
    
#pragma mark Download
    
////////////////////////////////////////////////////////////////////////////////////////////////
/* Sent when a download task that has completed a download.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
 * still be called.
 */
    
//Called when downloadTask finish
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSString *callback = downloadTask.taskDescription;
    NSError *error;
    // Retrieving path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *url = [downloadTask.currentRequest URL].absoluteString;
    NSString *fileName = [url MD5String];
    NSString *path = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
   
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) [downloadTask response];
    if((long)[httpResponse statusCode] < 399){
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if([fileManager fileExistsAtPath:path]){
            NSLog(@"DefaultViewController - File already exists. Suppressing it... %@",path);
            [fileManager removeItemAtPath:path error:&error];
        }
        
        [fileManager copyItemAtPath:[location path] toPath:path error:&error];
        if(error){
            NSLog(@"DefaultViewController - Error during copy: %@",error);
            [_viewController sendCallback:callback withData:@{@"status":@"error", @"cause":@"writeError"}];
        }
        else {
            NSLog(@"DefaultViewController - Download completed at %@",path);
            [_viewController sendCallback:callback withData:@{@"path":path, @"status":@"success"}];
        }
    }
}
    
//Called during downloadTask progress
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten  totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
{
    NSString *callback = downloadTask.taskDescription;
    NSString *percentage = [NSString stringWithFormat:@"%.f%%", (((float) totalBytesWritten / (float) totalBytesExpectedToWrite) * 100)];
    [_viewController sendCallback:callback withData:@{@"status":@"downloading", @"progress":percentage}];
}
    
//Called when downloadTask complete with error
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask didCompleteWithError:(NSError *)error;
{
    NSString *callback = downloadTask.taskDescription;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) [downloadTask response];
    NSLog(@"DefaultViewController - DownloadTask ends with server response: %ld",(long)[httpResponse statusCode]);
    if((long)[httpResponse statusCode] == 404){
        [_viewController sendCallback:callback withData:@{@"status":@"error", @"cause":@"fileNotFound"}];
    } else {
        if(error!=nil){
            NSLog(@"DefaultViewController - Error during download! %@",error);
            [_viewController sendCallback:callback withData:@{@"status":@"error", @"cause":@"networkError"}];
        }
    }
}

@end
