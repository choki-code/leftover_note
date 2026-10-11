import { test as setup, expect } from "@playwright/test";

// db/seeds.rb が作るデモユーザー。テストDB専用の値
const EMAIL = "demo@example.com";
const PASSWORD = "demo-password";

setup("デモユーザーでログインする", async ({ page }) => {
  await page.goto("/users/sign_in");
  await page.getByLabel("メールアドレス").fill(EMAIL);
  await page.getByLabel("パスワード").fill(PASSWORD);
  await page.getByRole("button", { name: "ログイン" }).click();

  await expect(page.getByRole("heading", { name: "献立一覧" })).toBeVisible();
  await page.context().storageState({ path: ".auth/user.json" });
});
