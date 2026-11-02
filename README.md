# nightshift: Gece vardiyası

Claude Code için gece vardiyası. Yatmadan önce `/nightshift` yazarsın. Claude ilk beş
dakikada ihtiyacı olan her şeyi sorar, sonra sabaha kadar senin çizdiğin sınırlar içinde tek
başına çalışır. Sabah vardiyayı bir özetle sana devreder.

*English below.*

## Ne yapar

- **İlk 5 dakikada her şeyi sorar:** iş listesi ve sırası, uyanma saati, push izni,
  istisnalar, gece lazım olacak izinler. Sonrasında kimse cevap vermeyecek.
- **Kendi başına çalışır:** her adımı doğrular (test, typecheck, build), commit'ler, günlüğe
  yazar. Biten iş commit'lenmeden beklemez.
- **Takılınca sırayla danışır:** önce 3 Sonnet'e, olmazsa Opus'a, gerekirse Fable'a (gecede
  en fazla 10 soru). Yine olmazsa sabah sana sormak için not alır ve sıradaki işe geçer.
- **Kotayı izler:** 5 saatlik kullanım penceresinin %85'ine gelince molaya çıkar, pencere
  sıfırlanınca kaldığı yerden devam eder.
- **Gece asla yapmadıkları:** deploy, silme, force push, ücretli çağrı, yeni bağımlılık,
  kimseye mesaj göndermek. İstisnayı ilk beş dakikada sen verirsin.
- **Sabah:** özet `~/.claude/nightshift/<tarih>-<proje>/NIGHTSHIFT.md` dosyasının en
  üstünde: neler bitti, neler bitmedi ve neden, senden ne bekleniyor. Bildirimler açıksa
  telefonuna tek satırlık bir bildirim gelir.

## Kurulum

```bash
git clone https://github.com/fatihfurkanak/nightshift.git
cd nightshift && ./install.sh
```

`install.sh` skill'i `~/.claude/skills/nightshift` altına kopyalar. Durum satırın (status line)
yoksa kota okuyan durum satırını kurar; ayar dosyanın yedeğini de alır. Zaten bir durum
satırın varsa ona dokunmaz, ekleyeceğin tek satırı gösterir.

Gerekenler: Claude Code, `jq`, macOS (Mac'i uyanık tutmak için `caffeinate` kullanılıyor).
Kota takibi claude.ai Pro, Max ve Ultra aboneliklerinde çalışır; Claude Code kullanım
yüzdesini yalnızca bu planlarda verir. API anahtarıyla kullanıyorsan %85 molası olmaz, gece
yine çalışır.

## Kullanım

| Komut | Ne yapar |
|---|---|
| `/nightshift` | Sorular, plan, sonra sabaha kadar çalışma |
| `/nightshift <işler>` | Aynısı, iş listesi verdiğin işlerle başlar |
| `/nightshift status` | Gecenin durumunu beş satırda söyler, hiçbir şeyi değiştirmez |
| `/nightshift stop` | Geceyi şimdi bitirir: özet yazar, zamanlayıcıları kapatır |

- Claude Code'u **terminalde** `claude` ile aç. Durum satırı ve zamanlanmış kontroller
  orada çalışır.
- Mac **şarjda** olsun, **kapak açık** kalsın.
- İzin soran bir modda çalışıyorsan Claude ilk beş dakikada gece lazım olacak komutları
  sayar; onlara o an izin ver. Gece 3'te çıkan bir izin sorusu geceyi bitirir.
- Önemli bir repoda push'u ayrı bir dala aç; sabah bakıp birleştirirsin.

## Nasıl çalışır

- **Kota:** Claude Code durum satırı betiğine 5 saatlik ve 7 günlük pencerenin kullanım
  yüzdesini ve sıfırlanma saatini verir. `save-usage.sh` bunu `~/.claude/nightshift/usage.json`
  dosyasına yazar; skill `usage.sh` ile oradan okur.
- **Zamanlanmış kontroller:** Claude Code'un oturum içi zamanlayıcısı. Saatte bir kontrol,
  uyanma saatinde özet ve kota sıfırlanınca devam. Oturumu kapatırsan kontroller de gider.
- **Hafıza:** uzun gecede konuşma özetlenir. Skill her işten sonra gece dosyasını yeniden
  okur; kaldığı yeri oradan bilir.

## Teşekkür

Gece çalışan bir skill fikri, Burak Tamaç'ın ([@burak_tamac](https://x.com/burak_tamac)) bir
paylaşımından ilham aldı. nightshift sıfırdan, kendi kurallarıyla yazıldı.

Lisans: MIT. Yazan: Fatih Furkan Ak.

---

## English

A night shift for Claude Code. Type `/nightshift` before bed: Claude asks for everything it
needs in the first five minutes, then works alone until morning inside the limits you set,
and hands over with a summary at the top of `~/.claude/nightshift/<date>-<project>/NIGHTSHIFT.md`.

- Works through an agreed queue, verifies and commits each step.
- When stuck: three Sonnet subagents, then Opus, then Fable (at most 10 questions a night),
  then a note for the morning.
- Takes a break at 85% of the 5-hour usage window and resumes when it resets (claude.ai Pro, Max
  and Ultra plans, where Claude Code reports usage to the status line).
- Never at night: deploys, deletes, force pushes, paid calls, new dependencies, messages.

Install with `./install.sh` (needs `jq`; written for macOS). Run Claude Code in a terminal,
keep the Mac on power with the lid open. Commands: `/nightshift`, `/nightshift <tasks>`,
`/nightshift status`, `/nightshift stop`.

Inspired by a post from Burak Tamaç; written from scratch. MIT licensed. By Fatih Furkan Ak.
