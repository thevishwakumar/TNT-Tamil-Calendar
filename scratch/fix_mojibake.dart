import 'dart:io';

void main() {
  final panchangamFile = File('lib/panchangam/widgets/panchangam_overview_card.dart');
  var pContent = panchangamFile.readAsStringSync();
  pContent = pContent.replaceAll('\'à®¤à®¿à®™à¯ à®•à®³à¯ \'', '\'திங்கள்\'');
  pContent = pContent.replaceAll('\'à®šà¯†à®µà¯ à®µà®¾à®¯à¯ \'', '\'செவ்வாய்\'');
  pContent = pContent.replaceAll('\'à®ªà¯ à®¤à®©à¯ \'', '\'புதன்\'');
  pContent = pContent.replaceAll('\'à®µà®¿à®¯à®¾à®´à®©à¯ \'', '\'வியாழன்\'');
  pContent = pContent.replaceAll('\'à®µà¯†à®³à¯ à®³à®¿\'', '\'வெள்ளி\'');
  pContent = pContent.replaceAll('\'à®šà®©à®¿\'', '\'சனி\'');
  pContent = pContent.replaceAll('\'à®žà®¾à®¯à®¿à®±à¯ \'', '\'ஞாயிறு\'');
  
  pContent = pContent.replaceAll('\'à®ªà¯ à®°à®Ÿà¯ à®Ÿà®¾à®šà®¿\'', '\'புரட்டாசி\'');
  pContent = pContent.replaceAll('\'à®•à¯ à®°à¯‹à®¤à®¿\'', '\'குரோதி\'');
  
  pContent = pContent.replaceAll('\'à®¤à®®à®¿à®´à¯  à®®à®¾à®¤à®®à¯  & à®†à®£à¯ à®Ÿà¯ \'', '\'தமிழ் மாதம் & ஆண்டு\'');
  pContent = pContent.replaceAll('\'à®•à®¿à®´à®®à¯ˆ / à®¨à®¾à®³à¯ \'', '\'கிழமை / நாள்\'');
  pContent = pContent.replaceAll('Â·', '·');
  
  panchangamFile.writeAsStringSync(pContent);

  final calFile = File('lib/calendar/screens/calendar_screen.dart');
  var cContent = calFile.readAsStringSync();
  cContent = cContent.replaceAll('\'à®¤à®¿à®™à¯ à®•à®³à¯ \'', '\'திங்கள்\'');
  cContent = cContent.replaceAll('\'à®šà¯†à®µà¯ à®µà®¾à®¯à¯ \'', '\'செவ்வாய்\'');
  cContent = cContent.replaceAll('\'à®ªà¯ à®¤à®©à¯ \'', '\'புதன்\'');
  cContent = cContent.replaceAll('\'à®µà®¿à®¯à®¾à®´à®©à¯ \'', '\'வியாழன்\'');
  cContent = cContent.replaceAll('\'à®µà¯†à®³à¯ à®³à®¿\'', '\'வெள்ளி\'');
  cContent = cContent.replaceAll('\'à®šà®©à®¿\'', '\'சனி\'');
  cContent = cContent.replaceAll('\'à®žà®¾à®¯à®¿à®±à¯ \'', '\'ஞாயிறு\'');

  cContent = cContent.replaceAll('\'à®‡à®¨à¯ à®¤ à®®à®¾à®¤ à®šà®¿à®±à®ªà¯ à®ªà¯  à®¨à®¾à®Ÿà¯ à®•à®³à¯ \'', '\'இந்த மாத சிறப்பு நாட்கள்\'');
  cContent = cContent.replaceAll('\'à®ªà®£à¯ à®Ÿà®¿à®•à¯ˆ\'', '\'பண்டிகை\'');
  cContent = cContent.replaceAll('\'à®šà®¿à®±à®ªà¯ à®ªà¯  à®¨à®¾à®³à¯ \'', '\'சிறப்பு நாள்\'');
  cContent = cContent.replaceAll('\'à®šà¯ à®ª à®®à¯ à®•à¯‚à®°à¯ à®¤à¯ à®¤à®®à¯ \'', '\'சுப முகூர்த்தம்\'');
  cContent = cContent.replaceAll('\'à®®à¯ à®•à¯‚à®°à¯ à®¤à¯ à®¤à®®à¯ \'', '\'முகூர்த்தம்\'');

  cContent = cContent.replaceAll('\'à®œà®©à®µà®°à®¿\'', '\'ஜனவரி\'');
  cContent = cContent.replaceAll('\'à®ªà®¿à®ªà¯ à®°à®µà®°à®¿\'', '\'பிப்ரவரி\'');
  cContent = cContent.replaceAll('\'à®®à®¾à®°à¯ à®šà¯ \'', '\'மார்ச்\'');
  cContent = cContent.replaceAll('\'à® à®ªà¯ à®°à®²à¯ \'', '\'ஏப்ரல்\'');
  cContent = cContent.replaceAll('\'à®®à¯‡\'', '\'மே\'');
  cContent = cContent.replaceAll('\'à®œà¯‚à®©à¯ \'', '\'ஜூன்\'');
  cContent = cContent.replaceAll('\'à®œà¯‚à®²à¯ˆ\'', '\'ஜூலை\'');
  cContent = cContent.replaceAll('\'à®†à®•à®¸à¯ à®Ÿà¯ \'', '\'ஆகஸ்ட்\'');
  cContent = cContent.replaceAll('\'à®šà¯†à®ªà¯ à®Ÿà®®à¯ à®ªà®°à¯ \'', '\'செப்டம்பர்\'');
  cContent = cContent.replaceAll('\'à®…à®•à¯ à®Ÿà¯‹à®ªà®°à¯ \'', '\'அக்டோபர்\'');
  cContent = cContent.replaceAll('\'à®¨à®µà®®à¯ à®ªà®°à¯ \'', '\'நவம்பர்\'');
  cContent = cContent.replaceAll('\'à®Ÿà®¿à®šà®®à¯ à®ªà®°à¯ \'', '\'டிசம்பர்\'');

  calFile.writeAsStringSync(cContent);
  print('Fixed mojibake in panchangam_overview_card.dart and calendar_screen.dart');
}
