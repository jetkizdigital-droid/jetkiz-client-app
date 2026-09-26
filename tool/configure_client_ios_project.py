from pathlib import Path

PROJECT = Path('ios/Runner.xcodeproj/project.pbxproj')
BUNDLE_ID = 'asia.jetkiz.client'
TEST_BUNDLE_ID = f'{BUNDLE_ID}.RunnerTests'

text = PROJECT.read_text(encoding='utf-8')
original = text

text = text.replace('com.example.jetkizMobile.RunnerTests', TEST_BUNDLE_ID)
text = text.replace('com.example.jetkizMobile', BUNDLE_ID)
text = text.replace('IPHONEOS_DEPLOYMENT_TARGET = 13.0;', 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;')

# Add Xcode capability metadata once. Entitlements are the signing source of
# truth; these flags also keep the project UI consistent with the release.
capability_anchor = '\t\t\t\t\t\tLastSwiftMigration = 1100;\n'
capability_block = (
    capability_anchor
    + '\t\t\t\t\t\tSystemCapabilities = {\n'
    + '\t\t\t\t\t\t\tcom.apple.BackgroundModes = {\n'
    + '\t\t\t\t\t\t\t\tenabled = 1;\n'
    + '\t\t\t\t\t\t\t};\n'
    + '\t\t\t\t\t\t\tcom.apple.Push = {\n'
    + '\t\t\t\t\t\t\t\tenabled = 1;\n'
    + '\t\t\t\t\t\t\t};\n'
    + '\t\t\t\t\t\t};\n'
)
if 'com.apple.Push = {' not in text:
    if capability_anchor not in text:
        raise SystemExit('Runner capability anchor not found')
    text = text.replace(capability_anchor, capability_block, 1)

# The Runner target has Profile, Debug and Release configurations. Add the
# correct entitlement file and automatic signing metadata to each one.
def add_target_signing(config_marker: str, entitlement: str) -> None:
    global text
    start = text.find(config_marker)
    if start < 0:
        raise SystemExit(f'Build configuration not found: {config_marker}')
    settings = text.find('\t\t\tbuildSettings = {\n', start)
    if settings < 0:
        raise SystemExit(f'buildSettings not found for: {config_marker}')
    insert_at = settings + len('\t\t\tbuildSettings = {\n')
    end = text.find('\t\t\t};\n', insert_at)
    block = text[insert_at:end]
    expected = f'CODE_SIGN_ENTITLEMENTS = {entitlement};'
    if expected in block:
        return
    prefix = (
        f'\t\t\t\tCODE_SIGN_ENTITLEMENTS = {entitlement};\n'
        '\t\t\t\tCODE_SIGN_STYLE = Automatic;\n'
    )
    text = text[:insert_at] + prefix + text[insert_at:]

add_target_signing('249021D4217E4FDB00AE95B9 /* Profile */ = {', 'Runner/Runner.Release.entitlements')
add_target_signing('97C147061CF9000F007C117D /* Debug */ = {', 'Runner/Runner.Debug.entitlements')
add_target_signing('97C147071CF9000F007C117D /* Release */ = {', 'Runner/Runner.Release.entitlements')

# Fail closed if the expected release identity is not present after patching.
checks = [
    'PRODUCT_BUNDLE_IDENTIFIER = asia.jetkiz.client;',
    'PRODUCT_BUNDLE_IDENTIFIER = asia.jetkiz.client.RunnerTests;',
    'CODE_SIGN_ENTITLEMENTS = Runner/Runner.Debug.entitlements;',
    'CODE_SIGN_ENTITLEMENTS = Runner/Runner.Release.entitlements;',
    'IPHONEOS_DEPLOYMENT_TARGET = 15.0;',
    'com.apple.Push = {',
    'com.apple.BackgroundModes = {',
]
for check in checks:
    if check not in text:
        raise SystemExit(f'Missing expected iOS project setting: {check}')

if text != original:
    PROJECT.write_text(text, encoding='utf-8')
    print('Updated client iOS Xcode project')
else:
    print('Client iOS Xcode project already configured')
