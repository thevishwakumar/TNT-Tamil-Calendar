import os

def fix_mojibake(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Days
    content = content.replace('à®¤à®¿à®™à¯ à®•à®³à¯ ', 'திங்கள்')
    content = content.replace('à®šà¯†à®µà¯ à®µà®¾à®¯à¯ ', 'செவ்வாய்')
    content = content.replace('à®ªà¯ à®¤à®©à¯ ', 'புதன்')
    content = content.replace('à®µà®¿à®¯à®¾à®´à®©à¯ ', 'வியாழன்')
    content = content.replace('à®µà¯†à®³à¯ à®³à®¿', 'வெள்ளி')
    content = content.replace('à®šà®©à®¿', 'சனி')
    content = content.replace('à®žà®¾à®¯à®¿à®±à¯ ', 'ஞாயிறு')

    # Months / General
    content = content.replace('à®ªà¯ à®°à®Ÿà¯ à®Ÿà®¾à®šà®¿', 'புரட்டாசி')
    content = content.replace('à®•à¯ à®°à¯‹à®¤à®¿', 'குரோதி')
    content = content.replace('à®¤à®®à®¿à®´à¯  à®®à®¾à®¤à®®à¯  & à®†à®£à¯ à®Ÿà¯ ', 'தமிழ் மாதம் & ஆண்டு')
    content = content.replace('à®•à®¿à®´à®®à¯ˆ / à®¨à®¾à®³à¯ ', 'கிழமை / நாள்')

    # Calendar Screen
    content = content.replace('à®‡à®¨à¯ à®¤ à®®à®¾à®¤ à®šà®¿à®±à®ªà¯ à®ªà¯  à®¨à®¾à®Ÿà¯ à®•à®³à¯ ', 'இந்த மாத சிறப்பு நாட்கள்')
    content = content.replace('à®ªà®£à¯ à®Ÿà®¿à®•à¯ˆ', 'பண்டிகை')
    content = content.replace('à®šà®¿à®±à®ªà¯ à®ªà¯  à®¨à®¾à®³à¯ ', 'சிறப்பு நாள்')
    content = content.replace('à®šà¯ à®ª à®®à¯ à®•à¯‚à®°à¯ à®¤à¯ à®¤à®®à¯ ', 'சுப முகூர்த்தம்')
    content = content.replace('à®®à¯ à®•à¯‚à®°à¯ à®¤à¯ à®¤à®®à¯ ', 'முகூர்த்தம்')

    # Months
    content = content.replace('à®œà®©à®µà®°à®¿', 'ஜனவரி')
    content = content.replace('à®ªà®¿à®ªà¯ à®°à®µà®°à®¿', 'பிப்ரவரி')
    content = content.replace('à®®à®¾à®°à¯ à®šà¯ ', 'மார்ச்')
    content = content.replace('à® à®ªà¯ à®°à®²à¯ ', 'ஏப்ரல்')
    content = content.replace('à®®à¯‡', 'மே')
    content = content.replace('à®œà¯‚à®©à¯ ', 'ஜூன்')
    content = content.replace('à®œà¯‚à®²à¯ˆ', 'ஜூலை')
    content = content.replace('à®†à®•à®¸à¯ à®Ÿà¯ ', 'ஆகஸ்ட்')
    content = content.replace('à®šà¯†à®ªà¯ à®Ÿà®®à¯ à®ªà®°à¯ ', 'செப்டம்பர்')
    content = content.replace('à®…à®•à¯ à®Ÿà¯‹à®ªà®°à¯ ', 'அக்டோபர்')
    content = content.replace('à®¨à®µà®®à¯ à®ªà®°à¯ ', 'நவம்பர்')
    content = content.replace('à®Ÿà®¿à®šà®®à¯ à®ªà®°à¯ ', 'டிசம்பர்')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_mojibake('lib/panchangam/widgets/panchangam_overview_card.dart')
fix_mojibake('lib/calendar/screens/calendar_screen.dart')
print('Fixed successfully')
