path = r'C:\Users\Vishw\Downloads\TNT\lib\services\auth_state_manager.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Fix 1: _loadUserSession
# Find: } else if (profile.accountStatus == 'PENDING_MOBILE_VERIFICATION' || profile.phoneVerifiedAt == null) {
# Replace: } else if ((profile.accountStatus == 'PENDING_MOBILE_VERIFICATION' || profile.phoneVerifiedAt == null) && (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty)) {
content = re.sub(
    r"\} else if \(profile\.accountStatus == 'PENDING_MOBILE_VERIFICATION' \|\| profile\.phoneVerifiedAt == null\) \{",
    r"} else if ((profile.accountStatus == 'PENDING_MOBILE_VERIFICATION' || profile.phoneVerifiedAt == null) && (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty)) {",
    content
)

# Fix 2: verifyEmailOtp
# Find:
# final updated = _currentProfile!.copyWith(
#         emailVerifiedAt: DateTime.now(),
#         accountStatus: 'PENDING_MOBILE_VERIFICATION',
#         updatedAt: DateTime.now(),
#       );
# 
#       if (SupabaseService().isInitialized) {
#         await _profileRepo.upsertUserProfile(updated);
#       }
#       _currentProfile = updated;
#       _state = AppAuthState.pendingMobileVerification;
pattern2 = r"final updated = _currentProfile!\.copyWith\([\s\S]*?accountStatus:\s*'PENDING_MOBILE_VERIFICATION',[\s\S]*?_state = AppAuthState\.pendingMobileVerification;"
replacement2 = '''final hasMobile = _currentProfile!.phoneNumber != null && _currentProfile!.phoneNumber!.isNotEmpty;
      final nextStatus = hasMobile ? 'PENDING_MOBILE_VERIFICATION' : 'ACTIVE';
      
      final updated = _currentProfile!.copyWith(
        emailVerifiedAt: DateTime.now(),
        accountStatus: nextStatus,
        updatedAt: DateTime.now(),
      );

      if (SupabaseService().isInitialized) {
        await _profileRepo.upsertUserProfile(updated);
      }
      _currentProfile = updated;
      _state = hasMobile ? AppAuthState.pendingMobileVerification : AppAuthState.authenticatedUser;'''
content = re.sub(pattern2, replacement2, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
