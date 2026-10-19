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

### Yêu cầu

- Node.js 22.x (>=22.19), 24.x (>=24.11) hoặc 26+, kèm npm.
- Linux: cần `ps` (procps) cho Ghidra/JADX/firmware và phân tích JS/Electron.
- Binary native: cần Hopper, Ghidra hoặc IDA đã cài sẵn. Phân tích JS/Electron,
  .NET, Go/Rust metadata, WASM… không cần engine native.

### Dùng

Mở Claude Code trong repo, kiểm tra bằng `/mcp` (thấy `rea` là connected), rồi hỏi ví dụ:

```text
Dùng REA phân tích /đường/dẫn/app.asar: tính năng tìm kiếm hoạt động thế nào, kèm bằng chứng.
```

Kiểm tra sức khoẻ: `npx -y rea-agents@6.7.0 doctor --client claude_code --json`

### Cập nhật phiên bản

Đổi `6.7.0` trong `.mcp.json` thành bản mới, rồi chép lại skill từ gói npm:

```bash
npm pack rea-agents@<ver> && tar xzf rea-agents-<ver>.tgz
rm -rf .claude/skills/reverse-engineer-anything
cp -r package/skills/reverse-engineer-anything .claude/skills/
cp package/LICENSE .claude/skills/reverse-engineer-anything/
```

> Chỉ tải REA từ nguồn chính thức: github.com/morluto/rea, rea.tools, hoặc npm `rea-agents`.
> Reverse engineering phải tuân thủ luật và giấy phép của phần mềm mục tiêu.
