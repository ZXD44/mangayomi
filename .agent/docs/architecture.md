# สถาปัตยกรรมระบบ Mangayomi Engine (Architecture Overview)

## โครงสร้างโปรเจกต์ (Directory Layout)
```text
mangayomi_engine/
├── .agent/                # ไฟล์ตั้งค่าและกฎระเบียบของ AI Agent
├── lib/
│   ├── cinema_core/       # ฟังก์ชันเสริม Cinema mode, ตัวดึงเว็บมังงะ & quick viewer
│   ├── core/              # ค่า config หลัก, theme, extensions, http clients
│   ├── eval/              # JavaScript bridge runtime สำหรับ source extensions
│   ├── ffi/               # FFI bindings (Rust, Go, Native C)
│   ├── l10n/              # ไฟล์ Localization & Translations
│   ├── models/            # Domain Models & Isar Collections
│   ├── modules/           # Feature UI & Business Logic (manga, anime, novel, history, etc.)
│   ├── providers/         # Global Riverpod State Providers
│   ├── repositories/      # Data access layer & Storage repositories
│   ├── router/            # Route configuration (GoRouter)
│   ├── services/          # External services & background jobs
│   └── utils/             # Helper functions เฉพาะระบบ
├── rust/                  # Rust crates & crypto / decryption engine
├── go/                    # Go Torrent streaming server & native bindings
├── proto/                 # Protocol buffer definitions สำหรับการ backup/restore
└── test/                  # Unit & Widget tests
```

## เทคโนโลยีหลัก (Core Stack)
- **UI Framework:** Flutter 3.x / Dart (SDK `^3.13.1`)
- **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Database:** Isar Community Database (`isar_community`)
- **Router:** GoRouter (`go_router`)
- **Media Player:** `media_kit` (MPV integration สำหรับ Anime/Video)
- **Cinema Mode & TTS:** `flutter_tts` พร้อมตัวอ่านภาพและพากย์ไทยอัตโนมัติ พัฒนาโดย **ZirconX (ZXD44)**
