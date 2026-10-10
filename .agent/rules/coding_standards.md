# กฎการเขียนโค้ดและมาตรฐานการพัฒนา (Coding Standards & Hygiene)

## 1. Cognitive Invariants & Code Hygiene
- **Zero Fluff & Structural Determinism:** กระชับ ตรงประเด็น ไม่อารัมภบท
- **Cyclomatic Complexity:** ความซับซ้อนของแต่ละฟังก์ชันห้ามเกิน 7, ความยาว logic ห้ามเกิน 70 บรรทัด (ยกเว้น Declarative UI)
- **Guard Clauses First:** ใช้ early returns เสมอ ห้าม nesting ลึกเกิน 3 ชั้น
- **No Forbidden Identifiers:** ห้ามตั้งชื่อตัวแปรคลุมเครือ เช่น `data`, `res`, `req`, `item`, `val`, `temp`, `obj`, `payload`, `result`, `handleData` ใน domain models/state
- **No Junk Drawers:** ห้ามสร้างโฟลเดอร์ generic เพิ่มเติม เช่น `utils/`, `helpers/`, `common/` ให้วางโค้ดไว้ใน feature domain นั้นๆ
- **Error Handling:** ห้ามใช้ `catch (_) {}` ว่างเปล่า หรือ swallow error เด็ดขาด ต้องจัดการ typed exception หรือ log อย่างมีระเบียบ

## 2. Flutter & Dart Best Practices
- **Riverpod State:** ใช้ Code Generation (`@riverpod`) สำหรับ provider ใหม่ รัน `dart run build_runner build --delete-conflicting-outputs`
- **UI & Theming:** อิงดีไซน์จาก FlexColorScheme ไม่ใช้สี saturated แบบ hardcoded (`#ff0000`, `#0000ff`)
- **Immutability:** Model ต้องเป็น immutable หรือ Isar-compliant collection
- **Preservation Shield:** ห้ามแตะต้องหรือ refactor โค้ดส่วนอื่นที่ไม่เกี่ยวข้องกับคำสั่งงานโดยพลการ (Ghost edit shield)
