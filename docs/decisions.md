# 決定ログ

## 前提（2026-10-06 に確認）
- 2026-10-01(PT) に claude.dev/terminal で `/plushies` `/stickers` と打つと、無料配布の申込フォームが表示された。配布は当日中に終了。
- 定期的な復活の公式告知はない。根拠は表示文の「All claimed for now. Thanks for the love.」だけ。
- 在庫の有無は `https://claude.dev/terminal/swag-status.json` で決まる（終了時点の値は `{"off":["stickers","plushie"]}`、`Cache-Control: no-store`）。ページのスクリプトは、ここに含まれる ID を「在庫なし」として表示する。
- 申込フォームは `https://app.brilliantmade.com/r/claude-code-plushies` と `.../claude-code-stickers`（終了後は `/sorry` にリダイレクトされる）。
- 応募条件（ページ内の文言）: Free, no purchase needed. While supplies last, one per person. 18+. Ships only where Brilliant ships. Void where prohibited. We can end it at any time.

## 決定
| 日付 | 決定 | 理由 |
|---|---|---|
| 2026-10-06 | 自動応募はしない。通知だけ行い、応募は手動 | フォームが閉じていて動作確認ができない／1回目は数時間かけて在庫がなくなったので通知で間に合う／「1人1つ・いつでも終了あり」の条件で無効にされる恐れがある |
| 2026-10-06 | PC ではなくクラウドで監視する | 1回目の開始は日本時間の深夜〜朝だった |
| 2026-10-07 | Claude Code のクラウドセッション（定期実行）は使わず、GitHub Actions・公開リポ・10分ごとにする | 定期実行は最短1時間・毎回 Claude の使用量を消費・claude.dev への通信は標準で遮断・結局リポジトリも必要 |
