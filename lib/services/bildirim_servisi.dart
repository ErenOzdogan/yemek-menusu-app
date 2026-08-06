import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class BildirimServisi {
  static final FlutterLocalNotificationsPlugin _bildirimEklentisi =
  FlutterLocalNotificationsPlugin();
  static void Function(String? payload)? bildirimeTiklaninca;

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const AndroidInitializationSettings androidAyarlari =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings ilkAyarlar = InitializationSettings(
      android: androidAyarlari,
    );

    // HATA 1 ÇÖZÜMÜ: Parametre adı sadece 'settings' olarak güncellendi.
    await _bildirimEklentisi.initialize(
      settings: ilkAyarlar,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        bildirimeTiklaninca?.call(response.payload);
      },
    );
  }

  static Future<String?> ilkAcilisPayloadiniAl() async {
    final detaylar =
    await _bildirimEklentisi.getNotificationAppLaunchDetails();

    if (detaylar?.didNotificationLaunchApp ?? false) {
      return detaylar?.notificationResponse?.payload;
    }

    return null;
  }

  static Future<void> alarmlariGuncelle(
      bool bildirimAcikMi, String birinciSaat, String ikinciSaat) async {

    await _bildirimEklentisi.cancelAll();

    if (!bildirimAcikMi) return;

    final birinciParca = birinciSaat.split(':');
    final ikinciParca = ikinciSaat.split(':');

    int aksamSaati = int.parse(birinciParca[0]);
    int aksamDakikasi = int.parse(birinciParca[1]);

    int sabahSaati = int.parse(ikinciParca[0]);
    int sabahDakikasi = int.parse(ikinciParca[1]);

    const AndroidNotificationDetails androidDetaylar = AndroidNotificationDetails(
      'menu_bildirim_kanali',
      'Yemek Menüsü Bildirimleri',
      channelDescription: 'Günlük yemek menüsü hatırlatmaları',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails bildirimDetaylari =
    NotificationDetails(android: androidDetaylar);

    // HATA 2 ve 3 ÇÖZÜMÜ: Eski iOS cihazlar için olan o karmaşık 'uiLocalNotification...' satırları tamamen silindi.
    await _bildirimEklentisi.zonedSchedule(
      id: 1,
      title: '🔮 Yarının Menüsüne Göz At!',
      body: 'Yarın menüde neler var? Tam listeyi şimdiden görmek için tıklayın.',
      payload: 'yarin',
      scheduledDate: _siradakiZamaniHesapla(aksamSaati, aksamDakikasi),
      notificationDetails: bildirimDetaylari,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _bildirimEklentisi.zonedSchedule(
      id: 2,
      title: '🍽️ Bugünün Menüsü Belli Oldu!',
      body: 'Bugün menüde neler var? Menüyü görmek ve oylamak için tıkla.',
      payload: 'bugun',
      scheduledDate: _siradakiZamaniHesapla(sabahSaati, sabahDakikasi),
      notificationDetails: bildirimDetaylari,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _siradakiZamaniHesapla(int saat, int dakika) {
    final tz.TZDateTime simdi = tz.TZDateTime.now(tz.local);
    tz.TZDateTime planlananZaman =
    tz.TZDateTime(tz.local, simdi.year, simdi.month, simdi.day, saat, dakika);

    if (planlananZaman.isBefore(simdi)) {
      planlananZaman = planlananZaman.add(const Duration(days: 1));
    }
    return planlananZaman;
  }
}