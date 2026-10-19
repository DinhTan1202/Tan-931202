# Tan-931202

## REA (Reverse Engineer Anything) cho Claude Code

Repo này tích hợp sẵn [REA](https://github.com/morluto/rea) (MIT, npm `rea-agents`)
ở phạm vi project, nên mọi phiên Claude Code mở thư mục này (local hoặc cloud) đều có:

| File | Tác dụng |
| --- | --- |
| `.mcp.json` | Đăng ký MCP server `rea` (`npx -y rea-agents@6.7.0 mcp`, ~200 tool) |
| `.claude/settings.json` | Tự bật server `rea` từ `.mcp.json`, không cần duyệt lại |
| `.claude/skills/reverse-engineer-anything/` | Skill hướng dẫn workflow của REA (bản đi kèm 6.7.0) |

Không sửa `~/.claude.json` hay `~/.claude/skills` của máy bạn.

### Công cụ đi kèm

| Mục đích | Công cụ | Cloud (Linux) | Windows |
| --- | --- | --- | --- |
| .exe / binary native | Ghidra 12.1.4 + JDK 21 | tự cài mỗi phiên (`.claude/hooks/session-start.sh`) | `scripts/setup-windows.ps1` (cài một lần) |
| Gỡ nén .exe | UPX | apt `upx-ucl` | winget `UPX.UPX` |
| Chạy thử .exe | Wine 9 (64 + 32-bit) | apt `wine` | không cần (chạy trực tiếp; nên dùng VM/Windows Sandbox) |
| Electron | `@electron/asar` | npm global | npm global |
| Web | Chromium/Chrome qua CDP | có sẵn, mở bằng `scripts/start-cdp-browser.sh URL` | Chrome/Edge với `--remote-debugging-port=9222` |

REA cần Node.js 22.x (>=22.19), 24.x (>=24.11) hoặc 26+. Hopper/IDA không bắt buộc.

#### Cloud (từ app điện thoại hoặc web)

Container cloud bị xoá sau mỗi phiên nên không cài hẳn được. Hook `SessionStart`
tự cài lại (khoảng 1–2 phút, chỉ chạy khi `CLAUDE_CODE_REMOTE=true`) và đặt
`GHIDRA_INSTALL_DIR=/opt/ghidra`. Hook chỉ có hiệu lực khi nằm trên nhánh mà phiên mở.

#### Windows (cài một lần)

```powershell
git clone https://github.com/DinhTan1202/Tan-931202
cd Tan-931202
powershell -ExecutionPolicy Bypass -File scripts\setup-windows.ps1
```

Script cài Node.js LTS, Microsoft OpenJDK 21, Ghidra 12.1.4 (kiểm tra SHA-256), UPX,
asar; đặt `GHIDRA_INSTALL_DIR`/`JAVA_HOME` cho user; đăng ký REA ở scope local với
`cmd.exe /d /c npx …` (Windows cần dạng này). REA hỗ trợ Ghidra trên Windows ở mức thử
nghiệm và chỉ đọc (không đổi tên hàm).

### Dùng

Mở Claude Code trong repo, kiểm tra bằng `/mcp` (thấy `rea` là connected), rồi hỏi ví dụ:

```text
Dùng REA phân tích /đường/dẫn/app.asar: tính năng tìm kiếm hoạt động thế nào, kèm bằng chứng.
```

Kiểm tra sức khoẻ: `npx -y rea-agents@6.7.0 doctor --provider ghidra --json`

### Cập nhật phiên bản

Đổi `6.7.0` trong `.mcp.json`, `.claude/hooks/session-start.sh` và `scripts/setup-windows.ps1` thành bản mới, rồi chép lại skill từ gói npm:

```bash
npm pack rea-agents@<ver> && tar xzf rea-agents-<ver>.tgz
rm -rf .claude/skills/reverse-engineer-anything
cp -r package/skills/reverse-engineer-anything .claude/skills/
cp package/LICENSE .claude/skills/reverse-engineer-anything/
```

> Chỉ tải REA từ nguồn chính thức: github.com/morluto/rea, rea.tools, hoặc npm `rea-agents`.
> Reverse engineering phải tuân thủ luật và giấy phép của phần mềm mục tiêu.
