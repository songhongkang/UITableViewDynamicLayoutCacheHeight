Pod::Spec.new do |s|
s.name         = 'UITableViewDynamicLayoutCacheHeight'
s.version      = '5.1.4'
s.summary      = '🖖 Template auto layout cell for automatically UITableViewCell UITableViewHeaderFooterView calculating and cache height framework.'
s.homepage     = 'https://github.com/liangdahong/UITableViewDynamicLayoutCacheHeight'
s.license      = 'MIT'
s.authors      = {'liangdahong' => 'ios@liangdahong.com'}
s.platform     = :ios, '8.0'
s.source       = {:git => 'https://github.com/liangdahong/UITableViewDynamicLayoutCacheHeight.git', :tag => s.version}
s.requires_arc = true
s.source_files = 'UITableViewDynamicLayoutCacheHeight/**/*.{h,m}'
end

