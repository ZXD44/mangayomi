# ขั้นตอนการทำงานและคำสั่งที่ใช้บ่อย (Runbooks & Workflows)

## 1. คำสั่ง Dependency & Code Generation
```bash
# ติดตั้ง dependencies
flutter pub get

# รัน build_runner เพื่อสร้างโค้ด Riverpod / Isar / Freezed
dart run build_runner build --delete-conflicting-outputs

# รันแบบเฝ้าดูความเปลี่ยนแปลง (Watch Mode)
dart run build_runner watch --delete-conflicting-outputs
```

## 2. คำสั่ง Native FFI Generation
```bash
# สร้างโค้ด Protobuf
cd proto && ./gen_proto.sh && cd ..

# สร้างบริดจ์ Rust
flutter_rust_bridge_codegen generate

# คอมไพล์ Go torrent server
cd go && ./build_go.sh && cd ..
```

## 3. การตรวจสอบคุณภาพโค้ด (Quality Assurance)
```bash
# วิเคราะห์ Lint ตาม analysis_options.yaml
flutter analyze

# หรือใช้ Dart analyze โดยตรง
dart analyze lib/cinema_core/ lib/modules/more/about/

# รันชุดทดสอบ
flutter test
```
