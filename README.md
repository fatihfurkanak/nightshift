# nightshift

A night shift for Claude Code. Type `/nightshift` before bed: Claude asks everything it needs
in one round, then works alone until morning on a branch of its own, inside the limits you
set, and hands the shift over to you with a summary you can act on in ten minutes.

## What it does

- **One round of questions, at most seven:** the task queue and its order, the wake-up time,
  whether it may push its branch, any exceptions, and the permissions the night will need.
  After that nobody is there to answer.
- **Works on its own branch:** every commit goes to `nightshift/<date>`. Your main branch is
  not touched until you merge in the morning.
- **Sorts every change by risk:** green (tests, docs), yellow (behaviour), red (data model,
  auth, payments, security, infra). Before a yellow or red change is committed, a second
  agent reviews the diff; red work is always flagged for your review.
- **Gives every task 90 minutes:** a task that runs over is parked on its own branch and the
  queue moves on, so one stubborn bug cannot eat the night.
- **Calls a council when stuck:** three roles in parallel (a solver, a skeptic who argues the
  obvious fix is wrong, and a scout who looks up the docs and issues), then Opus, then Fable
  (at most 6 questions a night). If that still does not settle it, the question waits for
  your morning and the night moves on.
- **Leaves usage for your morning:** takes a break at 80% of the 5-hour usage window and comes
  back when it resets. The window that runs past your wake-up time stops at 70%, so 30% is
  yours when you get up. One night never uses more than 15 points of your weekly window.
- **Never at night:** deploys, merges, deletes, force pushes, paid calls, new dependencies,
  or messages to anyone. You can grant an exception up front.
- **Hands over in the morning:** the summary sits at the top of
  `~/.claude/nightshift/<date>-<project>/NIGHTSHIFT.md`: what got done, what to review first,
  what did not get done and why, and what is waiting for you. Every finished task comes with
  a one-line undo command. With notifications on, one line reaches your phone.
- **Walks you through the morning:** `/nightshift review` asks the open questions as
  clickable choices, then undoes, merges and deploys what you approve.

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
API key there are no usage breaks; the night still runs.

## Use

| Command | What it does |
|---|---|
| `/nightshift` | Questions, the plan, then work until morning |
| `/nightshift <tasks>` | The same, with the queue starting from the tasks you give |
| `/nightshift status` | Reports the night in five lines, changes nothing |
| `/nightshift stop` | Ends the shift now: writes the summary, turns off the schedules |
| `/nightshift review` | Morning: your decisions as clickable choices, then merge, undo, deploy |

- Start Claude Code **in a terminal** with `claude`. The status line and the scheduled checks
  run there.
- Keep the Mac **on power** with the **lid open**.
- If your permission mode asks before commands, Claude lists the commands the night will need
  in the first round; allow them then. A permission prompt at 3 AM ends the night.

## The numbers

| | |
|---|---|
| Questions up front | one round, at most 7 |
| Time per task | 90 minutes, then it is parked |
| Stuck | 2 failed fixes, an unsettled decision, or 25 minutes without progress |
| Council | 3 roles, then Opus, then Fable (at most 6 a night) |
| Usage break | 80% of the 5-hour window, 70% for the window that runs into your morning |
| Weekly guard | stops at 95% of the 7-day window, or after 15 points of it in one night |
| Checks | every 30 minutes |
| Last start | 45 minutes before the wake-up time |

## How it works

- **Usage:** Claude Code passes the status line script the used percentage and reset time of
  the 5-hour and 7-day windows. `save-usage.sh` writes them to
  `~/.claude/nightshift/usage.json`, and `usage.sh --check` turns them into one answer:
  work, break (and until when), or stop.
- **Scheduled checks:** Claude Code's in-session scheduler. A check every 30 minutes, the
  handover at the cutoff, and a return when a break ends. Closing the session removes them.
- **Memory:** over a long night the conversation gets summarised. The skill re-reads its run
  file after every task, so it always knows where it left off.

## License

MIT. By Fatih Furkan Ak.

---

## Türkçe: Gece vardiyası

Claude Code için gece vardiyası. Yatmadan önce `/nightshift` yazarsın. Claude ihtiyacı olan
her şeyi tek turda sorar, sonra sabaha kadar kendi dalında, senin çizdiğin sınırlar içinde
tek başına çalışır. Sabah vardiyayı on dakikada üzerinden geçebileceğin bir özetle sana
devreder.

### Ne yapar

- **Tek tur soru, en fazla yedi:** iş listesi ve sırası, uyanma saati, dalını push'layıp
  push'layamayacağı, istisnalar, gece lazım olacak izinler. Sonrasında kimse cevap vermeyecek.
- **Kendi dalında çalışır:** her commit `nightshift/<tarih>` dalına gider. Ana dalına sabah
  sen birleştirene kadar dokunulmaz.
- **Her değişikliği riskine göre ayırır:** yeşil (test, belge), sarı (davranış), kırmızı
  (veri modeli, giriş, ödeme, güvenlik, altyapı). Sarı ve kırmızı değişiklikler commit'ten
  önce ikinci bir ajanın incelemesinden geçer; kırmızı işler sabah her zaman önüne gelir.
- **Her işe 90 dakika verir:** süreyi aşan iş kendi dalına park edilir, sıradakine geçilir.
  İnatçı tek bir hata bütün geceyi yiyemez.
- **Takılınca kurul toplar:** üç rol aynı anda: çözen, "bu çözüm yanlış" diye karşı çıkan ve
  belgelere, issue'lara bakan. Sonra Opus, gerekirse Fable (gecede en fazla 6 soru). Yine
  olmazsa soru sabaha kalır, gece devam eder.
- **Sabaha kota bırakır:** 5 saatlik kullanım penceresinin %80'inde molaya çıkar, pencere
  sıfırlanınca döner. Uyanma saatine uzanan pencerede %70'te durur; kalkınca %30 senindir.
  Bir gece haftalık kotanın 15 puanından fazlasını harcamaz.
- **Gece asla yapmadıkları:** deploy, birleştirme (merge), silme, force push, ücretli çağrı,
  yeni bağımlılık, kimseye mesaj göndermek. İstisnayı baştan sen verirsin.
- **Sabah devreder:** özet `~/.claude/nightshift/<tarih>-<proje>/NIGHTSHIFT.md` dosyasının en
  üstünde: neler bitti, önce neye bakmalısın, neler bitmedi ve neden, senden ne bekleniyor.
  Biten her işin yanında onu geri alan tek satırlık komut durur. Bildirimler açıksa
  telefonuna tek satır gelir.
- **Sabah seni gezdirir:** `/nightshift review` açık soruları tıklanabilir seçeneklerle sorar;
  onayladıklarını geri alır, birleştirir, deploy eder.

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
yüzdesini yalnızca bu planlarda verir. API anahtarıyla kullanıyorsan mola olmaz, gece yine
çalışır.

### Kullanım

| Komut | Ne yapar |
|---|---|
| `/nightshift` | Sorular, plan, sonra sabaha kadar çalışma |
| `/nightshift <işler>` | Aynısı, iş listesi verdiğin işlerle başlar |
| `/nightshift status` | Gecenin durumunu beş satırda söyler, hiçbir şeyi değiştirmez |
| `/nightshift stop` | Vardiyayı şimdi bitirir: özet yazar, zamanlayıcıları kapatır |
| `/nightshift review` | Sabah: kararların tıklanabilir seçenekler olarak gelir; sonra birleştirme, geri alma, deploy |

- Claude Code'u **terminalde** `claude` ile aç. Durum satırı ve zamanlanmış kontroller
  orada çalışır.
- Mac **şarjda** olsun, **kapak açık** kalsın.
- İzin soran bir modda çalışıyorsan Claude ilk turda gece lazım olacak komutları sayar;
  onlara o an izin ver. Gece 3'te çıkan bir izin sorusu geceyi bitirir.

### Sayılar

| | |
|---|---|
| Baştaki sorular | tek tur, en fazla 7 |
| İş başına süre | 90 dakika, sonra park edilir |
| Takılma | 2 başarısız düzeltme, çözülemeyen bir karar ya da 25 dakika ilerlememe |
| Kurul | 3 rol, sonra Opus, sonra Fable (gecede en fazla 6) |
| Mola | 5 saatlik pencerenin %80'i; sabaha uzanan pencerede %70 |
| Haftalık sınır | 7 günlük pencerenin %95'inde ya da bir gecede 15 puan harcayınca durur |
| Kontrol | 30 dakikada bir |
| Son başlangıç | uyanma saatinden 45 dakika önce |

### Nasıl çalışır

- **Kota:** Claude Code durum satırı betiğine 5 saatlik ve 7 günlük pencerenin kullanım
  yüzdesini ve sıfırlanma saatini verir. `save-usage.sh` bunu `~/.claude/nightshift/usage.json`
  dosyasına yazar; `usage.sh --check` bunu tek bir cevaba çevirir: çalış, mola (ve ne zamana
  kadar) ya da dur.
- **Zamanlanmış kontroller:** Claude Code'un oturum içi zamanlayıcısı. 30 dakikada bir
  kontrol, bitiş saatinde devir ve mola bitince dönüş. Oturumu kapatırsan kontroller de gider.
- **Hafıza:** uzun gecede konuşma özetlenir. Skill her işten sonra gece dosyasını yeniden
  okur; kaldığı yeri oradan bilir.

### Lisans

MIT. Yazan: Fatih Furkan Ak.
