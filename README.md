# claude-swag-watch

[Claude Terminal](https://claude.dev/terminal/) の Clawd ぬいぐるみ・ステッカーの配布状況を、GitHub Actions で10分ごとに確認します。2026-10-01 に終了した無料配布の再開やフォームの変更に気づくための監視です。通知だけを行い、フォームの送信や自動応募はしません。応募は通知を見た本人が手動で行います。

## 仕組み

次の2点を確認し、どちらかが基準と異なる場合に `swag-alert` ラベルの Issue を作成してリポジトリのオーナーを @メンションします。

1. [swag-status.json](https://claude.dev/terminal/swag-status.json) の `.off` をソートし、`["plushie","stickers"]`（両方とも配布終了）と比較します。`.off` が文字列の配列でない場合や取得に失敗した場合は、エラーで終了します。
2. Terminal の HTML から `https://app.brilliantmade.com/r/` で始まるフォーム URL を抽出し、重複を除いて次の2件と比較します。追加・削除に加え、URL がすべて消えた場合も通知します。

   - https://app.brilliantmade.com/r/claude-code-plushies
   - https://app.brilliantmade.com/r/claude-code-stickers

開いている `swag-alert` Issue がある間は追加の Issue を作りません。確認後に Issue を閉じると通知が再び有効になります。基準と異なる状態が続いていれば、閉じた後の次回実行でも通知されます。変更の検出は、在庫の復活を保証するものではありません。

通知が届いたら https://claude.dev/terminal/ を開き、`/plushies` または `/stickers` と入力してください。

## スマートフォンで通知を受け取る

1. GitHub モバイルアプリに、リポジトリのオーナーのアカウントでログインします。
2. アプリとスマートフォン本体の設定で GitHub の通知を有効にし、@メンションの通知を受け取れるようにします。
3. リポジトリの **Actions → watch → Run workflow** で **test=true** にして実行し、通知が届くことを確認します。

テストでは `[TEST] claude-swag-watch 通知テスト` というタイトルの `swag-test` Issue を毎回作成します。通常の監視や重複防止の判定は行いません。確認後はテスト Issue を閉じてください。

## 停止方法と実行間隔

停止するには **Actions → watch → メニュー → Disable workflow** を選びます。

定期実行はデフォルトブランチ上のワークフローを使います。cron は10分ごとの設定ですが、GitHub Actions の混雑などで実行が遅れたり、実行が省略されたりすることがあります。また、公開リポジトリで60日間リポジトリの活動がない場合、定期実行ワークフローは自動的に無効になります。[GitHub の定期実行に関する説明](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#schedule)を参照してください。

## ローカルでのテスト

Bash（Windows は Git Bash）、`curl`、`jq` を用意し、リポジトリのルートで実行します。

```bash
bash tests/run.sh
```

ローカルの fixture を `file://` URL で読み、すべて `--dry-run` で検証するので Issue は作成しません。PR の CI では ShellCheck と同じテストを実行します。

```bash
bash watch.sh --dry-run
bash watch.sh --dry-run --test
```

`STATUS_URL`、`TERMINAL_URL`、`NOTIFY_USER` を環境変数で変更できます。既定値はそれぞれ `https://claude.dev/terminal/swag-status.json`、`https://claude.dev/terminal/`、`ko-dhinngumuzuiyoo` です。Issue を実際に作る実行には GitHub CLI (`gh`) と認証が必要です。Actions では `GH_TOKEN`、`GH_REPO`、通知先のオーナーを自動設定します。

設計の経緯は[決定ログ](docs/decisions.md)を参照してください。
