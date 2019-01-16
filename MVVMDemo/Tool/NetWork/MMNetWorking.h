//
//  MMNetWorking.h
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/13.
//  Copyright © 2019 Insomnia. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * 下载进度
 *
 * @param bytesRead 已下载大小
 * @param totalBytesRead 总下载总大小
 *
 */

typedef void (^MMDownloadProgress)(int64_t bytesRead,
        int64_t totalBytesRead);

typedef MMDownloadProgress MMGetProgress;
typedef MMDownloadProgress MMPostProgress;

/**
 * 上传进度
 * @param bytesWritten 已上传大小
 * @param totalBytesWritten 总上传大小
 * 这个网络请求应该后续补上Progress
 */

typedef void (^MMUploadProgress)(int64_t bytesWritten,
        int64_t totalBytesWritten);


typedef NS_ENUM(NSUInteger, MMResponseType) {
    kMMResponseTypeJSON = 1, // 默认
    kMMResponseTypeXML  = 2,  // XML
    kMMResponseTypeData = 3  // 二进制
};

typedef NS_ENUM(NSUInteger, MMRequestType) {
    kMMRequestTypeJSON      = 1, // 默认
    kMMRequestTypePlainText = 2 // 普通text/html
};


typedef NS_ENUM(NSUInteger, MMNetworkStatus) {
    kMMNetworkStatusUnknown          = -1, //未知网络
    kMMNetworkStatusNotReachable     = 0, //网络无连接
    kMMNetworkStatusReachableViaWWAN = 1,  // 2, 3, 4G网络
    kMMNetworkStatusReachableViaWiFi = 2, // WIFI网络
};


/**
 * 所有接口返回值为NSURLSessionTask
 */
typedef NSURLSessionTask MMURLSessionTask;

/**
 * 请求成功回调
 * @param response 服务器返回的数据类型
 */
typedef void(^MMResponseSuccess)(id response);

/**
 * 请求失败回调
 * @param error 错误信息
 */
typedef void(^MMResponseFail)(NSError *error);


/***********************************************************************************************/

@interface MMNetWroking : NSObject

/**
 * 用于指定网络请求的base url
 * @param baseUrl 用于指定网络请求的基础url
 */
+ (void)updateBaseUrl:(NSString *)baseUrl;

+ (NSString *)baseUrl;

/**
 * 设置请求超时时间, 默认为30秒
 * @param timeout 超时时间
 */

+ (void)setTimeout:(NSTimeInterval)timeout;

/**
 * 当检查到网络异常时, 是否从本地提取数据,默认为NO, 一旦设置为True, 当设置刷新缓存时
 * 若网络异常也会从缓存中读取数据, 同样, 如果设置超时不回调, 同样会在网络异常时回调, 除非本地没有数据
 * @param shouldObatin BOOL
 */
+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObatin;

/**
 * 默认请求是不缓存的, 如果要缓存获取的数据, 需要手动头调用设置
 * @param isCacheGet 默认为false
 * @param shouldCachePost 默认为false
 */
+ (void)cacheGetRequest:(BOOL)isCacheGet shouldCachePost:(BOOL)shouldCachePost;

/**
 * 获取缓存总大小 bytes
 * @return 缓存大小
 */
+ (unsigned long long)totalCacheSize;

/**
 * 清楚缓存
 */
+ (void)clearCaches;

/**
 * 开启关闭接口打印信息
 * @param isDebug 开发期打开, 默认false
 */
+ (void)enableInterfaceDebug:(BOOL)isDebug;

/**
 * 配置请求格式, 默认为JSON
 * @param requestType 请求格式, 默认为JSON
 * @param responseType 返回格式, 默认为JSON
 * @param shouldAutoEncode  是否自动Encode Url
 * @param shouldCallbackOnCancelRequest 当取消请求时, 是否要回掉, 默认为true
 */
+ (void)configRequestType:(MMRequestType)requestType
             responseType:(MMResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest;

/**
 * 配置公共请求头
 * @param httpHeaders 只需要讲服务器所需参数设置即可
 */
+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders;

/**
 * 取消所有请求
 */
+ (void)cancelAllRequest;

/**
 * 取消某个请求
 * @param url 可以是绝对url也可以是某个url
 */
+ (void)cancelRequestWithURL:(NSString *)url;

/**
 * Get接口, 若不指定baseUrl, 可传完整URL
 * @param url           接口路径
 * @param refreshCache  是否刷新缓存
 * @param success       成功回调
 * @param fail          失败回掉
 * @return              返回的对象中有可取消请求的API
 */
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail;

/*!
 * 有提示框
 * Get接口, 若不指定baseUrl, 可传完整URL
 * @param url           接口路径
 * @param refreshCache  是否刷新缓存
 * @param statusText    提示框文字
 * @param success       成功回调
 * @param fail          失败回掉
 * @return              返回的对象中有可取消请求的API
 */
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         showHUD:(NSString *)statusText
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail;

/*!
 * 有参数无提示框
 * Get接口, 若不指定baseUrl, 可传完整URL
 * @param url           接口路径
 * @param refreshCache  是否刷新缓存
 * @param params        参数
 * @param success       成功回调
 * @param fail          失败回掉
 * @return              返回的对象中有可取消请求的API
 */
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                          params:(NSDictionary *)params
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail;

/*!
 * 有参数有提示框
 * Get接口, 若不指定baseUrl, 可传完整URL
 * @param url           接口路径
 * @param refreshCache  是否刷新缓存
 * @param statusText    提示框文字
 * @param params        参数
 * @param success       成功回调
 * @param fail          失败回掉
 * @return              返回的对象中有可取消请求的API
 */
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         showHUD:(NSString *)statusText
                          params:(NSDictionary *)params
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail;

/*!
 * 有参数有进度条
 * Get接口, 若不指定baseUrl, 可传完整URL
 * @param url           接口路径
 * @param refreshCache  是否刷新缓存
 * @param params        参数
 * @param progress      进度条
 * @param success       成功回调
 * @param fail          失败回掉
 * @return              返回的对象中有可取消请求的API
 */
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                          params:(NSDictionary *)params
                        progress:(MMGetProgress)progress
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail;

/*!
 * 有参数有进度条
 * Get接口, 若不指定baseUrl, 可传完整URL
 * @param url           接口路径
 * @param refreshCache  是否刷新缓存
 * @param statusText    提示框文字
 * @param params        参数
 * @param progress      进度条
 * @param success       成功回调
 * @param fail          失败回掉
 * @return              返回的对象中有可取消请求的API
 */
+ (MMURLSessionTask *)getWithUrl:(NSString *)url
                    refreshCache:(BOOL)refreshCache
                         showHUD:(NSString *)statusText
                          params:(NSDictionary *)params
                        progress:(MMGetProgress)progress
                         success:(MMResponseSuccess)success
                            fail:(MMResponseFail)fail;

/*!
 * Post请求借口, 若不指定baseurl, 可传完整url
 * @param url                 接口路径
 * @param refreshCache        刷新缓存
 * @param params              所需参数
 * @param success             成功回调
 * @param fail                失败回调
 * @return                    返回对象带有可取消请求的api
 */
+ (MMURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                          success:(MMResponseSuccess)success
                             fail:(MMResponseFail)fail;
// (有提示框)
+ (MMURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          showHUD:(NSString *)statusText
                           params:(NSDictionary *)params
                          success:(MMResponseSuccess)success
                             fail:(MMResponseFail)fail;
// 多一个带进度回调（无提示框）
+ (MMURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                         progress:(MMPostProgress)progress
                          success:(MMResponseSuccess)success
                             fail:(MMResponseFail)fail;
// 多一个带进度回调（有提示框）
+ (MMURLSessionTask *)postWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          showHUD:(NSString *)statusText
                           params:(NSDictionary *)params
                         progress:(MMPostProgress)progress
                          success:(MMResponseSuccess)success
                             fail:(MMResponseFail)fail;

/*!
 * 图片上传接口, 若不指定baseUrl, 可传完整url
 * @param image 图片对象
 * @param url 上传图片的接口路径, 如/path/images/
 * @param filename 给图片起一个名字, 默认为当前时间, 格式为"yyyyMMddHHmmss", 后缀为jpg
 * @param name 与指定的图片相关联的名称, 这是由后端写接口的认定的, 如imagefiles
 * @param mimeType 默认为image/jpeg
 * @param parameters 参数
 * @param progress 上传进度条
 * @param success 上传成功回调
 * @param fail 上传失败回调
 *
 * @return  返回对象带有可取消请求的api
 */
+ (MMURLSessionTask *)uploadWithImage:(UIImage *)image
                                  url:(NSString *)url
                             filename:(NSString *)filename
                                 name:(NSString *)name
                             mimeType:(NSString *)mimeType
                           parameters:(NSDictionary *)parameters
                             progress:(MMUploadProgress)progress
                              success:(MMResponseSuccess)success
                                 fail:(MMResponseFail)fail;

/*!
 * 上传文件操作
 * @param url 上传路径
 * @param uploadingFile 上传文件的路径
 * @param progress 上传进度
 * @param success 上传成功回调
 * @param fail 上传失败回调
 *
 * @return  返回对象带有可取消请求的api
 */
+ (MMURLSessionTask *)uploadFileWithUrl:(NSString *)url
                          uploadingFile:(NSString *)uploadingFile
                               progress:(MMUploadProgress)progress
                                success:(MMResponseSuccess)success
                                   fail:(MMResponseFail)fail;

/*!
 * 下载文件
 * @param url  下载url
 * @param saveToPath  下载到哪个路径下
 * @param progressBlock 下载进度
 * @param success  下载成功回调
 * @param fail 下载失败回调
 *
 * @return  返回对象带有可取消请求的api
 */
+ (MMURLSessionTask *)downloadWithUrl:(NSString *)url
                           saveToPath:(NSString *)saveToPath
                             progress:(MMDownloadProgress)progressBlock
                              success:(MMResponseSuccess)success
                                 fail:(MMResponseFail)fail;
@end
