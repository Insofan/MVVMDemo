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
    kMMResponseTypeXML = 2,  // XML
    kMMResponseTypeData = 3  // 二进制
};

typedef NS_ENUM(NSUInteger, MMRequestType) {
    kMMRequestTypeJSON = 1, // 默认
    kMMRequestTypePlainText = 2 // 普通text/html
};


typedef NS_ENUM(NSUInteger, MMNetworkStatus) {
    kMMNetworkStatusUnknown = -1, //未知网络
    kMMNetworkStatusNotReachable = 0, //网络无连接
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

@interface MMNetWroking: NSObject

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

@end
