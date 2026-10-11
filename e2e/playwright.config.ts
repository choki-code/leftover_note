import { defineConfig, devices } from "@playwright/test";

// Rails をテスト用DB（leftover_note_test）で port 3001 に立てて、そこへブラウザを向ける
const PORT = 3001;

export default defineConfig({
  testDir: "./tests",
  // テスト同士が同じDB（seed のデモユーザー）を書き換えるので、1本ずつ順に流す
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 2 : 0,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL: `http://localhost:${PORT}`,
    // 失敗したテストだけ、操作の記録（トレース）とスクショを残す
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  projects: [
    // 1. 最初にログインだけして、Cookie を .auth/user.json に保存する
    { name: "setup", testMatch: /auth\.setup\.ts/ },
    // 2. 本番のテストは、保存した Cookie を読み込んで「ログイン済み」から始める
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"], storageState: ".auth/user.json" },
      dependencies: ["setup"],
    },
  ],
  webServer: {
    // テストDBを作り直す → デモデータを入れる → サーバー起動。毎回同じ状態から始まる
    command: `bin/rails db:test:prepare && bin/rails db:seed && bin/rails server -p ${PORT}`,
    cwd: "..",
    env: { RAILS_ENV: "test" },
    url: `http://localhost:${PORT}/up`,
    // 既に動いているサーバー（開発DBかもしれない）を使い回さない
    reuseExistingServer: false,
    timeout: 120_000,
  },
});
