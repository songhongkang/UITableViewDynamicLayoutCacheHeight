//    MIT License
//
//    Copyright (c) 2019 https://github.com/liangdahong
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

#import "UITableViewCell+BMDynamicLayout.h"
#import <objc/runtime.h>
#import "UITableView+BMPrivate.h"
#import "UITableViewDynamicLayoutCacheHeight.h"

@implementation UITableViewCell (BMDynamicLayout)

- (BOOL)bm_maxYViewFixed {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBm_maxYViewFixed:(BOOL)bm_maxYViewFixed {
    objc_setAssociatedObject(self, @selector(bm_maxYViewFixed), @(bm_maxYViewFixed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (instancetype)bm_tableViewCellFromNibWithTableView:(UITableView *)tableView {
    NSString *selfClassName = NSStringFromClass(self.class);
    NSString *reuseIdentifier = [selfClassName stringByAppendingString:@"BMNibDynamicLayoutReuseIdentifier"];

    if ([objc_getAssociatedObject(tableView, (__bridge const void * _Nonnull)(self)) boolValue]) {
        // 已注册
        return [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    }
    BM_UITableView_DynamicLayout_LOG(@"✅✅✅✅%@ UINib nibWithNibName", self);
    // 未注册，开始注册
    UINib *nib = [UINib nibWithNibName:kSwiftClassNibName(selfClassName) bundle:[NSBundle bundleForClass:self.class]];
    [tableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
    objc_setAssociatedObject(tableView, (__bridge const void * _Nonnull)(self), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
}

+ (instancetype)bm_tableViewCellFromAllocWithTableView:(UITableView *)tableView {
    return [self bm_tableViewCellFromAllocWithTableView:tableView style:(UITableViewCellStyleDefault)];
}

+ (instancetype)bm_tableViewCellFromAllocWithTableView:(UITableView *)tableView style:(UITableViewCellStyle)style {
    NSString *reuseIdentifier = [NSStringFromClass(self.class) stringByAppendingString:@"BMAllocDynamicLayoutReuseIdentifier"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell) {
        return cell;
    }
    BM_UITableView_DynamicLayout_LOG(@"✅✅✅✅%@ alloc initWithStyle", self);
    return [[self alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
}

@end
