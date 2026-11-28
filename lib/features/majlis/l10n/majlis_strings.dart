import 'package:flutter/widgets.dart';

import '../domain/majlis_models.dart';
import '../majlis_theme.dart';

/// Every word Majlis shows, in English, Dari (fa) and Pashto (ps).
///
/// Each entry is [English, Dari, Pashto] so a reviewer can read the three
/// side by side. The language follows the app (WellMate's LocaleProvider sets
/// MaterialApp.locale), so nothing extra is needed when integrating.
/// Placeholders look like {name}. Numbers, days and times use Persian digits
/// in Dari and Pashto.
///
/// For the native Pashto reviewer, please check first: remindMe, scheduledFor,
/// reminderSet, spacesIn, the singulars goingOne / wantToSpeakOne / blockedOne,
/// the weekday names, «ژوندۍ» for LIVE and «لمرګلی» (sunflower).
class MajlisStrings {
  MajlisStrings(this.lang) : _i = lang == 'fa' ? 1 : (lang == 'ps' ? 2 : 0);

  final String lang;
  final int _i;

  static MajlisStrings of(BuildContext context) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    MajlisText.setLanguage(code);
    return MajlisStrings(code);
  }

  bool get rtl => _i != 0;

  String t(String key, [Map<String, Object> args = const {}]) {
    final row = _t[key];
    var s = row == null ? key : row[_i];
    args.forEach((k, v) => s = s.replaceAll('{$k}', v is int ? n(v) : '$v'));
    return s;
  }

  // ---- Numbers, days and times -------------------------------------------------

  static const _digits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  /// A number in the user's digits.
  String n(num value) => digits('$value');

  /// Any text with Western digits, in the user's digits.
  String digits(String s) {
    if (_i == 0) return s;
    return s.split('').map((c) {
      final d = int.tryParse(c);
      return d == null ? (c == '.' ? '٫' : c) : _digits[d];
    }).join();
  }

  String time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final pm = t.hour >= 12;
    return switch (_i) {
      1 => '${digits('$h:$m')} ${pm ? 'ب.ظ' : 'ق.ظ'}',
      2 => '${digits('$h:$m')} ${pm ? 'غ.و' : 'غ.م'}',
      _ => '$h:$m ${pm ? 'PM' : 'AM'}',
    };
  }

  /// Monday = 1 ... Sunday = 7.
  String weekday(int weekday) => _weekdays[_i][weekday - 1];

  /// "Tonight", "Tomorrow", "Wed"...
  String day(DateTime t, {DateTime? now}) {
    final n0 = now ?? DateTime.now();
    final diff = DateTime(t.year, t.month, t.day).difference(DateTime(n0.year, n0.month, n0.day)).inDays;
    if (diff == 0) return t.hour >= 17 ? this.t('tonight') : this.t('today');
    if (diff == 1) return this.t('tomorrow');
    return weekday(t.weekday);
  }

  String when(DateTime t) => '${day(t)} · ${time(t)}';

  static const _weekdays = [
    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'],
    ['دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه'],
  ];

  /// English needs "1 space / 2 spaces"; Dari and Pashto use one form here.
  String count(int value, String one, String many) => t(value == 1 ? one : many, {'n': value});

  String minutes(int m) => m < 1 ? t('aFewMoments') : count(m, 'minuteOne', 'minutes');

  String duration(int minutes) {
    if (minutes < 60) return count(minutes, 'minuteShortOne', 'minutesShort');
    final h = minutes / 60;
    return t('hoursShort', {'n': digits(h.toStringAsFixed(h < 10 ? 1 : 0))});
  }

  // ---- Names of things -----------------------------------------------------

  /// A veil name from the fixed list. Anything else (an old or tampered
  /// profile) shows as "Guest", never as raw text.
  String veil(String key) => _t.containsKey('veil.$key') ? t('veil.$key') : t('guest');

  /// What others see: a guide's name, or the veil in this language.
  String name(MajlisPerson p) {
    final g = p.guideName ?? '';
    if (p.isGuide && g.isNotEmpty) return t('guideName', {'name': g});
    return p.veil.isEmpty ? '…' : veil(p.veil);
  }
  String topic(String id) => t('topic.$id');
  String reaction(String id) => t('react.$id');
  String langName(String code) => switch (code) { 'fa' => 'دری', 'ps' => 'پښتو', _ => 'English' };
  String langShort(String code) => switch (code) { 'fa' => 'دری', 'ps' => 'پښتو', _ => 'EN' };

  /// Server error keys (see functions/majlis.js) to friendly words.
  String error(String code) => _t.containsKey('err.$code') ? t('err.$code') : t('err.generic');

  static const _t = <String, List<String>>{
    // Hallway
    'majlis': ['Majlis', 'مجلس', 'مجلس'],
    'guest': ['Guest', 'مهمان', 'مېلمه'],
    'tagline': ['Sit together. Heard, never seen.', 'دور هم بنشینیم. شنیده می‌شویم، دیده نه.', 'سره کېنو. اورېدل کېږو، لیدل نه.'],
    'peopleNow': ['{people} in {spaces} right now', 'همین حالا {people} در {spaces}', 'همدا اوس {people} په {spaces} کې'],
    'personOne': ['{n} person', '{n} نفر', '{n} کس'],
    'peopleN': ['{n} people', '{n} نفر', '{n} کسان'],
    'quietNow': ['Quiet right now. Open the first space.', 'فعلاً آرام است. اولین مجلس را باز کنید.', 'اوس ارامه ده. لومړی مجلس پرانیزئ.'],
    // WellMate Home (feeling sheet)
    'sitWithOthers': ['Sit with others in Majlis', 'با دیگران در مجلس بنشینید', 'له نورو سره په مجلس کې کېنئ'],
    'hereNow': ['{people} here now', 'همین حالا {people} اینجا', 'همدا اوس {people} دلته'],
    'peopleIn': ['{people} in {spaces}', '{people} در {spaces}', '{people} په {spaces} کې'],
    'profileTip': ['Your Majlis profile', 'پروفایل مجلس شما', 'ستاسو د مجلس پروفایل'],
    'all': ['All', 'همه', 'ټول'],
    'startingSoon': ['Starting soon', 'به‌زودی', 'ژر پیلېږي'],
    'scheduledN': ['{n} scheduled', '{n} برنامه', '{n} ټاکل شوي'],
    'liveNow': ['Live now', 'همین حالا', 'همدا اوس'],
    'spaceOne': ['{n} space', '{n} مجلس', '{n} مجلس'],
    'spaces': ['{n} spaces', '{n} مجلس', '{n} مجلسونه'],
    'spacesIn': ['{n} spaces', '{n} مجلس', '{n} مجلسونو'],
    'emptyTitle': ['No one is here yet', 'هنوز کسی نیامده', 'لا څوک نه دي راغلي'],
    'emptyBody': ['Open the first space, or schedule one for later', 'اولین مجلس را باز کنید، یا برای بعد برنامه بگذارید', 'لومړی مجلس پرانیزئ، یا یې د وروسته لپاره وټاکئ'],
    'startSpace': ['Start a space', 'مجلس باز کن', 'مجلس پرانیزه'],
    'join': ['Join', 'بیا', 'راشه'],
    'live': ['LIVE', 'زنده', 'ژوندی'],
    'ledByGuide': ['Led by a WellMate guide', 'با رهنمای WellMate', 'د WellMate لارښود سره'],
    'youreHosting': ["You're hosting", 'میزبان شما هستید', 'تاسو کوربه یاست'],
    'womenOnly': ['Women only', 'فقط زنان', 'یوازې ښځې'],
    'inviteOnly': ['Invite only', 'فقط با دعوت', 'یوازې په بلنه'],
    'goingN': ['{n} going', '{n} نفر می‌آیند', '{n} کسان راځي'],
    'goingOne': ['{n} going', '{n} نفر می‌آید', '{n} کس راځي'],
    'remindMe': ['Remind me', 'یادآوری کن', 'یادونه راکړه'],
    'reminderOn': ['Reminder on', 'یادآوری روشن', 'یادونه روښانه ده'],
    'haveCode': ['Have an invite code?', 'کد دعوت دارید؟', 'د بلنې کوډ لرئ؟'],
    'offline': ["Can't reach Majlis. Check your internet.", 'به مجلس وصل نمی‌شویم. انترنت را ببینید.', 'مجلس ته نه شو نښلېدلی. انټرنیټ وګورئ.'],
    'tryAgain': ['Try again', 'دوباره', 'بیا هڅه'],
    'today': ['Today', 'امروز', 'نن'],
    'tonight': ['Tonight', 'امشب', 'نن شپه'],
    'tomorrow': ['Tomorrow', 'فردا', 'سبا'],

    // Veil (first visit)
    'welcome': ['WELCOME TO MAJLIS', 'به مجلس خوش آمدید', 'مجلس ته ښه راغلاست'],
    'inHereYouAre': ['In here, you are', 'اینجا شما', 'دلته تاسو'],
    'anotherName': ['Another name', 'نام دیگر', 'بل نوم'],
    'promiseNames': ['No real names, no photos', 'نه نام واقعی، نه عکس', 'نه اصلي نوم، نه انځور'],
    'promiseRecorded': ['Nothing is recorded', 'هیچ چیزی ضبط نمی‌شود', 'هېڅ شی نه ثبتېږي'],
    'promiseKind': ['Kindness first. Hosts can remove anyone', 'اول مهربانی. میزبان می‌تواند هر کسی را بیرون کند', 'لومړی مهرباني. کوربه هر څوک ایستلی شي'],
    'takeSeat': ['Take a seat', 'بنشینید', 'کېنئ'],

    // Profile
    'yourName': ['Your Majlis name. Your real name is never shown.', 'نام شما در مجلس. نام واقعی شما هرگز نشان داده نمی‌شود.', 'په مجلس کې ستاسو نوم. اصلي نوم مو هېڅکله نه ښودل کېږي.'],
    'changeName': ['Change name', 'تغییر نام', 'نوم بدل کړئ'],
    'changePicture': ['Change picture', 'تغییر تصویر', 'انځور بدل کړئ'],
    'picture': ['Picture', 'تصویر', 'انځور'],
    'colour': ['Colour', 'رنگ', 'رنګ'],
    'pictureN': ['Picture {n}', 'تصویر {n}', 'انځور {n}'],
    'colourN': ['Colour {n}', 'رنگ {n}', 'رنګ {n}'],
    'save': ['Save', 'ذخیره', 'خوندي کړئ'],
    'statJoined': ['Spaces joined', 'مجلس‌هایی که رفتید', 'ګډون شوي مجلسونه'],
    'statListening': ['Time in Majlis', 'زمان در مجلس', 'په مجلس کې وخت'],
    'statTea': ['Cups of tea', 'پیاله‌های چای', 'د چای پیالې'],
    'statHosted': ['Spaces hosted', 'میزبانی‌ها', 'کوربه‌توبونه'],
    'onlyYou': ['Only you can see these numbers', 'این ارقام را فقط شما می‌بینید', 'دا شمېرې یوازې تاسو ګورئ'],
    'womenSpaces': ["Women's spaces", 'مجلس‌های زنان', 'د ښځو مجلسونه'],
    'womenSpacesOn': ['You said you are a woman', 'گفته‌اید که زن هستید', 'ویلي مو دي چې ښځه یاست'],
    'womenSpacesOff': ['Not confirmed', 'تأیید نشده', 'نه دی تایید شوی'],
    'blockedN': ['{n} people blocked', '{n} نفر مسدود', '{n} کسان بند شوي'],
    'blockedOne': ['{n} person blocked', '{n} نفر مسدود', '{n} کس بند شوی'],
    'unblockAll': ['Unblock all', 'آزاد کردن همه', 'ټول خلاص کړئ'],
    'done': ['Done', 'تمام', 'بس'],
    'minutesShort': ['{n} min', '{n} دقیقه', '{n} دقیقې'],
    'minuteShortOne': ['{n} min', '{n} دقیقه', '{n} دقیقه'],
    'hoursShort': ['{n} h', '{n} ساعت', '{n} ساعته'],

    // Start or schedule
    'startSub': ['Open it now, or schedule it so people can plan to come.', 'همین حالا باز کنید، یا برنامه بگذارید تا دیگران هم بیایند.', 'همدا اوس یې پرانیزئ، یا یې وټاکئ چې نور هم راشي.'],
    'goLiveNow': ['Go live now', 'همین حالا شروع', 'همدا اوس پیل'],
    'schedule': ['Schedule', 'برنامه', 'وټاکه'],
    'day': ['Day', 'روز', 'ورځ'],
    'time': ['Time', 'ساعت', 'وخت'],
    'otherTime': ['Other', 'دیگر', 'بل'],
    'tooSoon': ['Pick a time at least 10 minutes from now', 'وقتی را انتخاب کنید که دست‌کم ۱۰ دقیقه بعد باشد', 'داسې وخت وټاکئ چې لږ تر لږه ۱۰ دقیقې وروسته وي'],
    'scheduledFor': ['{when}. People who tap Remind me get a reminder.', '{when}. کسانی که «یادآوری کن» را بزنند یادآوری می‌گیرند.', '{when}. څوک چې «یادونه راکړه» کېکاږي، یادونه ترلاسه کوي.'],
    'title': ['Title', 'عنوان', 'سرلیک'],
    'titleHint': ['What would you like to talk about?', 'درباره چه می‌خواهید صحبت کنید؟', 'د څه په اړه خبرې کول غواړئ؟'],
    'topicLabel': ['Topic', 'موضوع', 'موضوع'],
    'language': ['Language', 'زبان', 'ژبه'],
    'whoCanJoin': ['Who can join', 'چه کسی بیاید', 'څوک راتلی شي'],
    'open': ['Open', 'باز', 'خلاص'],
    'openSub': ['Anyone on WellMate', 'همه در WellMate', 'په WellMate کې هرڅوک'],
    'women': ['Women', 'زنان', 'ښځې'],
    'invite': ['Invite', 'دعوت', 'بلنه'],
    'inviteSub': ['With your code', 'با کد شما', 'ستاسو په کوډ'],
    'questionLabel': ['Opening question (optional)', 'سؤال آغاز (اختیاری)', 'د پیل پوښتنه (اختیاري)'],
    'questionHint': ['e.g. What went right this week?', 'مثلاً: این هفته چه چیزی خوب پیش رفت؟', 'لکه: پدې اونۍ کې څه شی ښه شو؟'],
    'takeTurns': ['Take turns', 'نوبتی', 'په وار'],
    'takeTurnsSub': ['Each voice gets 2 minutes, in order', 'هر صدا ۲ دقیقه، به ترتیب', 'هر غږ ته ۲ دقیقې، په ترتیب'],
    'scheduleSpace': ['Schedule space', 'برنامه بگذار', 'مجلس وټاکه'],
    'idea.sleep': ["Can't sleep? Let's talk", 'خوابت نمی‌برد؟ بیا گپ بزنیم', 'خوب نه درځي؟ راځه خبرې وکړو'],
    'idea.chai': ['Evening chai and small talk', 'چای شام و گپ کوتاه', 'د ماښام چای او لنډې خبرې'],
    'idea.study': ['Exam stress, together', 'استرس امتحان، با هم', 'د ازموینې فشار، یوځای'],
    'idea.poetry': ['Poems we grew up with', 'شعرهایی که با آن بزرگ شدیم', 'هغه شعرونه چې ورسره لوی شوي یو'],
    'idea.hope': ['One small win today', 'یک موفقیت کوچک امروز', 'د نن یوه کوچنۍ بریا'],
    'idea.home': ['Missing home tonight', 'امشب دلم برای وطن تنگ است', 'نن شپه د وطن ارمان لرم'],

    // Scheduled space
    'hosting': ['Hosting', 'میزبان', 'کوربه'],
    'guideHosting': ['WellMate guide · hosting', 'رهنمای WellMate · میزبان', 'د WellMate لارښود · کوربه'],
    'you': ['You', 'شما', 'تاسو'],
    'youName': ['{name} (you)', '{name} (شما)', '{name} (تاسو)'],
    'startNow': ['Start now', 'شروع کن', 'پیل یې کړه'],
    'shareInvite': ['Share invite', 'فرستادن دعوت', 'بلنه ولېږه'],
    'share': ['Share', 'فرستادن', 'شریکول'],
    'cancelSpace': ['Cancel space', 'لغو مجلس', 'مجلس لغوه کړه'],
    'cancelQ': ['Cancel this space?', 'این مجلس لغو شود؟', 'دا مجلس لغوه شي؟'],
    'cancelBody': ['People who planned to come will see it was cancelled.', 'کسانی که قصد آمدن داشتند می‌بینند که لغو شد.', 'هغه کسان چې راتلل یې غوښتل، وبه ګوري چې لغوه شو.'],
    'keepIt': ['Keep it', 'بماند', 'پرېږده یې'],
    'inviteText': ['Join me in Majlis on WellMate: "{title}". Invite code: {code}', 'در مجلس WellMate با من باشید: «{title}». کد دعوت: {code}', 'په WellMate مجلس کې راسره یوځای شئ: «{title}». د بلنې کوډ: {code}'],
    'shareText': ['Join me in Majlis on WellMate: "{title}", {when}', 'در مجلس WellMate با من باشید: «{title}»، {when}', 'په WellMate مجلس کې راسره یوځای شئ: «{title}»، {when}'],
    'inviteCopied': ['Invite copied. Send it to someone you trust.', 'دعوت کاپی شد. برای کسی بفرستید که به او اعتماد دارید.', 'بلنه کاپي شوه. هغه چاته یې ولېږئ چې باور پرې لرئ.'],
    'spaceCancelled': ['Space cancelled', 'مجلس لغو شد', 'مجلس لغوه شو'],
    'scheduledToast': ['Scheduled for {when}', 'برنامه شد برای {when}', 'د {when} لپاره وټاکل شو'],
    'notStartedYet': ['Starts {when}', 'شروع: {when}', 'پیل: {when}'],

    // After leaving
    'thanksHosting': ['THANK YOU FOR HOSTING', 'سپاس از میزبانی شما', 'د کوربه‌توب مننه'],
    'spaceEndedCaps': ['THE SPACE HAS ENDED', 'مجلس پایان یافت', 'مجلس پای ته ورسېد'],
    'afterVisitCaps': ['AFTER YOUR VISIT', 'پس از این دیدار', 'له دې لیدنې وروسته'],
    'leftQuietly': ['YOU LEFT QUIETLY', 'آرام بیرون شدید', 'په ارامۍ ووتلئ'],
    'youSatFor': ['You sat for {time}', '{time} نشستید', '{time} کېناستلئ'],
    'aFewMoments': ['a few moments', 'چند لحظه', 'څو شېبې'],
    'minuteOne': ['{n} minute', '{n} دقیقه', '{n} دقیقه'],
    'minutes': ['{n} minutes', '{n} دقیقه', '{n} دقیقې'],
    'staysHere': ['What was said stays in the majlis', 'آنچه گفته شد، در مجلس می‌ماند', 'څه چې وویل شول، په مجلس کې پاتې کېږي'],
    'teaOne': ['{n} cup of tea for you', '{n} پیاله چای برای شما', 'ستاسو لپاره {n} پیاله چای'],
    'teaMany': ['{n} cups of tea for you', '{n} پیاله چای برای شما', 'ستاسو لپاره {n} پیالې چای'],
    'teaSub': ['People were grateful for what you shared', 'دیگران از گفته‌های شما سپاسگزار بودند', 'خلکو ستاسو له خبرو مننه وکړه'],
    'howFeel': ['How do you feel now?', 'حالا چه حسی دارید؟', 'اوس څنګه احساس کوئ؟'],
    'mood0': ['Calm', 'آرام', 'ارام'],
    'mood1': ['Good', 'خوب', 'ښه'],
    'mood2': ['Tired', 'خسته', 'ستړی'],
    'mood3': ['Anxious', 'نگران', 'اندېښمن'],
    'mood4': ['Sad', 'غمگین', 'خپه'],
    'moodReply0': ['Lighter than before. That is worth noticing.', 'سبک‌تر از قبل. این ارزش توجه دارد.', 'تر مخکې سپک. دا د پام وړ دی.'],
    'moodReply1': ['Lighter than before. That is worth noticing.', 'سبک‌تر از قبل. این ارزش توجه دارد.', 'تر مخکې سپک. دا د پام وړ دی.'],
    'moodReply2': ['Rest is allowed. A slow breath before bed may help.', 'استراحت حق شماست. یک نفس آرام پیش از خواب کمک می‌کند.', 'ارام کول ستاسو حق دی. د خوب مخکې یوه ورو ساه کېدای شي مرسته وکړي.'],
    'moodReply3': ['Still heavy, and that is okay. WellMate is here any time.', 'هنوز سنگین است و اشکالی ندارد. WellMate همیشه اینجاست.', 'لا هم دروند دی، او سمه ده. WellMate هر وخت دلته دی.'],
    'moodReply4': ['Thank you for being honest. You are not alone in this.', 'ممنون که صادق بودید. شما در این تنها نیستید.', 'مننه چې رښتیا مو وویل. تاسو پدې کې یوازې نه یاست.'],
    'journeyDone': ["Today's journey step is done", 'قدم امروز سفر شما انجام شد', 'د نن ورځې د سفر ګام بشپړ شو'],
    'backToHallway': ['Back to the hallway', 'بازگشت به دهلیز', 'دهلیز ته ستنېدل'],

    // Room
    'hallway': ['Hallway', 'دهلیز', 'دهلیز'],
    'help': ['Help', 'کمک', 'مرسته'],
    'hostTools': ['Host tools', 'ابزار میزبان', 'د کوربه وسایل'],
    'more': ['More', 'بیشتر', 'نور'],
    'notRecorded': ['Not recorded', 'ضبط نمی‌شود', 'نه ثبتېږي'],
    'whisperEyebrow': ['A WHISPER FROM THE CIRCLE', 'نجوایی از جمع', 'د حلقې یو پټ پیغام'],
    'onTheCarpet': ['ON THE CARPET', 'روی قالین', 'پر غالۍ'],
    'onStage': ['On stage', 'روی صحنه', 'په سټېج'],
    'turnsChip': ['Turns · 2 min', 'نوبتی · ۲ دقیقه', 'په وار · ۲ دقیقې'],
    'saySalaam': ['Say salaam to open', 'با سلام شروع کنید', 'په سلام یې پیل کړئ'],
    'quietMoment': ['Quiet moment', 'لحظه آرام', 'ارامه شېبه'],
    'youreSpeaking': ["You're speaking", 'شما صحبت می‌کنید', 'تاسو خبرې کوئ'],
    'isSpeaking': ['{name} is speaking', '{name} صحبت می‌کند', '{name} خبرې کوي'],
    'yourTurn': ['Your turn', 'نوبت شما', 'ستاسو وار'],
    'nextVoice': ['Next voice', 'صدای بعدی', 'بل غږ'],
    'guide': ['WellMate guide', 'رهنمای WellMate', 'د WellMate لارښود'],
    'guideName': ['Guide {name}', 'رهنما {name}', 'لارښود {name}'],
    'host': ['Host', 'میزبان', 'کوربه'],
    'listening': ['Listening', 'شنونده‌ها', 'اورېدونکي'],
    'wantToSpeak': ['{n} want to speak', '{n} نفر می‌خواهند صحبت کنند', '{n} کسان غواړي خبرې وکړي'],
    'wantToSpeakOne': ['{n} wants to speak', '{n} نفر می‌خواهد صحبت کند', '{n} کس غواړي خبرې وکړي'],
    'leaveQuietly': ['Leave quietly', 'آرام بیرون شو', 'په ارامۍ ووځه'],
    'teaTip': ['Pour tea for whoever is speaking', 'برای کسی که صحبت می‌کند چای بریز', 'چا چې خبرې کوي، هغه ته چای واچوه'],
    'reactTip': ['React', 'واکنش', 'غبرګون'],
    'mute': ['Mute', 'خاموش', 'غلی'],
    'unmute': ['Unmute', 'روشن', 'خلاص'],
    'writeInstead': ['Write instead of speaking', 'به جای حرف زدن بنویس', 'د خبرو پر ځای ولیکه'],
    'raisedHands': ['Raised hands', 'دست‌های بلند', 'پورته لاسونه'],
    'backToListening': ['Back to listening', 'بازگشت به شنیدن', 'بېرته اورېدو ته'],
    'raiseHand': ['Raise your hand to speak', 'برای صحبت دست بلند کنید', 'د خبرو لپاره لاس پورته کړئ'],
    'lowerHand': ['Lower your hand', 'دست را پایین بیاورید', 'لاس ښکته کړئ'],
    'react.love': ['Love', 'عشق', 'مینه'],
    'react.withyou': ['With you', 'همراهت', 'درسره یم'],
    'react.calm': ['Calm', 'آرام', 'ارام'],
    'react.beautiful': ['Beautiful', 'زیبا', 'ښکلی'],
    'react.haha': ['Haha', 'خنده', 'خندا'],
    'react.tea': ['Tea', 'چای', 'چای'],
    'invitedYou': ['{name} invited you to speak', '{name} شما را به صحبت دعوت کرد', '{name} تاسو خبرو ته راوبللئ'],
    'invitedSub': ['Say as much or as little as you like', 'هر قدر که دوست دارید بگویید', 'څومره چې مو زړه غواړي، ووایاست'],
    'joinStage': ['Join the stage', 'رفتن به صحنه', 'سټېج ته ورشه'],
    'notNow': ['Not now', 'حالا نه', 'اوس نه'],
    'breatheInvite': ['{name} invites everyone to breathe together', '{name} همه را به نفس کشیدن با هم دعوت می‌کند', '{name} ټول په ګډه ساه اخیستو ته رابولي'],
    'breatheSub': ['One quiet minute, all at once', 'یک دقیقه آرام، همه با هم', 'یوه ارامه دقیقه، ټول یوځای'],
    'breathe': ['Breathe', 'نفس بکش', 'ساه واخله'],
    'breathingTogether': ['BREATHING TOGETHER', 'نفس کشیدن با هم', 'په ګډه ساه اخیستل'],
    'breathingAlone': ['ONE QUIET MINUTE', 'یک دقیقه آرام', 'یوه ارامه دقیقه'],
    'breatheIn': ['Breathe in', 'دم', 'ساه واخله'],
    'breatheOut': ['Breathe out', 'بازدم', 'ساه وباسه'],
    'breathingWithYou': ['{n} people breathing with you', '{n} نفر با شما نفس می‌کشند', '{n} کسان درسره ساه اخلي'],
    'breathingWithYouOne': ['{n} person breathing with you', '{n} نفر با شما نفس می‌کشد', '{n} کس درسره ساه اخلي'],
    'imBack': ["I'm back", 'برگشتم', 'راستون شوم'],
    'takingSeat': ['Taking your seat…', 'در حال نشستن…', 'کېناستل…'],
    'reconnecting': ['Reconnecting…', 'دوباره وصل می‌شویم…', 'بیا نښلېږو…'],
    'hostAway': ['The host stepped out. The space waits a few minutes.', 'میزبان بیرون رفت. مجلس چند دقیقه منتظر می‌ماند.', 'کوربه ووت. مجلس څو دقیقې انتظار باسي.'],
    'tapToHear': ['Tap to turn on sound', 'برای شنیدن صدا بزنید', 'د غږ لپاره کېکاږئ'],

    // Toasts
    'pouredTea': ['You poured tea for {name}', 'برای {name} چای ریختید', '{name} ته مو چای واچاوه'],
    'teaToSpeaker': ['Tea goes to whoever is speaking', 'چای به کسی می‌رسد که صحبت می‌کند', 'چای هغه چا ته ځي چې خبرې کوي'],
    'pouredYou': ['{name} poured you tea', '{name} برای شما چای ریخت', '{name} تاسو ته چای واچاوه'],
    'mutedForMe': ['{name} is muted, only for you', '{name} فقط برای شما خاموش شد', '{name} یوازې ستاسو لپاره غلی شو'],
    'hearAgain': ['You can hear {name} again', 'دوباره صدای {name} را می‌شنوید', 'د {name} غږ بیا اورئ'],
    'reported': ['Thank you. The WellMate team will review it privately', 'سپاس. تیم WellMate آن را محرمانه بررسی می‌کند', 'مننه. د WellMate ټیم به یې په پټه وګوري'],
    'blocked': ["Blocked. You won't meet {name} in Majlis", 'مسدود شد. دیگر {name} را در مجلس نمی‌بینید', 'بند شو. نور به {name} په مجلس کې ونه وینئ'],
    'whisperSent': ['Sent to {name}, without your name', 'بدون نام شما برای {name} فرستاده شد', 'ستاسو له نوم پرته {name} ته ولېږل شو'],
    'handRaised': ['Hand raised. {name} can see it', 'دست بلند شد. {name} آن را می‌بیند', 'لاس پورته شو. {name} یې ویني'],
    'handLowered': ['Hand lowered', 'دست پایین شد', 'لاس ښکته شو'],
    'hostSaidNotNow': ['The host said not now. You can raise your hand again later.', 'میزبان گفت حالا نه. بعداً دوباره دست بلند کنید.', 'کوربه وویل اوس نه. وروسته بیا لاس پورته کړئ.'],
    'youreOnStage': ["You're on stage", 'روی صحنه هستید', 'په سټېج یاست'],
    'micOn': ['Mic on', 'مایکروفون روشن', 'مایک روښانه'],
    'micOff': ['Mic off', 'مایکروفون خاموش', 'مایک بند'],
    'micDenied': ['Majlis needs the microphone so you can speak. Allow it in Settings.', 'برای صحبت، مجلس به مایکروفون نیاز دارد. در تنظیمات اجازه دهید.', 'د خبرو لپاره مجلس مایکروفون ته اړتیا لري. په تنظیماتو کې یې اجازه ورکړئ.'],
    'settings': ['Settings', 'تنظیمات', 'تنظیمات'],
    'micPaused': ['Your mic paused while Majlis was in the background', 'وقتی مجلس در پس‌زمینه بود، مایکروفون شما خاموش شد', 'کله چې مجلس شاته و، ستاسو مایک بند شو'],
    'invitedToSpeak': ['{name} is invited to speak', '{name} به صحبت دعوت شد', '{name} خبرو ته وبلل شو'],
    'isOnStage': ['{name} is on stage', '{name} روی صحنه است', '{name} په سټېج دی'],
    'canRaiseLater': ['{name} can raise a hand again later', '{name} می‌تواند بعداً دوباره دست بلند کند', '{name} وروسته بیا لاس پورته کولی شي'],
    'everyoneMuted': ['Everyone on stage is muted', 'همه روی صحنه خاموش شدند', 'په سټېج ټول غلي شول'],
    'hostMutedYou': ['The host muted your mic', 'میزبان مایکروفون شما را خاموش کرد', 'کوربه ستاسو مایک بند کړ'],
    'movedToListeners': ['The host moved you back to listening', 'میزبان شما را به شنونده‌ها برگرداند', 'کوربه تاسو بېرته اورېدونکو ته ولېږلئ'],
    'turnsOn': ['Taking turns: each voice gets 2 minutes', 'نوبتی: هر صدا ۲ دقیقه', 'په وار: هر غږ ته ۲ دقیقې'],
    'turnsOff': ['Open conversation', 'گفتگوی آزاد', 'خلاصې خبرې'],
    'pinnedToast': ['Pinned for everyone', 'برای همه نمایش داده شد', 'د ټولو لپاره ونښلول شو'],
    'unpinned': ['Taken off the carpet', 'از روی قالین برداشته شد', 'له غالۍ لرې شو'],
    'removedPerson': ['{name} was removed from this space', '{name} از این مجلس بیرون شد', '{name} له دې مجلس څخه وایستل شو'],

    // Endings
    'endedByHost': ['The host closed this space gently', 'میزبان مجلس را آرام بست', 'کوربه مجلس په ارامۍ وتاړه'],
    'removedYou': ['You were removed from this space', 'شما از این مجلس بیرون شدید', 'تاسو له دې مجلس څخه وایستل شوئ'],
    'otherDevice': ['You joined from another device', 'از دستگاه دیگری وارد شدید', 'تاسو له بلې وسیلې ننوتلئ'],
    'connectionLost': ['The connection was lost', 'ارتباط قطع شد', 'اړیکه پرې شوه'],

    // Person card
    'listeningRole': ['Listening', 'شنونده', 'اورېدونکی'],
    'nobodySeesName': ['Nobody sees your real name.', 'هیچ کس نام واقعی شما را نمی‌بیند.', 'هېڅوک ستاسو اصلي نوم نه ویني.'],
    'pourTea': ['Pour tea', 'چای بریز', 'چای واچوه'],
    'pourAnother': ['Pour another cup', 'یک پیاله دیگر', 'بله پیاله'],
    'teaExplain': ['A quiet thank-you. They see the tea, never your name', 'یک تشکر آرام. چای را می‌بینند، نه نام شما را', 'یوه ارامه مننه. چای ویني، ستاسو نوم نه'],
    'inviteToStage': ['Invite to the stage', 'دعوت به صحنه', 'سټېج ته بلنه'],
    'moveToListeners': ['Move back to listening', 'برگرداندن به شنونده‌ها', 'بېرته اورېدونکو ته'],
    'muteTheirMic': ['Mute their mic', 'خاموش کردن مایکروفون', 'مایک یې بند کړه'],
    'removeFromSpace': ['Remove from this space', 'بیرون کردن از مجلس', 'له مجلس څخه ایستل'],
    'removeQ': ['Remove {name}?', '{name} بیرون شود؟', '{name} وایستل شي؟'],
    'removeBody': ["They can't come back to this space.", 'دیگر نمی‌توانند به این مجلس برگردند.', 'دوی بیا دې مجلس ته نه شي راتلای.'],
    'remove': ['Remove', 'بیرون کن', 'وباسه'],
    'muteForMe': ['Mute for me', 'برای من خاموش', 'زما لپاره غلی'],
    'unmuteForMe': ['Hear again', 'دوباره بشنو', 'بیا یې واوره'],
    'report': ['Report', 'گزارش', 'راپور'],
    'block': ['Block', 'مسدود', 'بندول'],
    'blockQ': ['Block {name}?', '{name} مسدود شود؟', '{name} بند شي؟'],
    'blockBody': ["You won't hear them, and they can't join your spaces.", 'صدای او را نمی‌شنوید و او نمی‌تواند به مجلس‌های شما بیاید.', 'غږ به یې وانه ورئ، او ستاسو مجلسونو ته نه شي راتلای.'],
    'reportTitle': ['What happened?', 'چه اتفاقی افتاد؟', 'څه پېښ شول؟'],
    'reportSub': ['Only the WellMate team sees this. They never see who sent it.', 'فقط تیم WellMate این را می‌بیند. نام فرستنده را به کسی نمی‌گویند.', 'دا یوازې د WellMate ټیم ویني. د لېږونکي نوم چاته نه ویل کېږي.'],
    'reason.unsafe': ['Someone may be in danger', 'ممکن کسی در خطر باشد', 'کېدای شي څوک په خطر کې وي'],
    'reason.harassment': ['Harassment or hate', 'آزار یا نفرت', 'ځورونه یا کرکه'],
    'reason.identity': ["Shared someone's real name or details", 'نام یا جزئیات واقعی کسی را گفت', 'د چا اصلي نوم یا معلومات یې وویل'],
    'reason.spam': ['Spam or selling', 'تبلیغ یا فروش', 'اعلان یا پلور'],
    'reason.other': ['Something else', 'چیز دیگر', 'بل څه'],
    'sendReport': ['Send report', 'فرستادن گزارش', 'راپور ولېږه'],
    'cancel': ['Cancel', 'لغو', 'لغوه'],

    // Help
    'notAlone': ["You're not alone", 'شما تنها نیستید', 'تاسو یوازې نه یاست'],
    'stepOut': ['Step out for a moment. Nobody in the room will know.', 'یک لحظه بیرون بیایید. هیچ‌کس در مجلس نمی‌فهمد.', 'یوه شېبه ووځئ. په مجلس کې به هېڅوک پوه نه شي.'],
    'talkToWellMate': ['Talk to WellMate', 'با WellMate صحبت کنید', 'له WellMate سره خبرې وکړئ'],
    'talkToWellMateSub': ['Private, any time of night', 'محرمانه، هر ساعت شب', 'پټ، د شپې هر وخت'],
    'writeToHost': ['Write to {name}', 'به {name} بنویسید', '{name} ته ولیکئ'],
    'writeToHostSub': ['Only the host sees it, without your name', 'فقط میزبان می‌بیند، بدون نام شما', 'یوازې کوربه یې ویني، ستاسو له نوم پرته'],
    'helplines': ['Helplines', 'شماره‌های کمک', 'د مرستې شمېرې'],
    'helplinesSub': ['When it feels urgent', 'وقتی فوری است', 'کله چې بیړنی وي'],
    'breatheMinute': ['Breathe for a minute', 'یک دقیقه نفس بکشید', 'یوه دقیقه ساه واخلئ'],
    'breatheMinuteSub': ['Then come back, or not', 'بعد برگردید، یا نه', 'بیا راستانه شئ، یا نه'],
    'numberCopied': ['Number copied', 'شماره کاپی شد', 'شمېره کاپي شوه'],

    // Whisper
    'cantSpeak': ["Can't speak out loud?", 'نمی‌توانید بلند حرف بزنید؟', 'په لوړ غږ خبرې نه شئ کولی؟'],
    'whisperSub': ['Write it. {name} can share it with the room, without your name.', 'بنویسید. {name} می‌تواند آن را بدون نام شما با جمع شریک کند.', 'ولیکئ. {name} یې ستاسو له نوم پرته له ټولو سره شریکولی شي.'],
    'whisperHint': ['Write your whisper', 'نجوای خود را بنویسید', 'خپل پټ پیغام ولیکئ'],
    'sendPrivately': ['Send privately', 'محرمانه بفرست', 'په پټه یې ولېږه'],

    // Host tools
    'hostToolsSub': ['Gentle ways to keep the space safe and warm.', 'راه‌های آرام برای امن و گرم نگه داشتن مجلس.', 'د مجلس د خوندي او تود ساتلو نرمې لارې.'],
    'breatheTogether': ['Breathe together', 'نفس با هم', 'په ګډه ساه'],
    'breatheTogetherSub': ['One minute, everyone', 'یک دقیقه، همه', 'یوه دقیقه، ټول'],
    'pinQuestion': ['Pin a question', 'یک سؤال بگذارید', 'پوښتنه کېږدئ'],
    'pinQuestionSub': ['Shown to everyone', 'برای همه دیده می‌شود', 'ټولو ته ښکاري'],
    'turnsOnSub': ['On · 2 min each', 'روشن · هر کدام ۲ دقیقه', 'روښانه · هر یو ۲ دقیقې'],
    'off': ['Off', 'خاموش', 'بند'],
    'waitingN': ['{n} waiting', '{n} منتظر', '{n} په تمه'],
    'muteEveryone': ['Mute everyone', 'همه را خاموش کن', 'ټول غلي کړه'],
    'guideToolsSub': ['WellMate guide tools', 'ابزار راهنمای WellMate', 'د WellMate لارښود وسایل'],
    'autoMuted': ['{name} was muted after several reports', '{name} پس از چند گزارش خاموش شد', '{name} له څو راپورونو وروسته غلی شو'],
    'muteEveryoneSub': ['Speakers can unmute later', 'سخنران‌ها بعداً روشن می‌کنند', 'ویناوال وروسته خلاصولی شي'],
    'invitePeople': ['Invite people', 'دعوت دیگران', 'نور راوبله'],
    'invitePeopleSub': ['Copy an invite', 'کاپی دعوت', 'بلنه کاپي کړه'],
    'whispers': ['Whispers', 'نجواها', 'پټ پیغامونه'],
    'whispersN': ['{n} written', '{n} نوشته', '{n} لیکل شوي'],
    'endGently': ['End the space gently', 'مجلس را آرام ببند', 'مجلس په ارامۍ پای ته ورسوه'],
    'endQ': ['End this space for everyone?', 'مجلس برای همه بسته شود؟', 'مجلس د ټولو لپاره پای ته ورسېږي؟'],
    'endBody': ['Everyone returns to the hallway. Leaving as host ends the space.', 'همه به دهلیز برمی‌گردند. اگر میزبان برود، مجلس بسته می‌شود.', 'ټول دهلیز ته ستنېږي. که کوربه ووځي، مجلس پای ته رسېږي.'],
    'endSpace': ['End space', 'بستن مجلس', 'مجلس پای ته ورسوه'],
    'stay': ['Stay', 'بمان', 'پاتې شه'],
    'pinTitle': ['Put a question on the carpet', 'یک سؤال روی قالین بگذارید', 'یوه پوښتنه پر غالۍ کېږدئ'],
    'pin': ['Pin', 'بگذار', 'کېږده'],
    'unpin': ['Take it off', 'بردار', 'لرې یې کړه'],
    'noWhispers': ['No whispers yet', 'هنوز نجوایی نیست', 'لا پټ پیغام نشته'],
    'pinWhisper': ['Put on the carpet', 'روی قالین بگذار', 'پر غالۍ یې کېږده'],
    'handsTitle': ['Want to speak', 'می‌خواهند صحبت کنند', 'غواړي خبرې وکړي'],
    'handsSub': ['Invite one at a time. Everyone else keeps listening.', 'یکی‌یکی دعوت کنید. بقیه گوش می‌دهند.', 'یو یو یې راوبلئ. نور اورېدو ته دوام ورکوي.'],
    'noHands': ['No hands raised right now', 'فعلاً کسی دست بلند نکرده', 'اوس مهال هېچا لاس نه دی پورته کړی'],

    'whispersHostSub': ['Written by listeners. You never see who wrote them.', 'نوشته‌ی شنونده‌ها. شما نمی‌بینید چه کسی نوشته است.', 'د اورېدونکو لیکنې. تاسو نه وینئ چې چا لیکلې دي.'],
    'movedToListening': ['{name} is listening again', '{name} دوباره شنونده شد', '{name} بیا اورېدونکی شو'],
    'weakLink': ['Weak connection. Voices may break up.', 'اتصال ضعیف است. صداها ممکن است قطع شوند.', 'نښلون کمزوری دی. غږونه ښايي پرې پرې شي.'],

    // While a space is open in the background (Android notification)
    'inMajlis': ['You are in Majlis', 'شما در مجلس هستید', 'تاسو په مجلس کې یاست'],
    'inMajlisBody': ['Still listening. Your mic stays off while you are away.', 'هنوز گوش می‌دهید. تا برنگردید مایکروفون خاموش است.', 'لا اورئ. تر څو بېرته نه یاست راغلي، مایک بند دی.'],
    'leave': ['Leave', 'بیرون شو', 'ووځه'],
    'reminderSet': ['We will remind you 10 minutes before', '۱۰ دقیقه پیش به شما یادآوری می‌کنیم', '۱۰ دقیقې مخکې به تاسو ته یادونه وکړو'],
    'reminderBody': ['{title} starts at {time}', '«{title}» ساعت {time} شروع می‌شود', '«{title}» په {time} پیلېږي'],
    'goingSet': ['Marked as going', 'شما می‌آیید', 'تاسو به راشئ'],

    // Listener menu
    'myProfile': ['My Majlis profile', 'پروفایل مجلس من', 'زما د مجلس پروفایل'],
    'shareSpace': ['Share this space', 'فرستادن این مجلس', 'دا مجلس شریک کړه'],
    'reportSpace': ['Report this space', 'گزارش این مجلس', 'د دې مجلس راپور'],
    'reportSpaceSub': ['The WellMate team reviews it privately', 'تیم WellMate محرمانه بررسی می‌کند', 'د WellMate ټیم یې په پټه ګوري'],

    // Women-only, invite code
    'womenTitle': ['A space for women', 'مجلسی برای زنان', 'د ښځو لپاره مجلس'],
    'womenBody': ['Women-only spaces are for women. Hosts can remove anyone who should not be here.', 'مجلس‌های زنان فقط برای زنان است. میزبان می‌تواند هر کسی را که نباید اینجا باشد بیرون کند.', 'د ښځو مجلسونه یوازې د ښځو لپاره دي. کوربه هغه څوک ایستلی شي چې باید دلته نه وي.'],
    'womenYes': ["I'm a woman", 'من زن هستم', 'زه ښځه یم'],
    'codeTitle': ['Join with an invite code', 'ورود با کد دعوت', 'د بلنې کوډ سره ننوځئ'],
    'codeHint': ['6 letters, e.g. K7Q2MD', '۶ حرف، مثلاً K7Q2MD', '۶ توري، لکه K7Q2MD'],

    // Errors (keys come from the server)
    'err.sign-in': ['Please sign in to WellMate first', 'لطفاً اول وارد WellMate شوید', 'مهرباني وکړئ لومړی WellMate ته ننوځئ'],
    'err.app-check': ['Please update WellMate to use Majlis', 'لطفاً WellMate را به‌روز کنید', 'مهرباني وکړئ WellMate تازه کړئ'],
    'err.no-veil': ['Choose your Majlis name first', 'اول نام مجلس خود را انتخاب کنید', 'لومړی خپل د مجلس نوم وټاکئ'],
    'err.verify-email': ['Please verify your email first', 'لطفاً اول ایمیل خود را تأیید کنید', 'مهرباني وکړئ لومړی خپل برېښنالیک تایید کړئ'],
    'err.already-hosting': ['You already have a live space', 'شما همین حالا یک مجلس زنده دارید', 'تاسو دمخه یو ژوندی مجلس لرئ'],
    'err.too-many-scheduled': ['You can schedule up to 5 spaces', 'تا ۵ مجلس را می‌توانید برنامه کنید', 'تر ۵ پورې مجلسونه ټاکلی شئ'],
    'err.space-gone': ['This space has ended', 'این مجلس تمام شده', 'دا مجلس پای ته رسېدلی'],
    'err.not-started': ['This space has not started yet', 'این مجلس هنوز شروع نشده', 'دا مجلس لا نه دی پیل شوی'],
    'err.removed': ['You were removed from this space', 'شما از این مجلس بیرون شدید', 'تاسو له دې مجلس څخه وایستل شوئ'],
    'err.unavailable': ['This space is not available to you', 'این مجلس برای شما در دسترس نیست', 'دا مجلس تاسو ته شتون نه لري'],
    'err.you-blocked-host': ["You blocked this space's host", 'شما میزبان این مجلس را مسدود کرده‌اید', 'تاسو د دې مجلس کوربه بند کړی'],
    'err.invite-needed': ['This space needs an invite code', 'این مجلس کد دعوت لازم دارد', 'دې مجلس ته د بلنې کوډ پکار دی'],
    'err.bad-code': ["That code didn't work", 'این کد کار نکرد', 'دا کوډ کار ونه کړ'],
    'err.stage-full': ['The stage is full', 'صحنه پر است', 'سټېج ډک دی'],
    'err.invite-expired': ['That invite is no longer open', 'این دعوت دیگر باز نیست', 'دا بلنه نوره خلاصه نه ده'],
    'err.slow-down': ['Please wait a moment', 'لطفاً لحظه‌ای صبر کنید', 'مهرباني وکړئ یوه شېبه صبر وکړئ'],
    'err.bad-title': ['Write a title of 3 to 90 letters', 'عنوانی بین ۳ تا ۹۰ حرف بنویسید', 'له ۳ تر ۹۰ تورو سرلیک ولیکئ'],
    'err.bad-time': ['Pick a time in the next 7 days', 'وقتی در ۷ روز آینده انتخاب کنید', 'په راتلونکو ۷ ورځو کې وخت وټاکئ'],
    'err.join-first': ['Join the space first', 'اول وارد مجلس شوید', 'لومړی مجلس ته ننوځئ'],
    'err.sound': ["Couldn't connect to the sound of this space", 'به صدای این مجلس وصل نشدیم', 'د دې مجلس غږ سره ونه نښلېدو'],
    'err.network': ['No internet connection', 'انترنت وصل نیست', 'انټرنیټ نشته'],
    'err.generic': ['Something went wrong. Please try again.', 'مشکلی پیش آمد. دوباره امتحان کنید.', 'یوه ستونزه پېښه شوه. بیا هڅه وکړئ.'],

    // Topics
    'topic.all': ['All', 'همه', 'ټول'],
    'topic.chai': ['Chai & chat', 'چای و گپ', 'چای او ګپ شپ'],
    'topic.sleep': ["Can't sleep", 'بی‌خوابی', 'بې خوبي'],
    'topic.study': ['Studies', 'درس', 'زده کړه'],
    'topic.moms': ['Mothers', 'مادران', 'میندې'],
    'topic.poetry': ['Poetry', 'شعر', 'شعر'],
    'topic.faith': ['Faith & calm', 'ایمان و آرامش', 'ایمان او ارامي'],
    'topic.hope': ['Small wins', 'موفقیت‌های کوچک', 'کوچنۍ بریاوې'],
    'topic.home': ['Missing home', 'دلتنگی وطن', 'د وطن ارمان'],

    // Veil names
    'veil.red_tulip': ['Red Tulip', 'لاله سرخ', 'سور غاټول'],
    'veil.almond_blossom': ['Almond Blossom', 'شگوفه بادام', 'د بادام ګل'],
    'veil.morning_sun': ['Morning Sun', 'آفتاب صبح', 'د سهار لمر'],
    'veil.night_star': ['Night Star', 'ستاره شب', 'د شپې ستوری'],
    'veil.little_lamp': ['Little Lamp', 'چراغ کوچک', 'وړوکی څراغ'],
    'veil.kabul_rain': ['Kabul Rain', 'باران کابل', 'د کابل باران'],
    'veil.mulberry': ['Mulberry', 'توت', 'توت'],
    'veil.pomegranate': ['Pomegranate', 'انار', 'انار'],
    'veil.apricot': ['Apricot', 'زردآلو', 'زردالو'],
    'veil.walnut': ['Walnut', 'چارمغز', 'غوز'],
    'veil.saffron_moon': ['Saffron Moon', 'ماه زعفرانی', 'زعفراني سپوږمۍ'],
    'veil.blue_butterfly': ['Blue Butterfly', 'پروانه آبی', 'شین ښاپېرک'],
    'veil.wild_rose': ['Wild Rose', 'نسترن', 'ځنګلي ګلاب'],
    'veil.cypress': ['Cypress', 'سرو', 'د سرو ونه'],
    'veil.hindu_kush': ['Hindu Kush', 'هندوکش', 'هندوکش'],
    'veil.soft_cloud': ['Soft Cloud', 'ابر نرم', 'نرمه ورېځ'],
    'veil.little_sparrow': ['Little Sparrow', 'گنجشک کوچک', 'وړه چڼچڼه'],
    'veil.green_apple': ['Green Apple', 'سیب سبز', 'شنه مڼه'],
    'veil.honey': ['Honey', 'عسل', 'ګبین'],
    'veil.autumn_leaf': ['Autumn Leaf', 'برگ پاییزی', 'د منې پاڼه'],
    'veil.sunflower': ['Sunflower', 'گل آفتاب‌پرست', 'لمرګلی'],
    'veil.prayer_beads': ['Prayer Beads', 'تسبیح', 'تسبیح'],
    'veil.little_teapot': ['Little Teapot', 'چاینک کوچک', 'وړوکی چاینک'],
    'veil.warm_naan': ['Warm Naan', 'نان گرم', 'ګرمه ډوډۍ'],
    'veil.peacock': ['Peacock', 'طاووس', 'طاووس'],
    'veil.cherry': ['Cherry', 'گیلاس', 'ګیلاس'],
    'veil.shomali_grape': ['Shomali Grape', 'انگور شمالی', 'د شمالي انګور'],
    'veil.lemon_tree': ['Lemon Tree', 'درخت لیمو', 'د لیمو ونه'],
    'veil.clay_jug': ['Clay Jug', 'کوزه گلی', 'خاورین منګی'],
    'veil.little_lamb': ['Little Lamb', 'بره کوچک', 'وړوکی وری'],
    'veil.morning_breeze': ['Morning Breeze', 'نسیم صبح', 'د سهار نسیم'],
    'veil.silver_moon': ['Silver Moon', 'ماه نقره‌ای', 'سپینه سپوږمۍ'],
    'veil.mountain_spring': ['Mountain Spring', 'چشمه کوه', 'د غره چینه'],
    'veil.salang_snow': ['Salang Snow', 'برف سالنگ', 'د سالنګ واوره'],
    'veil.panjshir_river': ['Panjshir River', 'دریای پنجشیر', 'د پنجشیر سیند'],
    'veil.bamyan_sky': ['Bamyan Sky', 'آسمان بامیان', 'د بامیان آسمان'],
    'veil.golden_wheat': ['Golden Wheat', 'گندم طلایی', 'طلايي غنم'],
    'veil.fig_tree': ['Fig Tree', 'درخت انجیر', 'د انځر ونه'],
    'veil.jasmine': ['Jasmine', 'یاسمن', 'رازقي'],
    'veil.raindrop': ['Raindrop', 'قطره باران', 'د باران څاڅکی'],
    'veil.little_fox': ['Little Fox', 'روباه کوچک', 'وړه ګیدړه'],
  };

  /// For tests: every key must have exactly three non-empty strings.
  static Iterable<MapEntry<String, List<String>>> get entries => _t.entries;
}
