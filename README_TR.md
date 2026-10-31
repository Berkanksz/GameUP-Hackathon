# Higher Ground (Daha Yukarı): Antigravity Başlangıç Paketi

## 1. Pakette ne var

* `.agents/rules`: Her mesajda yüklenen kısa kurallar (iletişim, token, mimari, kod stili, asset lisansı, çeviri).
* `.agents/skills`: İhtiyaç olunca yüklenen bilgi paketleri (Blender'dan Godot'a asset, 2.5D toon görünüm, grafik disiplini).
* `.agents/workflows`: Senin yazacağın komutlar: `/setup`, `/new_feature`, `/sync_graph`, `/ship_check`.
* `docs/`: Oyun tasarımı, teknik şartname, proje haritası, görev listesi, asset listesi, lisans defteri, bilgi kaynakları, teslim notları.
* `tools/gen_graph.py`: Kodu tarayıp bağımlılık ve sinyal haritası (`docs/GRAPH.md`) üretir. Ajan projeyi baştan okumaz, bunu okur.
* `tools/check_project.py`: Eksik çeviri ve lisans defterinde olmayan asset kontrolü.
* `translations/strings.csv`: İngilizce ve Türkçe başlangıç metinleri (64 anahtar).
* `mcp_config.template.json`: Godot, Blender ve hafıza (knowledge graph) MCP ayarları.

## 2. Senin yapacakların (sırayla)

1. Zip'i klasöre çıkar. Klasör adı önemli değil ama yolunda Türkçe karakter olmasın.
2. Antigravity'de File, Open Folder ile bu klasörü aç.
3. Agent paneline sadece şunu yaz: `/setup`
4. Ajan araçları kontrol eder, eksikleri kurar, MCP ayarını kendi yapar. Sana "Senden" satırında şunları söyleyecek:
   * Antigravity'de MCP sunucularını yenile (agent paneli, üç nokta, Manage MCP Servers) veya Antigravity'yi yeniden başlat.
   * Blender'da: Edit, Preferences, Add-ons, Install from Disk, `tools/blender_addon/addon.py` dosyasını seç ve etkinleştir.
   * Blender 3D görünümünde N tuşu, BlenderMCP sekmesi, Poly Haven kutusunu işaretle, Sketchfab kapalı kalsın, Connect'e bas. Çalışırken Blender açık kalsın.
5. Sonra: `/new_feature` yaz ve görev olarak `docs/TASKS.md` içindeki ilk işaretsiz maddeyi ver (M1).
6. Her görev bitince yeni sohbet aç (token tasarrufu). Görevleri sırayla `/new_feature` ile ilerlet.

Klasör görünmüyorsa: `.agents` gizli klasör sayılır. Windows'ta görünür, Mac'te Cmd + Shift + nokta ile göster.
Kurallar yüklenmiyorsa: Antigravity sürümün eski olabilir. `.agents` klasörünü `.agent` olarak yeniden adlandır. Kök dizindeki `AGENTS.md` zaten yedek olarak ajanı kurallara yönlendirir.

## 3. Token tasarrufu için ipuçları

1. Küçük işlerde Fast, büyük işlerde Planning modunu kullan.
2. Her milestone için yeni sohbet aç, `@docs/TASKS.md` ile referans ver.
3. Ajana "projeyi oku" deme. Kurallar zaten `GRAPH.md` ve `PROJECT_MAP.md` üzerinden çalışmasını söylüyor.
4. MCP sunucuları: Godot (17 araç, hafif), Blender, hafıza grafiği. Gereksiz MCP ekleme, her araç listesi token yer.

## 4. Bir yeri yaparken diğerini bozmaması nasıl sağlanıyor

1. Otomatik grafik: `tools/gen_graph.py` hangi dosya neyi kullanıyor, hangi sinyali kim yayıyor ve dinliyor çıkarır. `--impact dosya` komutu bir dosyayı değiştirince kimlerin etkileneceğini söyler.
2. `docs/PROJECT_MAP.md`: Her modülün genel sözleşmesi (metotlar, sinyaller, export değişkenleri).
3. Hafıza MCP grafiği: Tarayıcının göremediği bağlantılar (node yolları, sahne bağları, kararlar).
4. Kurallar: Modüller birbirinin içine uzanmaz, sadece EventBus sinyalleri ve listelenen genel metotlarla konuşur. Bir şeyi yeniden adlandırmadan önce etki analizi zorunlu.
5. Her doğrulanmış görevden sonra otomatik git commit. Bozulursa geri dönülür.

## 5. Oyun özeti

**Higher Ground (Daha Yukarı)**: Eriyen koloniden uzaklaşan yalnız bir penguen, daha soğuk ve yüksek bir yer arıyor. Yolda insanların izlerine rastlıyor ve "hiçbir şeyin anlamı yok" tavrından yavaşça "belki bir şey yapılabilir" tavrına geçiyor.

1. Görünüm: 3D modeller, yandan kamera, düzleme kilitli oynanış, toon gölgelendirme ve kontur. 3D ama 2D gibi hissettirir.
2. Isı (0 ile 1): Güneşte yükselir, gölgede düşer. Dolarsa penguen son kontrol noktasında yeniden doğar.
3. Umut (0 ile 100): Hiçbir zaman kaybetme sebebi değil. Monolog tonunu, dünyanın renk tonunu ve finali belirler.
4. Bölüm 1, Kıyı (Okyanuslar ve Denizler): Eriyen buz parçaları üzerinde zıplama. Mahsur kalmış yavruya yardım seçimi.
5. Bölüm 2, Yamaç (Sıfır Atık): Atıkları taşı ve doğru kutuya ayır (kağıt mavi, plastik sarı, cam yeşil). Atık yığınları yolu kapatır, ayırdıkça açılır. Tohum ekme seçimi.
6. Bölüm 3, Zirve (İklim Eğitimi ve Yenilenebilir Enerji): Tırmanış, eski kulübede güneş enerjili lamba seçimi. Zirveden uzakta bir kasaba görünür: hiçbir yer uzak değil.
7. Üç final: Uzaklaştı, Geriye Baktı, Aşağı İndi. Umut seviyene göre değişir.
8. Diller: İngilizce ve Türkçe, menüden değiştirilir.
9. Penguenin iç sesi altyazı olarak gelir. Ses taklidi veya orijinal belgesel/meme materyali yok, ton özgün.

## 6. Hackathon için unutma

1. Yayın ve webinarların en az %60'ına katıl, değerlendirmede sayılıyor.
2. Slack kanalına gir, WhatsApp topluluğunu takip et.
3. Sunum şablonu paylaşılınca `docs/SUBMISSION.md` ile doldur.
4. Teslim: 1 Kasım Pazar 23.59'a kadar WhatsApp'tan paylaşılacak form. Hedef: 18.00'de bitir.
5. Mentorluk Pazar günü, zorunlu değil ama sunum öncesi faydalı.

## 7. Dikkat edilecekler

1. Penguen tamamen özgün tasarım olacak (kırmızı atkı). Viral belgesel görüntüsü, sesi, repliği ve ekran görüntüsü kullanma.
2. COP31, UNDP, HP, ICPSD logolarını oyuna koyma. Sadece düz metin olarak COP31 Türkiye Antalya yazılabilir.
3. Bilgi kartları ve kutu renkleri 30 Ekim 2026 tarihinde doğrulandı, kaynaklar `docs/FACTS_SOURCES.md` içinde. COP31 satırını teslimden önce bir kez daha kontrol et.
4. Blender MCP ve Godot MCP topluluk yapımı. Blender MCP kod çalıştırabilir, sadece güvendiğin projelerde kullan.
5. Asset bulunamazsa ajan Blender'da özgün low poly model üretir ve lisans defterine "CC0 original" olarak yazar.
