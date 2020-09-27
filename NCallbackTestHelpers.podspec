Pod::Spec.new do |spec|
    spec.name         = "NCallbackTestHelpers"
    spec.version      = "1.0.0"
    spec.summary      = "NCallback - wrapped closures"

    spec.source       = { :git => "git@bitbucket.org:tech4star/NCallback.git" }
    spec.homepage     = "https://bitbucket.org/tech4star/NCallback.git"

    spec.license          = 'MIT'
    spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
    spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

    spec.ios.deployment_target = "10.0"
    spec.swift_version = '5.0'

    spec.resources = ['TestHelpers/**/*.{storyboard,xib,xcassets,json,imageset,png,strings,stringsdict}']
    spec.source_files  = 'TestHelpers/**/*.swift'

    spec.dependency 'Spry'
    spec.dependency 'NCallback'

    spec.frameworks = 'XCTest', 'Foundation'

    spec.scheme = {
      :code_coverage => true
    }

    spec.test_spec 'Tests' do |tests|
        #        tests.requires_app_host = true

        tests.dependency 'Nimble'
        tests.dependency 'Quick'
        tests.dependency 'Spry+Nimble'

        tests.source_files = 'Tests/Specs/**/*.swift'
    end
end
