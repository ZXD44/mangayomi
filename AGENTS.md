# Mangayomi Engine - Agent Rules & Instructions (.agent / AGENTS.md)

ไฟล์นี้กำหนดบริบท กฎเกณฑ์ โครงสร้างโปรเจกต์ และขั้นตอนการทำงานสำหรับ AI Agent และนักพัฒนาในโปรเจกต์ **Mangayomi Engine**

---

## 1. ข้อมูลภาพรวมของโปรเจกต์ (Project Overview)
- **ชื่อโปรเจกต์:** Mangayomi Engine (`mangayomi`)
- **เทคโนโลยีหลัก:**
  - **Flutter / Dart** (SDK `^3.13.1`, Flutter 3.x)
  - **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`, `build_runner`)
  - **Database:** Isar Community Database (`isar_community`)
  - **Router:** GoRouter (`go_router`)
  - **Native / FFI:** Rust (`flutter_rust_bridge`), Go backend/torrent server (`go/`), FFI bindings (`proto/`, `ffigen`)
  - **Media Player:** `media_kit` (MPV integration สำหรับเล่น Anime/Video)

---

## 2. โครงสร้างไดเรกทอรีสำคัญ (Architecture & Directory Layout)
```text
mangayomi_engine/
├── lib/
│   ├── cinema_core/       # ฟังก์ชันเสริม Cinema mode & quick viewer
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

---

## 3. กฎเหล็กในการพัฒนา (Core Rules & Constraints)

### 3.1 Cognitive Invariants & Code Hygiene
1. **Zero Fluff & High Density:** สื่อสารตรงประเด็น ไม่อารัมภบท ไม่ใช้คำฟุ่มเฟือย
2. **Cyclomatic Complexity:** ความซับซ้อนของแต่ละฟังก์ชันไม่เกิน 7, ความยาว logic ไม่เกิน 70 บรรทัด (ยกเว้น Declarative UI)
3. **Guard Clauses First:** ใช้ early returns / guard clauses เสมอ ความลึก nesting ห้ามเกิน 3 ชั้น
4. **No Forbidden Identifiers:** ห้ามตั้งชื่อตัวแปรคลุมเครือ เช่น `data`, `res`, `req`, `item`, `val`, `temp`, `obj`, `payload`, `result`, `handleData` ใน domain models/state
5. **No Junk Drawers:** ห้ามสร้างโฟลเดอร์ขยะรวมโค้ด เช่น `utils/`, `helpers/`, `common/` เพิ่มเติม ให้วางโค้ดไว้ใน feature domain นั้นๆ
6. **Error Handling:** ห้ามใช้ `catch (_) {}` ว่างเปล่า หรือ swallow error เด็ดขาด ต้องจัดการ typed exception หรือ log อย่างมีระเบียบ

### 3.2 Flutter & Dart Best Practices
- **Riverpod State:** ใช้ Code Generation (`@riverpod`) เมื่อสร้าง provider ใหม่ รัน `dart run build_runner build --delete-conflicting-outputs`
- **UI & Theming:** อิงดีไซน์จาก FlexColorScheme ไม่ใช้สี saturated แบบ hardcoded (`#ff0000`, `#0000ff`)
- **Immutability:** Model ต้องเป็น immutable หรือ Isar-compliant collection
- **Preservation Shield:** ห้ามแตะต้องหรือ refactor โค้ดส่วนอื่นที่ไม่เกี่ยวข้องกับคำสั่งงานโดยพลการ (Ghost edit shield)

---

## 4. คำสั่งที่ใช้บ่อย (Common Commands & Runbooks)

### 4.1 Dependency & Code Generation
```bash
# ติดตั้ง dependencies
flutter pub get

# Generate Code (Riverpod, Isar, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Watch Mode ระหว่างพัฒนา
dart run build_runner watch --delete-conflicting-outputs
```

### 4.2 Native & FFI Generation
```bash
# Protobuf code generation
cd proto && ./gen_proto.sh && cd ..

# Rust Bridge generation
flutter_rust_bridge_codegen generate

# Go server build
cd go && ./build_go.sh && cd ..
```

### 4.3 Lint, Analysis & Test
```bash
# ตรวจสอบโค้ดตาม analysis_options.yaml
flutter analyze

# รันชุดทดสอบ
flutter test
```

---

## 5. มาตรฐานการส่งมอบงาน (Completion Checklist)
- [ ] โค้ดไม่มี Compile Error และผ่าน `flutter analyze`
- [ ] ฟังก์ชันไม่มีตัวแปร Generic ที่ถูกห้าม (`data`, `temp`, `res`, ฯลฯ)
- [ ] ไม่ทิ้ง TODO หรือ Mock stub ไว้ใน Production code
- [ ] ตรวจสอบว่าไม่มีผลกระทบต่อ Caller อื่น (Blast Radius Audit)
