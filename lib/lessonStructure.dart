
class Lesson {

  String? lessonShortTitle;
  String? lessonNumber;
  String? lessonTitle;
  String? lessonText;
  String? fullTitle;
  String? audio;
  String? link;

  Lesson({
    required this.lessonShortTitle, 
    required this.lessonNumber, 
    required this.lessonTitle, 
    required this.lessonText, 
    required this.fullTitle, 
    required this.audio, 
    required this.link,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {

    // For debugging and manually identifying the weird characters that need handling
    if (json['lessonNumber']=='Lesson 1') {
      print(json['lessonText']);
      print(sanatise(json['lessonText']));
    }

    return Lesson(
      lessonShortTitle: sanatise(json['lessonShortTitle']),
      lessonNumber: sanatise(json['lessonNumber']),
      lessonTitle: sanatise(json['lessonTitle']),
      lessonText: sanatise(json['lessonText']),
      fullTitle: sanatise(json['fullTitle']),
      audio: json['audio'],
      link: json['link'],
    );
  }

  static String sanatise(String s) {
    // There are a few funky characters in the text, so we need to remove them
    if (s==null) return '';
    // these don't work but should
    s = s.replaceAll('–', "-");
    s = s.replaceAll('“', '"');
    s = s.replaceAll("’", "'");
    s = s.replaceAll('…', '...');
    // the data must get warped into something like this in transit ?!?
    s = s.replaceAll("â¦", "...");
    s = s.replaceAll("â", "-");
    s = s.replaceAll("â", "'");
    return s;
  }

}

/*

Lessons come in this format : 

{
  "lessonShortTitle": "Let me not bind Your Son with laws I made",
  "lessonNumber": "Lesson 277",
  "lessonTitle": "Let me not bind Your Son with laws I made",
  "lessonText": "<div class=\"acim-text lesson-277\"> <div data-paragraph-id=\"694#1\"><p class=\"p-italic\"><span class=\"pnr\">1.</span> <span data-sentence-id=\"694#1:1\"><span class=\"snr noprint\">1</span>Your Son is free, my Father.</span> <span data-sentence-id=\"694#1:2\"><span class=\"snr\">2</span>Let me not imagine I have bound him with the laws I made to rule the body.</span> <span data-sentence-id=\"694#1:3\"><span class=\"snr\">3</span>He is not subject to any laws I made by which I try to make the body more secure.</span> <span data-sentence-id=\"694#1:4\"><span class=\"snr\">4</span>He is not changed by what is changeable.</span> <span data-sentence-id=\"694#1:5\"><span class=\"snr\">5</span>He is not slave to any laws of time.</span> <span data-sentence-id=\"694#1:6\"><span class=\"snr\">6</span>He is as You created him, because he knows no law except the law of love.</span></p></div> <div data-paragraph-id=\"694#2\"><p class=\"p-normal\"><span class=\"pnr\">2.</span> <span data-sentence-id=\"694#2:1\"><span class=\"snr noprint\">1</span>Let us not worship idols, nor believe in any law idolatry would make to hide the freedom of the Son of God.</span> <span data-sentence-id=\"694#2:2\"><span class=\"snr\">2</span>He is not bound except by his beliefs.</span> <span data-sentence-id=\"694#2:3\"><span class=\"snr\">3</span>Yet what he is, is far beyond his faith in slavery or freedom.</span> <span data-sentence-id=\"694#2:4\"><span class=\"snr\">4</span>He is free because he is his Father’s Son.</span> <span data-sentence-id=\"694#2:5\"><span class=\"snr\">5</span>And he cannot be bound unless God’s truth can lie, and God can will that He deceive Himself.</span></p></div> </div>",
  "fullTitle": "Let me not bind Your Son with laws I made.",
  "audio": "https://acim.org/audio/web-edition/3cc31c741c385714ca109d40dd6d225c.mp4",
  "link": "https://acim.org/acim/lesson-277/let-me-not-bind-your-son-with-laws-i-made/en/s/694?wid=toc"
}

*/