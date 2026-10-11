import { test, expect } from "@playwright/test";

test("献立一覧に、デモデータの献立が並ぶ", async ({ page }) => {
  await page.goto("/");

  await expect(page.getByRole("heading", { name: "献立一覧" })).toBeVisible();
  await expect(page.getByText("ひまわり小学校")).toBeVisible();
  await expect(page.getByRole("row")).not.toHaveCount(0);
});

test("残食を入力すると、料理詳細の棒グラフに反映される", async ({ page }) => {
  // 献立一覧 → 一番上の献立を開く
  await page.goto("/menus");
  await page.getByRole("row").nth(1).getByRole("link").first().click();
  // 献立詳細に切り替わるのを待つ。待たずに読むと、まだ一覧の行（日付）を読んでしまう
  await expect(page).toHaveURL(/\/menus\/\d+$/);

  // 1品目の料理名を覚えてから、残食入力画面へ
  const dishName = await page.getByRole("row").nth(1).getByRole("link").first().innerText();
  await page.getByRole("link", { name: "残食を入力する" }).click();

  // 1品目の残食量を書き換えて保存
  await page.getByLabel("残食量（kg）").first().fill("0.5");
  await page.getByRole("button", { name: "保存する" }).click();

  // 料理詳細を開くと、残食率の比較グラフが出ている
  await page.getByRole("link", { name: dishName }).first().click();
  await expect(page.getByRole("heading", { name: "残食率の比較" })).toBeVisible();
  await expect(page.getByText("0.5 kg")).toBeVisible();
});

test("ログインしていないと、ログイン画面に戻される", async ({ browser }) => {
  // 保存した Cookie を使わない、まっさらなブラウザで開く
  const context = await browser.newContext({ storageState: undefined });
  const page = await context.newPage();

  await page.goto("http://localhost:3001/analysis");
  await expect(page).toHaveURL(/\/users\/sign_in/);
  await context.close();
});
