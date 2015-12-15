platform :ios, '7.1'

pod 'Underscore.m', '~> 0.2.1'
pod 'JSONKit', '~> 1.5pre'
pod 'XLForm', '~> 2.1.0'
pod 'BlocksKit'
pod "AFNetworking", "~> 2.0"
pod 'MGSwipeTableCell'
pod 'AWPercentDrivenInteractiveTransition'
pod 'Masonry' # Auto-layout DSL https://github.com/Masonry/Masonry
# pod 'pop', '~> 1.0'
# pod 'POP+MCAnimate', '~> 2.0'

# Remove 64-bit build architecture from Pods targets
post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |configuration|
            target.build_settings(configuration.name)['ARCHS'] = '$(ARCHS_STANDARD_32_BIT)'
        end
    end
end