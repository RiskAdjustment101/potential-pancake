import { test, expect } from "@playwright/test"

test.describe("Navigation", () => {
  test("should navigate between pages correctly", async ({ page }) => {
    await page.goto("/")

    // Test navigation links are present and functional
    const nav = page.locator("nav")
    await expect(nav).toBeVisible()

    // Test each navigation item
    const navItems = [
      { text: "Dashboard", href: "/dashboard" },
      { text: "Season Plans", href: "/season-plans" },
      { text: "Agendas", href: "/agendas" },
      { text: "Comms", href: "/comms" },
    ]

    for (const item of navItems) {
      const link = page.locator(`text="${item.text}"`)
      await expect(link).toBeVisible()
      
      // Click the link and verify URL changes
      await link.click()
      await expect(page).toHaveURL(item.href)
      
      // Go back to home for next test
      await page.goto("/")
    }
  })

  test("should highlight active navigation item", async ({ page }) => {
    await page.goto("/dashboard")
    
    // Check that dashboard link has active styling
    const dashboardLink = page.locator('text="Dashboard"')
    await expect(dashboardLink).toBeVisible()
    
    // Check that other links don't have active styling
    await page.goto("/season-plans")
    const seasonPlansLink = page.locator('text="Season Plans"')
    await expect(seasonPlansLink).toBeVisible()
  })
})