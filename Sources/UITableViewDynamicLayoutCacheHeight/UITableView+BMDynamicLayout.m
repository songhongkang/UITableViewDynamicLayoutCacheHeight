//    MIT License
//
//    Copyright (c) 2019 https://liangdahong.com
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

#import "UITableView+BMDynamicLayout.h"
#import <objc/runtime.h>
#import "UITableView+BMPrivate.h"
#import "UITableViewCell+BMPrivate.h"
#import "UITableViewHeaderFooterView+BMPrivate.h"
#import "UITableViewHeaderFooterView+BMDynamicLayout.h"
#import "UITableViewCell+BMDynamicLayout.h"

#ifdef DEBUG
    #define BM_UITableView_DynamicLayout_LOG(...) NSLog(__VA_ARGS__)
#else
    #define BM_UITableView_DynamicLayout_LOG(...)
#endif

void tableViewDynamicLayoutLayoutIfNeeded(UIView *view);
inline void tableViewDynamicLayoutLayoutIfNeeded(UIView *view) {
    // https://juejin.im/post/5a30f24bf265da432e5c0070
    // https://objccn.io/issue-3-5
    [view setNeedsUpdateConstraints];
    [view setNeedsLayout];
    [view layoutIfNeeded];
    [view setNeedsDisplay];
}

@implementation UITableView (BMDynamicLayout)

#pragma mark - private cell

- (CGFloat)_heightWithCellClass:(Class)clas
                  configuration:(void (^)(__kindof UITableViewCell *cell))configuration {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, _cmd, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UIView *view = dict[NSStringFromClass(clas)];
    
    if (!view) {
        NSString *path = [[NSBundle mainBundle] pathForResource:NSStringFromClass(clas) ofType:@"nib"];
        UIView *cell = nil;
        if (path.length) {
            cell = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(clas) owner:nil options:nil].firstObject;
        } else {
            cell = [[clas alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        view = [UIView new];
        [view addSubview:cell];
        dict[NSStringFromClass(clas)] = view;
    }

    // 获取 TableView 宽度
    UIView *temp = self.superview ? self.superview : self;
    tableViewDynamicLayoutLayoutIfNeeded(temp);
    CGFloat width = CGRectGetWidth(self.frame);
    
    // 设置 Frame
    view.frame = CGRectMake(0.0f, 0.0f, width, 0.0f);
    UITableViewCell *cell = view.subviews.firstObject;
    cell.frame = CGRectMake(0.0f, 0.0f, width, 0.0f);
    
    // 让外面布局 Cell
    !configuration ? : configuration(cell);
    
    // 刷新布局
    tableViewDynamicLayoutLayoutIfNeeded(view);
    
    // 获取需要的高度
    __block CGFloat maxY  = 0.0f;
    if (cell.bm_maxYViewFixed) {
        if (cell.maxYView) {
            return CGRectGetMaxY(cell.maxYView.frame);
        } else {
            __block UIView *maxXView = nil;
            [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxXView = obj;
                }
            }];
            cell.maxYView = maxXView;
            return maxY;
        }
    } else {
        [cell.contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
        return maxY;
    }
}

#pragma mark - private HeaderFooterView

- (CGFloat)_heightWithHeaderFooterViewClass:(Class)clas
                                        sel:(SEL)sel
                              configuration:(void (^)(__kindof UITableViewHeaderFooterView *headerFooterView))configuration {
    
    NSMutableDictionary *dict = objc_getAssociatedObject(self, sel);
    if (!dict) {
        dict = @{}.mutableCopy;
        objc_setAssociatedObject(self, sel, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    UIView *view = dict[NSStringFromClass(clas)];
    
    if (!view) {
        NSString *path = [[NSBundle mainBundle] pathForResource:NSStringFromClass(clas) ofType:@"nib"];
        UIView *headerView = nil;
        if (path.length) {
            headerView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(clas) owner:nil options:nil].firstObject;
        } else {
            headerView = [[clas alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        }
        view = [UIView new];
        [view addSubview:headerView];
        dict[NSStringFromClass(clas)] = view;
    }

    // 获取 TableView 宽度
    UIView *temp = self.superview ? self.superview : self;
    tableViewDynamicLayoutLayoutIfNeeded(temp);
    CGFloat width = CGRectGetWidth(self.frame);

    // 设置 Frame
    view.frame = CGRectMake(0.0f, 0.0f, width, 0.0f);
    UITableViewHeaderFooterView *headerFooterView = view.subviews.firstObject;
    headerFooterView.frame = CGRectMake(0.0f, 0.0f, width, 0.0f);
    
    // 让外面布局 UITableViewHeaderFooterView
    !configuration ? : configuration(headerFooterView);
    // 刷新布局
    tableViewDynamicLayoutLayoutIfNeeded(view);

    UIView *contentView = headerFooterView.contentView.subviews.count ? headerFooterView.contentView : headerFooterView;

    // 获取需要的高度
    __block CGFloat maxY  = 0.0f;
    if (headerFooterView.bm_maxYViewFixed) {
        if (headerFooterView.maxYView) {
            return CGRectGetMaxY(headerFooterView.maxYView.frame);
        } else {
            __block UIView *maxXView = nil;
            [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                CGFloat tempY = CGRectGetMaxY(obj.frame);
                if (tempY > maxY) {
                    maxY = tempY;
                    maxXView = obj;
                }
            }];
            headerFooterView.maxYView = maxXView;
            return maxY;
        }
    } else {
        [contentView.subviews enumerateObjectsWithOptions:(NSEnumerationReverse) usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat tempY = CGRectGetMaxY(obj.frame);
            if (tempY > maxY) {
                maxY = tempY;
            }
        }];
        return maxY;
    }
}

- (CGFloat)_heightWithHeaderViewClass:(Class)clas
                        configuration:(void (^)(__kindof UITableViewHeaderFooterView *headerFooterView))configuration {
    return [self _heightWithHeaderFooterViewClass:clas sel:_cmd configuration:configuration];
}

- (CGFloat)_heightWithFooterViewClass:(Class)clas
                        configuration:(void (^)(__kindof UITableViewHeaderFooterView *headerFooterView))configuration {
    return [self _heightWithHeaderFooterViewClass:clas sel:_cmd configuration:configuration];
}

#pragma mark - set get

- (CGFloat)fixedWidth {
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
}

- (void)setFixedWidth:(CGFloat)fixedWidth {
    objc_setAssociatedObject(self, @selector(fixedWidth), @(fixedWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Public cell

- (CGFloat)bm_heightWithCellClass:(Class)clas
                    configuration:(void (^)(__kindof UITableViewCell *cell))configuration {
    return [self _heightWithCellClass:clas configuration:configuration];
}

- (CGFloat)bm_heightWithCellClass:(Class)clas
                 cacheByIndexPath:(NSIndexPath *)indexPath
                    configuration:(void (^)(__kindof UITableViewCell *cell))configuration {
    // init cache Array
    NSMutableArray <NSMutableArray <NSNumber *> *> *arr1 = self.verticalArray;
    long i1 = (indexPath.section + 1 - arr1.count);
    while (i1-- > 0) {
        [self.verticalArray addObject:@[].mutableCopy];
    }
    NSMutableArray <NSNumber *> *arr2 = arr1[indexPath.section];
    long i2 = (indexPath.row + 1 - arr2.count);
    while (i2-- > 0) {
        [arr2 addObject:@(-1)];
    }

    NSMutableArray <NSMutableArray <NSNumber *> *> *arr3 = self.horizontalArray;
    long i3 = (indexPath.section + 1 - arr3.count);
    while (i3-- > 0) {
        [arr3 addObject:@[].mutableCopy];
    }
    NSMutableArray <NSNumber *> *arr4 = arr3[indexPath.section];
    long i4 = (indexPath.row + 1 - arr4.count);
    while (i4-- > 0) {
        [arr4 addObject:@(-1)];
    }

    NSNumber *number = self.heightArray[indexPath.section][indexPath.row];

    if (number.doubleValue == -1) {
        // not cache
        self.isIndexPathHeightCache = YES;
        // get cache height
        CGFloat cellHeight = [self _heightWithCellClass:clas configuration:configuration];
        // save cache height
        self.heightArray[indexPath.section][indexPath.row] = @(cellHeight);
        BM_UITableView_DynamicLayout_LOG(@"BMLog: Cell: %@ save height { (indexPath: %ld %ld ) (height: %@) }", NSStringFromClass(clas), indexPath.section, indexPath.row, @(cellHeight));
        return cellHeight;
        
    } else {
        BM_UITableView_DynamicLayout_LOG(@"BMLog:✅ Cell: %@ get cache height { (indexPath: %ld %ld ) (height: %@) }", NSStringFromClass(clas), indexPath.section, indexPath.row, number);
        return number.doubleValue;
    }
}

- (CGFloat)bm_heightWithCellClass:(Class)clas
                       cacheByKey:(NSString *)key
                    configuration:(void (^)(__kindof UITableViewCell *cell))configuration {
    if (key && self.heightDictionary[key]) {
        BM_UITableView_DynamicLayout_LOG(@"BMLog:✅ Cell: %@ get cache height { (key: %@) (height: %@) }", NSStringFromClass(clas), key, self.heightDictionary[key]);
        return self.heightDictionary[key].doubleValue;
    }
    self.isIndexPathHeightCache = NO;
    CGFloat cellHeight = [self _heightWithCellClass:clas configuration:configuration];
    if (key) {
        BM_UITableView_DynamicLayout_LOG(@"BMLog: Cell: %@ save height { (key: %@) (height: %@) }", NSStringFromClass(clas), key, @(cellHeight));
        self.heightDictionary[key] = @(cellHeight);
    }
    return cellHeight;
}

#pragma mark - Public HeaderFooter

- (CGFloat)bm_heightWithHeaderFooterViewClass:(Class)clas
                                         type:(BMHeaderFooterViewDynamicLayoutType)type
                                configuration:(void (^)(__kindof UITableViewHeaderFooterView *headerFooterView))configuration {
    if (type == BMHeaderFooterViewDynamicLayoutTypeHeader) {
        return [self _heightWithHeaderViewClass:clas configuration:configuration];
    } else {
        return [self _heightWithFooterViewClass:clas configuration:configuration];
    }
}

- (CGFloat)bm_heightWithHeaderFooterViewClass:(Class)clas
                                         type:(BMHeaderFooterViewDynamicLayoutType)type
                               cacheBySection:(NSInteger)section
                                configuration:(void (^)(__kindof UITableViewHeaderFooterView *headerFooterView))configuration {
    if (type == BMHeaderFooterViewDynamicLayoutTypeHeader) {
        // init cache Array
        NSMutableArray <NSNumber *> *arr1 = self.headerVerticalArray;
        long i1 = (section + 1 - arr1.count);
        while (i1-- > 0) {
            [self.headerVerticalArray addObject:@(-1)];
        }
        
        NSMutableArray <NSNumber *> *arr2 = self.headerHorizontalArray;
        long i2 = (section + 1 - arr2.count);
        while (i2-- > 0) {
            [self.headerHorizontalArray addObject:@(-1)];
        }

        NSNumber *number = self.headerHeightArray[section];

        if (number.doubleValue == -1) {
            // not cache
            self.isSectionHeaderHeightCache = YES;
            // get cache height
            CGFloat height = [self _heightWithHeaderViewClass:clas configuration:configuration];
            // save cache height
            self.headerHeightArray[section] = @(height);
            BM_UITableView_DynamicLayout_LOG(@"BMLog: Header: %@ save height { ( section: %ld ) (height: %@) }", NSStringFromClass(clas), section, @(height));
            return height;
        } else {
            BM_UITableView_DynamicLayout_LOG(@"BMLog:✅ Header: %@ get cache height { (section: %ld ) (height: %@) }", NSStringFromClass(clas), section, number);
            return number.doubleValue;
        }
    } else {
        
        // init cache Array
        NSMutableArray <NSNumber *> *arr1 = self.footerVerticalArray;
        long i1 = (section + 1 - arr1.count);
        while (i1-- > 0) {
            [self.footerVerticalArray addObject:@(-1)];
        }

        NSMutableArray <NSNumber *> *arr2 = self.footerHorizontalArray;
        long i2 = (section + 1 - arr2.count);
        while (i2-- > 0) {
            [self.footerHorizontalArray addObject:@(-1)];
        }
        
        NSNumber *number = self.footerHeightArray[section];
        
        if (number.doubleValue == -1) {
            // not cache
            self.isSectionFooterHeightCache = YES;
            // get cache height
            CGFloat height = [self _heightWithFooterViewClass:clas configuration:configuration];
            // save cache height
            self.footerHeightArray[section] = @(height);
            BM_UITableView_DynamicLayout_LOG(@"BM: Footer: %@ save height { ( section: %ld ) (height: %@) }", NSStringFromClass(clas), section, @(height));
            return height;
        } else {
            BM_UITableView_DynamicLayout_LOG(@"BMLog:✅ Footer: %@ get cache height { (section: %ld ) (height: %@) }", NSStringFromClass(clas), section, number);
            return number.doubleValue;
        }
    }
}

- (CGFloat)bm_heightWithHeaderFooterViewClass:(Class)clas
                                         type:(BMHeaderFooterViewDynamicLayoutType)type
                                   cacheByKey:(NSString *)key
                                configuration:(void (^)(__kindof UITableViewHeaderFooterView *headerFooterView))configuration {
    if (type == BMHeaderFooterViewDynamicLayoutTypeHeader) {
        if (key && self.headerHeightDictionary[key]) {
            BM_UITableView_DynamicLayout_LOG(@"BMLog:✅ Header: %@ get cache height { (key: %@) (height: %@) }", NSStringFromClass(clas), key, self.headerHeightDictionary[key]);
            return self.headerHeightDictionary[key].doubleValue;
        }
        self.isSectionHeaderHeightCache = NO;
        CGFloat cellHeight = [self _heightWithHeaderViewClass:clas configuration:configuration];
        if (key) {
            BM_UITableView_DynamicLayout_LOG(@"BML: Header: %@ save height { (key: %@) (height: %@) }", NSStringFromClass(clas), key, @(cellHeight));
            self.heightDictionary[key] = @(cellHeight);
        }
        return cellHeight;
        
    } else {
        if (key && self.footerHeightDictionary[key]) {
            BM_UITableView_DynamicLayout_LOG(@"BMLog:✅ Footer: %@ get cache height { (key: %@) (height: %@) }", NSStringFromClass(clas), key, self.footerHeightDictionary[key]);
            return self.footerHeightDictionary[key].doubleValue;
        }
        self.isSectionFooterHeightCache = NO;
        CGFloat cellHeight = [self _heightWithFooterViewClass:clas configuration:configuration];
        
        if (key) {
            BM_UITableView_DynamicLayout_LOG(@"BML:  Footer: %@ save height { (key: %@) (height: %@) }", NSStringFromClass(clas), key, @(cellHeight));
            self.footerHeightDictionary[key] = @(cellHeight);
        }
        return cellHeight;
    }
}

@end