//
//  ImageCachePlugin.m
//  Forms
//
//  Created by Vincent Rifa on 27/03/2019.
//  Copyright © 2019 Kristal. All rights reserved.
//

#import "ImageCachePlugin.h"

#define BACKGROUND_URL_SESSION_ID   @"io.kristal.forms.backgroundURLSession"
#define TIMEOUT   5*60

@implementation ImageCachePlugin

- (void)onMessageFromCobaltController:(CobaltViewController *)viewController andData: (NSDictionary *)message {
    
    _viewController = viewController;
    _callback = [message objectForKey:kJSCallback];
    NSDictionary *data = [message objectForKey:kJSData];
    NSString *action = [message objectForKey:kJSAction];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:BACKGROUND_URL_SESSION_ID];
    [sessionConfig setTimeoutIntervalForResource:TIMEOUT];  
    NSURLSession *_session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                           delegate:self
                                                      delegateQueue:[NSOperationQueue mainQueue]];
/*    NSURLSession *_session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:BACKGROUND_URL_SESSION_ID]
                                             delegate:self
                                        delegateQueue:[NSOperationQueue mainQueue]];*/
    
    if (data != nil && [message isKindOfClass:[NSDictionary class]]) {
        if (action != nil && [action isEqualToString:@"download"]) {
            // Retrieving url and path from data
            NSURL *url = [NSURL URLWithString:data[@"url"]];
            NSString *path = [NSString stringWithString:data[@"path"]];
            
            // Task creation and start
            if (url != nil && path != nil) {
                NSURLSessionDownloadTask *task = [_session downloadTaskWithURL:url];
                task.taskDescription = path;
                [task resume];
            }
        } else if (action != nil && [action isEqualToString:@"delete"]) {
            NSError *error;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            // Retrieving url and path from data
            NSString *path = [NSString stringWithString:data[@"path"]];
            
            // Retrieving Root Directory
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            
            // Defining file path (Root + path)
            NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, path];
            if([fileManager fileExistsAtPath:filePath]){
                [fileManager removeItemAtPath:filePath error:&error];
                if(error){
                    NSLog(@"DefaultViewController - Error, Cannot delete file : %@",error);
                    [_viewController sendCallback:_callback withData:@{@"path":path, @"status":@"error", @"cause":@"unknownError"}];
                }
                else {
                    NSLog(@"DefaultViewController - Successfully removed file at %@",filePath);
                    [_viewController sendCallback:_callback withData:@{@"path":path, @"status":@"success"}];
                }
            } else {
                NSLog(@"DefaultViewController - Error, file doesn't exists at %@",filePath);
                [_viewController sendCallback:_callback withData:@{@"path":path, @"status":@"error", @"cause":@"fileNotFound"}];
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
    NSString *path = downloadTask.taskDescription;
    NSError *error;
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) [downloadTask response];
    if((long)[httpResponse statusCode] < 399){
        // Defining Root Directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        // Defining and creating local folders
        NSString *folders = [path stringByDeletingLastPathComponent];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![folders  isEqual: @""]){
            folders = [NSString stringWithFormat:@"%@/%@", documentsDirectory, folders];
            [fileManager createDirectoryAtPath:folders
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:nil];
        }
        
        // Defining local path
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, path];
        if([fileManager fileExistsAtPath:filePath]){
            NSLog(@"DefaultViewController - File already exists. Suppressing it... %@",filePath);
            [fileManager removeItemAtPath:filePath error:&error];
        }
        
        [fileManager copyItemAtPath:[location path] toPath:filePath error:&error];
        if(error){
            NSLog(@"DefaultViewController - Error during copy: %@",error);
            [_viewController sendCallback:_callback withData:@{@"path":path, @"status":@"error", @"cause":@"writeError"}];
        }
        else {
            NSLog(@"DefaultViewController - Download completed at %@",filePath);
            NSString *root = [NSString stringWithFormat:@"file://%@/",documentsDirectory];
            [_viewController sendCallback:_callback withData:@{@"path":path, @"root":root, @"status":@"success"}];
        }
    }
}
    
//Called during downloadTask progress
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten  totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
{
    NSString *path = downloadTask.taskDescription;
    NSString *percentage = [NSString stringWithFormat:@"%.f%%", (((float) totalBytesWritten / (float) totalBytesExpectedToWrite) * 100)];
    [_viewController sendCallback:_callback withData:@{@"path":path, @"status":@"downloading", @"progress":percentage}];
}
    
//Called when downloadTask complete with error
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask didCompleteWithError:(NSError *)error;
{
    NSString *path = downloadTask.taskDescription;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) [downloadTask response];
    NSLog(@"DefaultViewController - DownloadTask ends with server response: %ld",(long)[httpResponse statusCode]);
    if((long)[httpResponse statusCode] == 404){
        [_viewController sendCallback:_callback withData:@{@"path":path, @"status":@"error", @"cause":@"fileNotFound"}];
    } else {
        if(error!=nil){
            NSLog(@"DefaultViewController - Error during download! %@",error);
            [_viewController sendCallback:_callback withData:@{@"path":path, @"status":@"error", @"cause":@"networkError"}];
        }
    }
}

@end

