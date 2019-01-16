//
//  MMConfig.h
//  MVVMDemo
//
//  Created by Insomnia on 2019/1/9.
//  Copyright © 2019 Insomnia. All rights reserved.
//

#ifndef MMConfig_h
#define MMConfig_h

// 懒加载
#define MM_LAZY(object, assignment) (object = object ?: assignment)

// debug下
#ifndef __OPTIMIZE__
#define NSLog(...) NSLog(__VA_ARGS__)
#else
// release下
#define NSLog(...) {}
#endif

#endif /* MMConfig_h */
