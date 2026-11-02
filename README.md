# nightshift

A night shift for Claude Code. Type `/nightshift` before bed: Claude asks for everything it
needs in the first five minutes, then works alone until morning inside the limits you set,
and hands the shift over to you with a summary.

*Türkçesi aşağıda.*

## What it does

- **Asks everything in the first five minutes:** the task queue and its order, the wake-up
  time, whether it may push, any exceptions, and the permissions the night will need. After
  that nobody is there to answer.
- **Works on its own:** verifies every step (tests, typecheck, build), commits it, and writes
  it in the journal. Finished work never waits uncommitted.
- **Asks for help in order when stuck:** three Sonnet subagents first, then Opus, then Fable
  if needed (at most 10 questions a night). If that still does not settle it, it keeps the
  question for your morning and moves on to the next task.
- **Watches your usage:** takes a break at 85% of the 5-hour usage window and picks up where
  it stopped when the window resets.
- **Never at night:** deploys, deletes, force pushes, paid calls, new dependencies, or
  messages to anyone. You can grant an exception in the first five minutes.
- **In the morning:** the summary sits at the top of
  `~/.claude/nightshift/<date>-<project>/NIGHTSHIFT.md`: what got done, what did not and
  why, and what is waiting for you. With notifications on, one line reaches your phone.

## Install

```bash
git clone https://github.com/fatihfurkanak/nightshift.git
cd nightshift && ./install.sh
```

`install.sh` copies the skill to `~/.claude/skills/nightshift`. If you have no status line
yet, it sets up one that reads your usage, after backing up your settings file. If you
already have a status line, it leaves it alone and prints the one line to add to it.

Needs: Claude Code, `jq`, macOS (`caffeinate` keeps the Mac awake). Usage tracking works on
claude.ai Pro, Max and Ultra plans, the plans for which Claude Code reports usage. With an
API key there is no 85% break; the night still runs.

## Use

| Command | What it does |
|---|---|
| `/nightshift` | Questions, the plan, then work until morning |
| `/nightshift <tasks>` | The same, with the queue starting from the tasks you give |
| `/nightshift status` | Reports the night in five lines, changes nothing |
| `/nightshift stop` | Ends the shift now: writes the summary, turns off the schedules |

- Start Claude Code **in a terminal** with `claude`. The status line and the scheduled checks
  run there.
- Keep the Mac **on power** with the **lid open**.
- If your permission mode asks before commands, Claude lists the commands the night will need
  in the first five minutes; allow them then. A permission prompt at 3 AM ends the night.
- In an important repository, let it push to a separate branch and merge in the morning.

## How it works

- **Usage:** Claude Code passes the status line script the used percentage and reset time of
  the 5-hour and 7-day windows. `save-usage.sh` writes them to
  `~/.claude/nightshift/usage.json`, and the skill reads them with `usage.sh`.
- **Scheduled checks:** Claude Code's in-session scheduler. A check every hour, the summary at
  the wake-up time, and a resume when the usage window resets. Closing the session removes
  the schedules.
- **Memory:** over a long night the conversation gets summarised. The skill re-reads its run
  file after every task, so it always knows where it left off.

## Credits

The idea of a skill that works through the night was inspired by a post from Burak Tamaç
([@burak_tamac](https://x.com/burak_tamac)). nightshift was written from scratch, with its own
rules.

MIT licensed. By Fatih Furkan Ak.

---

## Türkçe: Gece vardiyası

Claude Code için gece vardiyası. Yatmadan önce `/nightshift` yazarsın. Claude ilk beş
dakikada ihtiyacı olan her şeyi sorar, sonra sabaha kadar senin çizdiğin sınırlar içinde tek
başına çalışır. Sabah vardiyayı bir özetle sana devreder.

### Ne yapar

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

### Kurulum

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

### Kullanım

| Komut | Ne yapar |
|---|---|
| `/nightshift` | Sorular, plan, sonra sabaha kadar çalışma |
| `/nightshift <işler>` | Aynısı, iş listesi verdiğin işlerle başlar |
| `/nightshift status` | Gecenin durumunu beş satırda söyler, hiçbir şeyi değiştirmez |
| `/nightshift stop` | Vardiyayı şimdi bitirir: özet yazar, zamanlayıcıları kapatır |

- Claude Code'u **terminalde** `claude` ile aç. Durum satırı ve zamanlanmış kontroller
  orada çalışır.
- Mac **şarjda** olsun, **kapak açık** kalsın.
- İzin soran bir modda çalışıyorsan Claude ilk beş dakikada gece lazım olacak komutları
  sayar; onlara o an izin ver. Gece 3'te çıkan bir izin sorusu geceyi bitirir.
- Önemli bir repoda push'u ayrı bir dala aç; sabah bakıp birleştirirsin.

### Nasıl çalışır

- **Kota:** Claude Code durum satırı betiğine 5 saatlik ve 7 günlük pencerenin kullanım
  yüzdesini ve sıfırlanma saatini verir. `save-usage.sh` bunu `~/.claude/nightshift/usage.json`
  dosyasına yazar; skill `usage.sh` ile oradan okur.
- **Zamanlanmış kontroller:** Claude Code'un oturum içi zamanlayıcısı. Saatte bir kontrol,
  uyanma saatinde özet ve kota sıfırlanınca devam. Oturumu kapatırsan kontroller de gider.
- **Hafıza:** uzun gecede konuşma özetlenir. Skill her işten sonra gece dosyasını yeniden
  okur; kaldığı yeri oradan bilir.

### Teşekkür

Gece çalışan bir skill fikri, Burak Tamaç'ın ([@burak_tamac](https://x.com/burak_tamac)) bir
paylaşımından ilham aldı. nightshift sıfırdan, kendi kurallarıyla yazıldı.

Lisans: MIT. Yazan: Fatih Furkan Ak.
