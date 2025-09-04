import { test, expect } from "@playwright/test"

test.describe("Placeholder Pages", () => {
  const pages = [
    { name: "Season Plans", url: "/season-plans" },
    { name: "Agendas", url: "/agendas" },
    { name: "Comms", url: "/comms" },
  ]

  for (const page_info of pages) {
    test(`should display ${page_info.name} placeholder page`, async ({ page }) => {
      await page.goto(page_info.url)

      // Check for page heading
      await expect(page.locator("h1")).toContainText(page_info.name)

      // Check for coming soon message
      await expect(page.locator('text="coming soon"')).toBeVisible()

      // Verify consistent dark theme styling
      const contentCard = page.locator(".bg-slate-800")
      await expect(contentCard).toBeVisible()

      // Verify page structure matches dashboard
      const mainContainer = page.locator(".flex.flex-col.gap-6")
      await expect(mainContainer).toBeVisible()
    })
  }

  test("should maintain consistent layout across all placeholder pages", async ({ page }) => {
    for (const page_info of pages) {
      await page.goto(page_info.url)
      
      // Check consistent header structure
      const headerSection = page.locator(".flex.flex-col.gap-2")
      await expect(headerSection).toBeVisible()
      
      // Check consistent content card styling
      const contentCard = page.locator(".rounded-2xl.border.border-slate-700.bg-slate-800")
      await expect(contentCard).toBeVisible()
    }
  })
})