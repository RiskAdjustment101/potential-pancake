import { test, expect } from "@playwright/test"

test.describe("Dashboard", () => {
  test("should display dashboard page content", async ({ page }) => {
    await page.goto("/dashboard")

    // Check for dashboard heading
    await expect(page.locator("h1")).toContainText("Dashboard")

    // Check for subtitle
    await expect(page.locator('text="Your mentor command center"')).toBeVisible()

    // Check for placeholder content
    await expect(page.locator('text="Dashboard content coming soon..."')).toBeVisible()

    // Verify dark theme styling is applied
    const contentCard = page.locator(".bg-slate-800")
    await expect(contentCard).toBeVisible()
  })

  test("should have proper page structure", async ({ page }) => {
    await page.goto("/dashboard")

    // Check for main content container
    const mainContainer = page.locator(".flex.flex-col.gap-6")
    await expect(mainContainer).toBeVisible()

    // Check for header section
    const headerSection = page.locator(".flex.flex-col.gap-2")
    await expect(headerSection).toBeVisible()

    // Check for content card
    const contentCard = page.locator(".rounded-2xl.border.border-slate-700")
    await expect(contentCard).toBeVisible()
  })
})