//
//  AssetCachePlugin.h
//  Forms
//
//  Created by Vincent Rifa on 27/03/2019.
//  Copyright © 2019 Kristal. All rights reserved.
//

#import <Cobalt/CobaltAbstractPlugin.h>


@interface AssetCachePlugin : CobaltAbstractPlugin <NSURLSessionDownloadDelegate>{
    CobaltViewController * _viewController;
    NSString *_callback;
}

@end
