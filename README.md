# 📱 InnJoy Mobil Uygulaması

> **Konaklamanın Keyfini Çıkarın, Kayıt Olmak Saniyenizi Alır.**

Bu proje, kullanıcıların **güvenli bir şekilde hesap oluşturup oturum açabileceği** (Login/Signup) ekranları içeren **dinamik bir Flutter mobil uygulamasıdır**.

---

## 🚀 Başlarken

InnJoy projesini yerel makinenizde kurmak ve çalıştırmak için gerekli adımlar ve ön koşullar aşağıdadır.

### 🛠️ Ön Koşullar

Bu projeyi yerel makinenizde çalıştırmadan önce, aşağıdaki yazılımların kurulu olduğundan emin olun:

* **Git**: Sürüm kontrol sistemi.
* **Flutter SDK**: Projenin çalışması için gereken mobil uygulama geliştirme ortamı (Dart dilini içerir).
* **Bir IDE (Örn: VS Code veya Android Studio)**: Flutter eklentisi kurulu olmalıdır.

### ⚙️ Kurulum ve Çalıştırma

Projeyi yerel makinenize kurmak ve çalıştırmak için bu adımları takip edin:

1.  **Depoyu Klonlayın**
    ```bash
    git clone [REPOZİTORYO URL'NİZİ BURAYA YAZIN]
    cd InnJoy
    ```

2.  **Bağımlılıkları İndirin**
    ```bash
    flutter pub get
    ```

3.  **Uygulamayı Çalıştırın**
    Bağlı bir cihazınızda (telefon, emülatör/simülatör) uygulamayı başlatmak için:
    ```bash
    flutter run
    ```
    *(Not: Uygulama, belirtilen bir Android veya iOS cihazında (ya da web/masaüstü) otomatik olarak çalışacaktır.)*

---

## 🤝 Katkıda Bulunma (Contribution)

Ekip çalışması yaparken kod kalitesini ve ana dalın stabilitesini korumak için **Feature Branching (Özellik Dallanması)** stratejisini kullanıyoruz.



[Image of Git Flow diagram]


### 💡 Dal (Branch) Yönetimi Kuralları

1.  **Ana Dallarımız:**
    * `main`: **Canlı (Production)** ortamdaki stabil koddur. **Doğrudan Merge (Birleştirme) YASAKTIR.**
    * `dev`: **Geliştirme (Development)** dalımızdır. Tüm özellikler önce bu dala birleştirilir.

2.  **Çalışmaya Başlama: Feature Dallarının Oluşturulması**

    Her yeni görev (özellik/hata düzeltme) için `dev` dalından yeni bir dal oluşturulmalıdır.

    * **Güncel Kodu Çekin:** Çalışmaya başlamadan önce `dev` dalını güncelleyin.
        ```bash
        git checkout dev
        git pull origin dev
        ```

    * **Yeni Dal Oluşturun:** Görev adınıza uygun, açıklayıcı bir isim kullanın.
        ```bash
        # feature/gorev-adi veya fix/hata-adi formatını kullanın
        git checkout -b feature/login-sayfasi-tamamla
        ```

3.  **Kod Yazma ve Gönderme (Push)**

    * **Değişiklikleri Hazırlama ve Kaydetme (Commit):**
        ```bash
        git add .
        git commit -m "feat: Login sayfasinin temel yapisi eklendi"
        ```

    * **Uzak Depoya Gönderme (Push):**
        ```bash
        git push -u origin feature/login-sayfasi-tamamla
        ```

4.  **Kod Birleştirme (Merge) İşlemi**

    * Göreviniz bittiğinde, oluşturduğunuz daldan `dev` dalına hedefli **Pull Request (Çekme İsteği - PR)** açın.
    * PR'ınız, en az bir ekip arkadaşı tarafından **Code Review (Kod İncelemesi)** yapılıp onaylandıktan sonra birleştirilecektir.

---

## 📞 İletişim

Sorularınız, sorunlarınız veya geri bildirimleriniz için lütfen iletişime geçin:

* **Ekip Lideri:** [Adınız/Kullanıcı Adınız]
* **İletişim Kanalı:** [Slack, Discord, E-posta vb. kanalınızın adı]
