platform :ios, '7.1'

pod 'ECSlidingViewController', '~> 2.0.1'
pod 'Underscore.m', '~> 0.2.1'
pod 'JSONKit', '~> 1.5pre'

# Remove 64-bit build architecture from Pods targets
post_install do |installer|
    installer.project.targets.each do |target|
        target.build_configurations.each do |configuration|
            target.build_settings(configuration.name)['ARCHS'] = '$(ARCHS_STANDARD_32_BIT)'
        end
    end
end