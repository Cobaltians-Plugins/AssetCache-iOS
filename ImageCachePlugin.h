//
//  ImageCachePlugin.h
//  Forms
//
//  Created by Vincent Rifa on 27/03/2019.
//  Copyright © 2019 Kristal. All rights reserved.
//

#import <Cobalt/CobaltAbstractPlugin.h>


@interface ImageCachePlugin : CobaltAbstractPlugin <NSURLSessionDownloadDelegate>{
    CobaltViewController * _viewController;
    NSString *_callback;
}

//@property (nonatomic, retain) NSString * callback;


@end
