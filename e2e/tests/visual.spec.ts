import { test, expect } from "@playwright/test";

test("上位5品の棒グラフの見た目が変わっていない", async ({ page }) => {
  await page.goto("/analysis");

  const ranking = page.locator(".card", { has: page.getByRole("heading", { name: "残食率が高い上位5品" }) });
  await expect(ranking.locator(".bar-row")).toHaveCount(5);

  // 1回目（--update-snapshots）で正解画像を保存し、2回目以降はそれと比べる
  await expect(ranking).toHaveScreenshot("ranking.png");
});
