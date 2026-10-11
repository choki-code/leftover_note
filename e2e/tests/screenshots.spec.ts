import { test, expect } from "@playwright/test";

test("分析シートの棒グラフを撮る", async ({ page }) => {
  await page.goto("/analysis");

  // 見出し「残食率が高い上位5品」を含むカードだけを取り出す
  const ranking = page.locator(".card", { has: page.getByRole("heading", { name: "残食率が高い上位5品" }) });
  await expect(ranking.locator(".bar-row")).toHaveCount(5);

  await ranking.screenshot({ path: "shots/ranking.png" });
  await page.screenshot({ path: "shots/analysis-full.png", fullPage: true });
});
