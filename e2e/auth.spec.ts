import { test, expect } from "@playwright/test"

test.describe("Authentication", () => {
  test("should display sign in button when not authenticated", async ({ page }) => {
    await page.goto("/")

    // Should show sign in button for unauthenticated users
    await expect(page.locator('text="Sign In"')).toBeVisible()
    await expect(page.locator('text="Create Account"')).toBeVisible()
  })

  test("should display landing page content", async ({ page }) => {
    await page.goto("/")

    // Check for main heading
    await expect(page.locator("h1")).toContainText("Welcome to FLL Mentor Copilot")

    // Check for main description
    await expect(page.locator('text="Your AI-powered assistant"')).toBeVisible()
  })

  test("navigation should work", async ({ page }) => {
    await page.goto("/")

    // Check navigation elements are present
    const nav = page.locator("nav")
    await expect(nav).toBeVisible()

    // Check navigation links
    await expect(page.locator('text="Dashboard"')).toBeVisible()
    await expect(page.locator('text="Season Plans"')).toBeVisible()
    await expect(page.locator('text="Agendas"')).toBeVisible()
    await expect(page.locator('text="Comms"')).toBeVisible()
  })
})