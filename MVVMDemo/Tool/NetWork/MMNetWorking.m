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
#import "MMShowMessageView.h"


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

+ (void)cacheGetRequest:(BOOL)isCacheGet shouldCachePost:(BOOL)shouldCachePost {
    MM_cacheGet  = isCacheGet;
    MM_cachePost = shouldCachePost;
}

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
    MM_requestType                   = requestType;
    MM_responseType                  = responseType;
    MM_shouldAutoEncode              = shouldAutoEncode;
    MM_shouldCallbackOnCancelRequest = shouldCallbackOnCancelRequest;
}

+ (BOOL)shouldEncode {
    return MM_shouldAutoEncode;
}

+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders {
    MM_httpHeaders = httpHeaders;
}

#pragma mark - Get Request

// 无进度回调, 无提示框
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:false
                           showHUD:nil
                        httpMethod:1
                            params:nil
                          progress:nil
                           success:success
                              fail:fail];
}

// 无进度条 有提示框
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         shoeHUD:(NSString *)statusText
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:true
                           showHUD:statusText
                        httpMethod:1
                            params:nil
                          progress:nil
                           success:success
                              fail:fail];
}

// 无进度条 无提示框
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                          params:(NSDictionary *)params
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:false
                           showHUD:nil
                        httpMethod:1
                            params:params
                          progress:nil
                           success:success
                              fail:fail];
}

// 无进度条 有提示框
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         showHUD:(NSString *)statusText
                          params:(NSDictionary *)params
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:true
                           showHUD:statusText
                        httpMethod:1
                            params:params
                          progress:nil
                           success:success
                              fail:fail];
}

// 有进度回调 无提示框
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                          params:(NSDictionary *)params
                        progress:(MMGetProgress)progress
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:false
                           showHUD:nil
                        httpMethod:1
                            params:params
                          progress:progress
                           success:success
                              fail:fail];
}

// 有进度回调 有提示框
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         showHUD:(NSString *)statusText
                          params:(NSDictionary *)params
                        progress:(MMGetProgress)progress
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:true
                           showHUD:statusText
                        httpMethod:1
                            params:params
                          progress:progress
                           success:success
                              fail:fail];
}

#pragma mark - Post Request

// 无进度回调 无提示框
+ (MMURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                          success:(MMResponseSuccess)success
                             fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:false
                           showHUD:nil
                        httpMethod:2
                            params:params
                          progress:nil
                           success:success
                              fail:fail];
}

// 无进度回调 有提示框
+ (MMURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          showHUD:(NSString *)statusText
                           params:(NSDictionary *)params
                          success:(MMResponseSuccess)success
                             fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:true
                           showHUD:statusText
                        httpMethod:2
                            params:params
                          progress:nil
                           success:success
                              fail:fail];
}

// 有进度回调 无提示框
+ (MMURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                         progress:(MMPostProgress)progress
                          success:(MMResponseSuccess)success
                             fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:false
                           showHUD:nil
                        httpMethod:2
                            params:params
                          progress:progress
                           success:success
                              fail:fail];
}

// 有进度回调 有提示框
+ (MMURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          showHUD:(NSString *)statusText
                           params:(NSDictionary *)params
                         progress:(MMPostProgress)progress
                          success:(MMResponseSuccess)success
                             fail:(MMResponseFail)fail {
    return [self MM_requestWithUrl:url
                      refreshCache:refreshCache
                         isShowHUD:true
                           showHUD:statusText
                        httpMethod:2
                            params:params
                          progress:progress
                           success:success
                              fail:fail];
}


+ (MMURLSessionTask *)MM_requestWithUrl:(NSString *)url
                           refreshCache:(BOOL)refreshCache
                              isShowHUD:(BOOL)isShowHud
                                showHUD:(NSString *)statusText
                             httpMethod:(NSUInteger)httpMethod
                                 params:(NSDictionary *)params
                               progress:(MMDownloadProgress)progress
                                success:(MMResponseSuccess)success
                                   fail:(MMResponseFail)fail {
    if (url) {
        if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) {
        } else {
            NSString *serverAddress = [MMServerConfig getMMServerAddr];
            url = [serverAddress stringByAppendingString:url];
        }
    } else {
        return nil;
    }

    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }

    MMAppDotNetAPIClient *manager  = [self manager];
    NSString             *absolute = [self absoluteUrlWithPath:url];

    MMURLSessionTask *session = nil;

    if (isShowHud) {
        [MMNetWroking showHUD:statusText];
    }

    if (httpMethod == 1) {
        if (MM_cacheGet) {
            if (MM_shouldObtainLocalWhenUnconnected) {
                // 无网时
                if (MM_networkStatus == kMMNetworkStatusNotReachable || MM_networkStatus == kMMNetworkStatusUnknown) {
                    id response = [MMNetWroking cacheResponseWithURL:absolute
                                                              params:params];
                    if (response) {
                        if (success) {
                            // 这里 block 也可以传递
                            [self successResponse:response
                                         callBack:success];

                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:url
                                                      params:params];
                            }
                        }
                    }
                    return nil;
                }
            }
        }

        // 不刷新缓存
        if (!refreshCache) {
            id response = [MMNetWroking cacheResponseWithURL:absolute
                                                      params:params];
            if (response) {
                if (success) {
                    [self successResponse:response callBack:success];

                    if ([self isDebug]) {
                        [self logWithSuccessResponse:response
                                                 url:absolute
                                              params:params];
                    }
                }
                return nil;
            }
        }

        session = [manager GET:url
                    parameters:params progress:^(NSProgress *_Nonnull downloadProgress) {
                    if (progress) {
                        progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                    }
                }      success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                    if (isShowHud) {
                        [MMNetWroking dismissSuccessHUD];
                    }

                    [[self allTasks] removeObject:task];

                    [self successResponse:responseObject callBack:success];

                    if (MM_cacheGet) {
                        [self cacheResponseObject:responseObject
                                          request:task.currentRequest
                                           params:params];
                    }

                    if ([self isDebug]) {
                        [self logWithSuccessResponse:responseObject
                                                 url:absolute
                                              params:params];
                    }
                }      failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
                    if (isShowHud) {
                        [MMNetWroking dismissErrorHUD];
                    }
                    [[self allTasks] removeObject:task];

                    if ([error code] < 0 && MM_cacheGet) {
                        id response = [MMNetWroking cacheResponseWithURL:absolute
                                                                  params:params];
                        if (response) {
                            if (success) {
                                [self successResponse:response callBack:success];

                                if ([self isDebug]) {
                                    [self logWithSuccessResponse:response
                                                             url:absolute
                                                          params:params];
                                }
                            }
                        } else {
                            [self handleCallbackWithError:error fail:fail];

                            if ([self isDebug]) {
                                [self logWithFailError:error url:absolute params:params];
                            }
                        }
                    } else {
                        [self handleCallbackWithError:error fail:fail];
                        if ([self isDebug]) {
                            [self logWithFailError:error url:absolute params:params];
                        }
                    }

                }];
    } else if (httpMethod == 2) {
        if (MM_cachePost) { // 获取缓存
            if (MM_shouldObtainLocalWhenUnconnected) {
                if (MM_networkStatus == kMMNetworkStatusNotReachable || MM_networkStatus == kMMNetworkStatusUnknown) {
                    id response = [MMNetWroking cacheResponseWithURL:absolute params:params];

                    if (response) {
                        if (success) {
                            [self successResponse:response callBack:success];

                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:absolute
                                                      params:params];
                            }
                        }
                        return nil;
                    }
                }
            }

            if (!refreshCache) {
                id response = [MMNetWroking cacheResponseWithURL:absolute
                                                          params:params];

                if (response) {
                    if (success) {
                        [self successResponse:response
                                     callBack:success];

                        if ([self isDebug]) {
                            [self logWithSuccessResponse:response
                                                     url:absolute
                                                  params:params];
                        }
                    }
                    return nil;
                }
            }
        }

        session = [manager POST:url parameters:params
                       progress:^(NSProgress *_Nonnull uploadProgress) {
                           if (progress) {
                               progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
                           }

                       } success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
                    if (isShowHud) {
                        [MMNetWroking dismissSuccessHUD];
                    }

                    [[self allTasks] removeObject:task];

                    [self successResponse:responseObject callBack:success];

                    if (MM_cachePost) {
                        [self cacheResponseObject:responseObject
                                          request:task.currentRequest
                                           params:params];
                    }

                    if ([self isDebug]) {
                        [self logWithSuccessResponse:responseObject
                                                 url:absolute
                                              params:params];
                    }
                }       failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {

                    if (isShowHud) {
                        [MMNetWroking dismissErrorHUD];
                    }

                    [[self allTasks] removeObject:task];
                    if ([error code] < 0 && MM_cachePost) {
                        id response = [MMNetWroking cacheResponseWithURL:absolute params:params];

                        if (response) {
                            if (success) {
                                [self successResponse:response callBack:success];

                                if ([self isDebug]) {
                                    [self logWithSuccessResponse:response
                                                             url:absolute
                                                          params:params];
                                }
                            }
                        } else {
                            [self handleCallbackWithError:error fail:fail];

                            if ([self isDebug]) {
                                [self logWithSuccessResponse:response
                                                         url:absolute
                                                      params:params];
                            }
                        }
                    } else {
                        [self handleCallbackWithError:error fail:fail];
                        if ([self isDebug]) {
                            [self logWithFailError:error
                                               url:absolute
                                            params:params];
                        }
                    }
                }];

    }

    if (session) {
        [[self allTasks] addObject:session];
    }

    return session;
}

+ (MMURLSessionTask *)uploadFileWithUrl:(NSString *)url
                          uploadingFile:(NSString *)uploadingFile
                               progress:(MMUploadProgress)progress
                                success:(MMResponseSuccess)success
                                   fail:(MMResponseFail)fail {
    if (![NSURL URLWithString:uploadingFile]) {
        return nil;
    }

    NSURL *uploadURL = nil;
    if ([self baseUrl] == nil) {
        uploadURL = [NSURL URLWithString:url];
    } else {
        uploadURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]];
    }

    if (!uploadURL) {
        return nil;
    }

    MMAppDotNetAPIClient *manager = [self manager];
    NSURLRequest         *request = [NSURLRequest requestWithURL:uploadURL];
    MMURLSessionTask     *session = nil;

    [manager uploadTaskWithStreamedRequest:request
                                  progress:^(NSProgress *_Nonnull uploadProgress) {
                                      if (progress) {
                                          progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
                                      }
                                  } completionHandler:^(NSURLResponse *_Nonnull response, id _Nullable responseObject, NSError *_Nullable error) {
                [[self allTasks] removeObject:session];
                [self successResponse:responseObject callBack:success];

                if (error) {
                    [self handleCallbackWithError:error fail:fail];

                    if ([self isDebug]) {
                        [self logWithFailError:error url:response.URL.absoluteString params:nil];
                    }
                } else {
                    if ([self isDebug]) {
                        [self logWithSuccessResponse:responseObject
                                                 url:response.URL.absoluteString
                                              params:nil];
                    }
                }

            }];

    if (session) {
        [[self allTasks] addObject:session];
    }

    return session;
}

+ (MMURLSessionTask *)uploadWithImage:(UIImage *)image url:(NSString *)url filename:(NSString *)filename name:(NSString *)name mimeType:(NSString *)mimeType parameters:(NSDictionary *)parameters progress:(MMUploadProgress)progress success:(MMResponseSuccess)success fail:(MMResponseFail)fail {

    if (![self baseUrl]) {
        if (![NSURL URLWithString:url]) {
            return nil;
        }
    } else {
        if (![NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]]) {
            return nil;
        }
    }

    if ([self shouldEncode]) {
        url = [self encodeUrl:url];
    }

    NSString *absolute = [self absoluteUrlWithPath:url];

    MMAppDotNetAPIClient *manager = [self manager];
    MMURLSessionTask     *session = [manager POST:url parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData> _Nonnull formData) {
        NSData   *imageData     = UIImageJPEGRepresentation(image, 1);
        NSString *imageFileName = filename;

        if (!filename || ![filename isKindOfClass:[NSString class]] || filename.length == 0) {
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateFormat = @"yyyyMMddHHmmss";
            NSString *str = [formatter stringFromDate:[NSDate date]];
            imageFileName = [NSString stringWithFormat:@"%@.jpg", str];
        }

        [formData appendPartWithFileData:imageData name:name
                                fileName:filename
                                mimeType:mimeType];
    }                                    progress:^(NSProgress *_Nonnull uploadProgress) {
        if (progress) {
            progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
        }
    }                                     success:^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        [[self allTasks] removeObject:task];
        [self successResponse:responseObject callBack:success];

        if ([self isDebug]) {
            [self logWithSuccessResponse:responseObject
                                     url:absolute
                                  params:parameters];
        }
    }                                     failure:^(NSURLSessionDataTask *_Nullable task, NSError *_Nonnull error) {
        [[self allTasks] removeObject:task];

        [self handleCallbackWithError:error
                                 fail:fail];
        if ([self isDebug]) {
            [self logWithFailError:error
                               url:absolute params:nil];
        }
    }];

    if (session) {
        [[self allTasks] addObject:session];
    }

    return session;
}

+ (MMURLSessionTask *)downloadWithUrl:(NSString *)url saveToPath:(NSString *)saveToPath progress:(MMDownloadProgress)progressBlock success:(MMResponseSuccess)success fail:(MMResponseFail)fail {
    if (![self baseUrl]) {
        if (![NSURL URLWithString:url]) {
            return nil;
        }
    } else {
        if ([NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseUrl], url]] == nil) {
            return nil;
        }
    }
    NSURLRequest         *downloadRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    MMAppDotNetAPIClient *manager         = [self manager];

    MMURLSessionTask *session = nil;
    session = [manager downloadTaskWithRequest:downloadRequest
                                      progress:^(NSProgress *downloadProgress) {
                                          if (progressBlock) {
                                              progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
                                          }
                                      } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                return [NSURL fileURLWithPath:saveToPath];
            }                completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                [[self allTasks] removeObject:session];

                if (error == nil) {
                    if (success) {
                        success(filePath.absoluteString);
                    }

                    if ([self isDebug]) {
                        NSLog(@"Download success for url %@",
                                [self absoluteUrlWithPath:url]);
                    }
                } else {
                    [self handleCallbackWithError:error fail:fail];

                    if ([self isDebug]) {
                        NSLog(@"Download fail for url %@, reason : %@",
                                [self absoluteUrlWithPath:url],
                                [error description]);
                    }
                }
            }];

    if (session) {
        [[self allTasks] addObject:session];
    }
    return session;
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
                case kMMRequestTypeJSON: {
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

            manager.requestSerializer.timeoutInterval          = MM_timeout;
            manager.operationQueue.maxConcurrentOperationCount = 3;
            MM_sharedManager = manager;
        }
    }

    return MM_sharedManager;
}


+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(NSDictionary *)params {
    NSLog(@"\n");
    NSLog(@"\nRequest success, URL: %@\n params:%@\n response:%@\n\n",
            [self generateGETAbsoluteURL:url params:params],
            params,
            [self tryToParseData:response]
    );
}

+ (void)logWithFailError:(NSError *)error url:(NSString *)url params:(id)params {
    NSString *format = @" params: ";
    if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
        format = @"";
        params = @"";
    }

    NSLog(@"\n");
    if ([error code] == NSURLErrorCancelled) {
        NSLog(@"\nRequest was canceled mannully, URL: %@ %@%@\n\n",
                [self generateGETAbsoluteURL:url params:params],
                format,
                params);
    } else {
        NSLog(@"\nRequest error, URL: %@ %@%@\n errorInfos:%@\n\n",
                [self generateGETAbsoluteURL:url params:params],
                format,
                params,
                [error localizedDescription]);
    }
}


+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(NSDictionary *)params {
    if (params == nil || ![params isKindOfClass:[NSDictionary class]] || params.count == 0) {
        return url;
    }

    NSString      *queries = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];

        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                                                 (queries.length == 0 ? @"&" : queries),
                                                 key,
                                                 value];
        }
    }

    if (queries.length > 1) {
        // 去&
        queries = [queries substringToIndex:queries.length - 1];
    }

    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
        if ([url rangeOfString:@"?"].location != NSNotFound ||
                [url rangeOfString:@"#"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@", url, queries];
        } else {
            queries = [queries substringFromIndex:1];
            url     = [NSString stringWithFormat:@"%@%@", url, queries];
        }
    }

    return url.length == 0 ? queries : url;
}

+ (NSString *)encodeUrl:(NSString *)url {
    return [self MM_URLEncode:url];
}

+ (id)tryToParseData:(id)json {
    if (!json || json == (id) kCFNull) return nil;
    NSDictionary *dic      = nil;
    NSData       *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *) json dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }

    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                              options:kNilOptions
                                                error:nil];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}

+ (void)successResponse:(id)responseData callBack:(MMResponseSuccess)success {
    if (success) {
        success([self tryToParseData:responseData]);
    }
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

+ (id)cacheResponseWithURL:(NSString *)url params:params {
    id cacheData = nil;
    if (url) {
        NSString *dirPath     = cachePath();
        NSString *absoluteURL = [self generateGETAbsoluteURL:url params:params];
        NSString *key         = [absoluteURL md5String];
        NSString *path        = [dirPath stringByAppendingPathComponent:key];

        NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
        if (data) {
            cacheData = data;
            NSLog(@"Read data from cache for url: %@\n", url);
        }
    }
    return cacheData;
}

+ (void)cacheResponseObject:(id)responseObject request:(NSURLRequest *)request params:params {
    if (request && responseObject && ![responseObject isKindOfClass:[NSNull class]]) {
        NSString *dirPath = cachePath();
        NSError  *error   = nil;
        if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath
                                                  isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                                      withIntermediateDirectories:true
                                                       attributes:nil
                                                            error:&error];

            if (error) {
                NSLog(@"Create cache dir error: %@\n", error);
                return;
            }
        }

        NSString     *absoluteURL = [self generateGETAbsoluteURL:request.URL.absoluteString params:params];
        NSString     *key         = [absoluteURL md5String];
        NSString     *path        = [dirPath stringByAppendingString:key];
        NSDictionary *dict        = (NSDictionary *) responseObject;
        NSData       *data        = nil;
        if ([dict isKindOfClass:[NSData class]]) {
            data = responseObject;
        } else {
            data = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        }
        if (data && error == nil) {
            BOOL isOk = [[NSFileManager defaultManager] createFileAtPath:path
                                                                contents:data
                                                              attributes:nil];
            if (isOk) {
                NSLog(@"cache file ok for request: %@\n", absoluteURL);
            } else {
                NSLog(@"cache file error for request: %@\n", absoluteURL);
            }
        }
    }
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












+ (void)handleCallbackWithError:(NSError *)error fail:(MMResponseFail)fail {
    if ([error code] == NSURLErrorCancelled) {
        if (MM_shouldCallbackOnCancelRequest) {
            if (fail) {
                fail(error);
            }
        }
    } else {
        if (fail) {
            fail(error);
        }
    }
}


#pragma mark - HUD

+ (void)showHUD:(NSString *)showMessage {
    dispatch_main_async_safe(^{
        [MMShowMessageView showStatusWithMessage:showMessage];
    });
}

+ (void)dismissSuccessHUD {
    dispatch_main_async_safe(^{
        [MMShowMessageView dismissSuccessView:@"Success"];
    });
}

+ (void)dismissErrorHUD {
    dispatch_main_async_safe(^{
        [MMShowMessageView dismissErrorView:@"Error"];
    });
}

#pragma mark Cookie

///其中存储cookie可能会有问题

+ (void)getAndSaveCookie:(NSURLSessionDataTask *)task andUrl:(NSString *)url {
    NSDictionary * *headers = [(NSHTTPURLResponse *)task.response allHeaderFields];

    NSArray *cookie = [NSHTTPCookie cookiesWithResponseHeaderFields:headers forURL:[NSURL URLWithString:url]];

    if (cookie && cookie.count != 0) {
        NSData * cookiesData = [NSKeyedArchiver archivedDataWithRootObject:[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]];

        if(!cookiesData){
            return;
        }
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:cookiesData forKey:@"UserCookie"];
        [ud synchronize];
    }
}

+ (void)deleteCookieWithLoginOut {
    NSData *cookieData = [NSData data];
    [[NSUserDefaults standardUserDefaults] dataForKey:@"UserCookie"];
    if(!cookiesData){
        return;
    }
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:cookiesData forKey:@"UserCookie"];
    [ud synchronize];

    NSHTTPCookieStorage * *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];

    for (NSHTTPCookie *tmpCookie in cookies) {
        [cookieStorage deleteCookie:tmpCookie];
    }
}

+ (void)setUpCookie {
    //取出保存的cookie
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //对取出的cookie进行反归档处理
    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:[userDefaults objectForKey:@"UserCookie"]];

    if (cookies && cookies.count != 0) {

        //设置cookie
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (id cookie in cookies) {
            [cookieStorage setCookie:(NSHTTPCookie *)cookie];
        }
    }
}


@end
