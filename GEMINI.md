name: QIResizer
options:
  bundleIdPrefix: com.polidisio
  deploymentTarget:
    macOS: "14.0"
targets:
  QIResizer:
    type: application
    platform: macOS
    sources:
      - Sources
    resources:
      - Sources/Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.polidisio.QIResizer
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_NSPrincipalClass: NSApplication
        INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.utilities
        INFOPLIST_KEY_CFBundleIconFile: AppIcon
        CODE_SIGN_STYLE: Automatic
        SWIFT_VERSION: "5.9"
        MACOSX_DEPLOYMENT_TARGET: "14.0"
        CODE_SIGN_ENTITLEMENTS: QIResizer.entitlements
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
