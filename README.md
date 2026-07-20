# 📜 Ataların Sözü

Günlük hayatta unutulmaya yüz tutmuş atasözlerini ve deyimleri kullanıcılara hatırlatmayı, kelime dağarcıklarını (Vocabulary) zenginleştirmeyi amaçlayan eğitici mobil uygulama ve sözlük (Dictionary) projesidir.

---

## 🎯 Proje Amacı (Project Goal)
Kullanıcıların her gün yeni bir atasözü veya deyim öğrenmesini sağlamak. Uygulama, mobil cihazlar için özel geliştirilen ana ekran aracı (Widget) ve anlık bildirimler (Push Notifications) ile öğrenmeyi günlük rutinin bir parçası haline getirir. Aynı zamanda geniş veri tabanı ile detaylı bir arama (Search) deneyimi sunar.

## ✨ Özellikler (Features)
*   **Günlük Söz Bildirimi (Daily Push Notification):** Kullanıcılara her gün rastgele seçilmiş bir atasözü veya deyim bildirimi gönderilir.
*   **Ana Ekran Aracı ( Widget):** Uygulama kapalıyken bile cihazların ana ekranında günün kelimesini gösteren özel araç.
*   **Kapsamlı Arama (Smart Search):** TDK (Türk Dil Kurumu) kaynaklı 100+ atasözü ve deyim içinde hızlı arama yapma imkanı.
*   **Detaylı İnceleme (Detail View):** Seçilen kelimenin anlamını ve akılda kalıcılığı artıran örnek cümle içi kullanımını (Example Sentence) görüntüleme.

## 🛠 Kullanılan Teknolojiler (Tech Stack)




##Joaquin'in Açacağı Dallar (Flutter Frontend / Ön Yüz):
Joaquin kod yazarken develop dalından kendi bilgisayarına aşağıdaki dalları açıp, işi bitince geri develop dalına gönderecek (Merge işlemi).

feature/flutter-init : Flutter projesinin ilk kez oluşturulduğu ve klasör yapısının (klasörlerin nereye konacağı) ayarlandığı görev dalı.

feature/home-screen : Ana sayfanın, butonların ve "Günün Sözü" kutusunun görsel olarak kodlanacağı dal.

feature/search-screen : Arama çubuğunun ve liste görünümünün yapılacağı dal.

feature/firebase-connection : Senin kurduğun veri tabanı (Firebase) ile uygulamanın haberleşmesini sağlayacak kodların yazıldığı dal.

##Erden'in Açacağı Dallar (Swift Widget / Apple Araç Takımı):

feature/ios-widget-ui : Apple cihazlar için ana ekran aracının (Widget) dış görünüşünün Swift ve SwiftUI ile kodlanacağı dal.

feature/widget-data-bridge : (İleri seviye görev) Joaquin'in Flutter'daki verileriyle, Erden'in Swift'teki Widget'ını birbirine bağlayacak olan köprü (Platform Channel) kodlarının yazılacağı dal.

Semra
docs/readme-update : Projenin kimler tarafından yapıldığını, hangi dillerin kullanıldığını anlatan açıklama dosyasının (README.md) yazıldığı dal.
