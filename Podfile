platform :ios, '7.1'

pod 'ECSlidingViewController', '~> 2.0.2'
pod 'Underscore.m', '~> 0.2.1'
pod 'JSONKit', '~> 1.5pre'
pod "AFNetworking", "~> 2.0"

# Remove 64-bit build architecture from Pods targets
post_install do |installer|
    installer.project.targets.each do |target|
        target.build_configurations.each do |configuration|
            target.build_settings(configuration.name)['ARCHS'] = '$(ARCHS_STANDARD_32_BIT)'
        end
    end
end