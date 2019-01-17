//
//  MMNetWorking.h
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/13.
//  Copyright © 2019 Insomnia. All rights reserved.
//
#import "MMNetWorking.h"
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import "MMAppDotNetAPIClient.h"

#import "MMServerConfig.h"


/*!
 * baseUrl
 */
static NSString *MM_privateNetworkBaseUrl = nil;

/*!
 * 是否打印接口信息
 */
static BOOL MM_isEnableInterfaceDebug = false;

/*!
 * 是否自动转换url里的中文
 */
static BOOL MM_shouldAutoEncode = false;

/*!
 * 请求头, 默认为空
 */
static NSDictionary *MM_httpHeaders = nil;

/*!
 * 设置默认返回数据类型
 */
static MMResponseType MM_responseType = kMMResponseTypeData;

/*!
 * 请求数据类型
 */
static MMRequestType MM_requestType = kMMRequestTypePlainText;

/*!
 * 检测网络状态
 */
static MMNetworkStatus MM_networkStatus = kMMNetworkStatusUnknown;

/*!
 * 保存所有网络请求的状态
 */
static NSMutableArray *MM_requestTasks;

/*!
 * 默认get, post 不缓存
 */
static BOOL MM_cacheGet  = false;
static BOOL MM_cachePost = false;

/*!
 * 是否开启取消请求
 */
static BOOL MM_shouldCallbackOnCancelRequest = true;

/*!
 * 请求的超时时间
 */
static NSTimeInterval MM_timeout = 25.0f;

/*!
 * 无法连接时, 是否从本地读取数据
 */
static BOOL MM_shouldObtainLocalWhenUnconnected = false;

/*!
 * 基础url是否更改, 默认为true
 */
static BOOL MM_isBaseURLChanged = true;

/*!
 * 请求单例
 */
static MMAppDotNetAPIClient *MM_sharedManager = nil;

@implementation MMNetWroking

+ (void)updateBaseUrl:(NSString *)baseUrl {
    if ([baseUrl isEqualToString:MM_privateNetworkBaseUrl] && baseUrl && baseUrl.length) {
       MM_isBaseURLChanged = true;
    } else {
        MM_isBaseURLChanged = false;
    }
    MM_privateNetworkBaseUrl = baseUrl;
}

+ (NSString *)baseUrl {
    return MM_privateNetworkBaseUrl;
}

+ (void)cacheGetRequest:(BOOL)isCacheGet shouldCachePost:(BOOL)shouldCachePost {
    MM_cacheGet = isCacheGet;
    MM_cachePost = shouldCachePost;
}

+ (void)setTimeout:(NSTimeInterval)timeout {
    MM_timeout = timeout;
}

+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObatin {
    MM_shouldObtainLocalWhenUnconnected = shouldObatin;
}

+ (void)enableInterfaceDebug:(BOOL)isDebug {
    MM_isEnableInterfaceDebug = isDebug;
}

+ (BOOL)isDebug {
    return MM_isEnableInterfaceDebug;
}

static inline NSString *cachePath() {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/MMNetworkingCaches"];
}

+ (void)clearCaches {
    NSString *directoryPath = cachePath();
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
        if (error) {
            NSLog(@"MMNetworking clear caches error: %@", error);
        } else {
            NSLog(@"MMNetworking clear caches bingo.");
        }
    }
}

+ (unsigned long long)totalCacheSize {
    NSString           *directoryPath = cachePath();
    BOOL               isDir          = false;
    unsigned long long total          = 0;

    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (isDir) {
            NSError *err   = nil;
            NSArray *array = [[NSFileManager defaultManager]
                    contentsOfDirectoryAtPath:directoryPath error:&err];

            if (!err) {
                for (NSString *subPath in array) {
                    NSString     *path = [directoryPath stringByAppendingPathComponent:subPath];
                    NSDictionary *dict = [[NSFileManager defaultManager]
                            attributesOfItemAtPath:path
                                             error:&err];
                    if (!err) {
                        total += [dict[NSFileSize] unsignedIntegerValue];
                    }
                }
            }
        }
    }
    return total;
}

+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!MM_requestTasks) {
            MM_requestTasks = [NSMutableArray new];
        }
    });
    return MM_requestTasks;
}

+ (void)cancelAllRequest {
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(MMURLSessionTask *_Nonnull task, NSUInteger idx, BOOL *stop) {
            if ([task isKindOfClass:[MMURLSessionTask class]]) {
                [task cancel];
            }
        }];
        [[self allTasks] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)url {
    if (!url) {
        return;
    }

    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(MMURLSessionTask *task, NSUInteger idx, BOOL *stop) {
            if ([task isKindOfClass:[MMURLSessionTask class]] && [task.currentRequest.URL.absoluteString hasSuffix:url]) {
                [task cancel];
                [[self allTasks] removeObject:task];
                return;
            }
        }];
    }
}

+ (void)configRequestType:(MMRequestType)requestType
             responseType:(MMResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest {
    MM_requestType = requestType;
    MM_responseType = responseType;
    MM_shouldAutoEncode = shouldAutoEncode;
    MM_shouldCallbackOnCancelRequest = shouldCallbackOnCancelRequest;
}

+ (BOOL)shouldEncode {
    return MM_shouldAutoEncode;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
    MM_httpHeaders = httpHeaders;
}

//+ (MMURLSessionTask *)getWithUrl:(NSString *)url
//                    refreshCache:(BOOL)refreshCache
//                         success:(MMResponseSuccess)success
//                            fail:(MMResponseFail)fail {
//}

+ (MMURLSessionTask *)MM_requestWithUrl:(NSString *)url
                           refreshCache:(BOOL)refreshCache
                              isShowHUD:(BOOL)isShowHud
                                shoeHUD:(NSString *)statusText
                              httpMedth:(NSUInteger)httpMethod
                                 params:(NSDictionary *)params
                               progress:(MMDownloadProgress)progress
                                success:(MMResponseSuccess)success
                                   fail:(MMResponseFail)fail {
    if (url) {
        if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
        } else {
            NSString *serverAddress = [MMServerConfig getMMServerAddr];
        }
    } else {
        return nil;
    }

    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }

    MMAppDotNetAPIClient *manager = [self manager];
    NSString *absolute = [self absoluteUrlWithPath:url];
    
    MMURLSessionTask *session = nil;
    
    if (isShowHud) {
        [MMNetWroking showH]
    }
}

+ (NSString *)encodeUrl:(NSString *)url {
    return [self MM_URLEncode:url];
}

+ (NSString *)MM_URLEncode:(NSString *)url {
    if ([url respondsToSelector:@selector(stringByAddingPercentEncodingWithAllowedCharacters:)]) {
        static NSString *const kAFCharacterHTeneralDelimitersToEncode = @":#[]@";
        static NSString *const kAFCharactersSubDelimitersToEncode     = @"!$&'()*+,;=";

        NSMutableCharacterSet *allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
        [allowedCharacterSet removeCharactersInString:[kAFCharacterHTeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
        static NSUInteger const batchSize = 50;

        NSUInteger      index    = 0;
        NSMutableString *escaped = @"".mutableCopy;

        while (index < url.length) {
            NSUInteger length = MIN(url.length - index, batchSize);
            NSRange range = NSMakeRange(index, length);
            range = [url rangeOfComposedCharacterSequencesForRange:range];
            NSString *substring = [url substringWithRange:range];
            NSString *encoded   = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
            [escaped appendString:encoded];

            index += range.length;
        }
        return escaped;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding);
        NSString         *encoded   = (__bridge_transfer NSString *)
                CFURLCreateStringByAddingPercentEscapes(
                        kCFAllocatorDefault,
                        (__bridge CFStringRef) url,
                        NULL,
                        CFSTR("!#$&'()*+,/:;=?@[]"),
                        cfEncoding);
        return encoded;
#pragma clang diagnostic pop
    }
}

#pragma mark - Private
+ (MMAppDotNetAPIClient *)manager {
    @synchronized (self) {
        if (!MM_sharedManager || MM_isBaseURLChanged) {
            // 开启转菊花
            [AFNetworkActivityIndicatorManager sharedManager].enabled = true;
            
            MMAppDotNetAPIClient *manager = nil;
            if ([self baseUrl]) {
                manager = [[MMAppDotNetAPIClient sharedClient] initWithBaseURL:[NSURL URLWithString:[self baseUrl]]];
            } else {
                manager = [MMAppDotNetAPIClient sharedClient];
            }
            
            switch (MM_requestType) {
                case kMMRequestTypeJSON:{
                    manager.requestSerializer = [AFJSONRequestSerializer serializer];
                    break;
                }
                    
                case kMMRequestTypePlainText: {
                    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
                    break;
                }
                default:
                    break;
            }
            
            switch (MM_responseType) {
                case kMMResponseTypeJSON: {
                    manager.responseSerializer = [AFJSONResponseSerializer serializer];
                    break;
                }
                case kMMResponseTypeXML: {
                    manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
                    break;
                }
                case kMMResponseTypeData: {
                    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                    break;
                }
                default:
                    break;
            }
            
            manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
            
            for (NSString *key in MM_httpHeaders.allKeys) {
                if (MM_httpHeaders[key]) {
                    [manager.requestSerializer setValue:MM_httpHeaders[key]
                                     forHTTPHeaderField:key];
                }
            }
            
            // 设置cookie

            manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[
                    @"application/json",
                    @"text/html",
                    @"text/json",
                    @"text/plain",
                    @"text/javascript",
                    @"text/xml",
                    @"image/*"
                    ]];

            manager.requestSerializer.timeoutInterval = MM_timeout;
            manager.operationQueue.maxConcurrentOperationCount = 3;
            MM_sharedManager = manager;
        }
    }

    return MM_sharedManager;
}

+ (NSString *)absoluteUrlWithPath:(NSString *)path {
    if (!path || path.length == 0) {
        return @"";
    }
    
    if (![self baseUrl] || [self baseUrl].length == 0) {
        return path;
    }
    
    NSString *absoluteUrl = path;
    
    if (![path hasPrefix:@"http://"] && ![path hasPrefix:@"https://"]) {
        if ([[self baseUrl] hasSuffix:@"/"]) {
            if ([path hasPrefix:@"/"]) {
                NSMutableString *mPath = [NSMutableString stringWithString:path];
                [mPath deleteCharactersInRange:NSMakeRange(0, 1)];
                absoluteUrl = [NSString stringWithFormat:@"%@%@",
                               [self baseUrl],
                               mPath];
            } else {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",
                               [self baseUrl],
                               path];
            }
        } else {
            if ([path hasPrefix:@"/"]) {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",
                               [self baseUrl],
                               path];
            } else {
                absoluteUrl = [NSString stringWithFormat:@"%@%@",
                               [self baseUrl],
                               path];
            }
        }
    }
    return absoluteUrl;
}
@end














