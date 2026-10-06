import sys

def replace_lines(filepath, line_replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for line_num, new_content in line_replacements.items():
        # 1-indexed to 0-indexed
        lines[line_num - 1] = new_content + "\n"
        
    with open(filepath, 'w', encoding='utf-8', newline='') as f:
        f.writelines(lines)

panchangam_replacements = {
    20: "      const days = ['திங்கள்', 'செவ்வாய்', 'புதன்', 'வியாழன்', 'வெள்ளி', 'சனி', 'ஞாயிறு'];",
    40: "    final tamilMonth = calendarDay?.tamilMonth ?? (isTamil ? 'புரட்டாசி' : 'Purattasi');",
    41: "    final tamilYear = calendarDay?.tamilYear ?? (isTamil ? 'குரோதி' : 'Krodhi');",
    125: "                    isTamil ? 'தமிழ் மாதம் & ஆண்டு' : 'Tamil Month & Year',",
    133: "                    isTamil ? 'கிழமை / நாள்' : 'Day / Tamil Date',"
}
replace_lines('lib/panchangam/widgets/panchangam_overview_card.dart', panchangam_replacements)

calendar_replacements = {
    240: "            'ஞாயிறு',",
    241: "            'திங்கள்',",
    242: "            'செவ்வாய்',",
    243: "            'புதன்',",
    244: "            'வியாழன்',",
    245: "            'வெள்ளி',",
    246: "            'சனி'",
    256: "              final isWeekend = day == 'ஞாயிறு' ||",
    258: "                  day == 'சனி' ||",
    446: "                ? 'இந்த மாத சிறப்பு நாட்கள்'",
    469: "                  isTamil ? 'பண்டிகை' : 'Festival',",
    481: "                      ? 'சிறப்பு நாள்'",
    490: "                      ? 'சுப முகூர்த்தம்'",
    496: "                  isTamil ? 'முகூர்த்தம்' : 'Muhurtham',",
    581: "        'ஜனவரி',",
    582: "        'பிப்ரவரி',",
    583: "        'மார்ச்',",
    584: "        'ஏப்ரல்',",
    585: "        'மே',",
    586: "        'ஜூன்',",
    587: "        'ஜூலை',",
    588: "        'ஆகஸ்ட்',",
    589: "        'செப்டம்பர்',",
    590: "        'அக்டோபர்',",
    591: "        'நவம்பர்',",
    592: "        'டிசம்பர்'"
}
replace_lines('lib/calendar/screens/calendar_screen.dart', calendar_replacements)

print('Lines replaced.')
