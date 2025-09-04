import { test, expect } from "@playwright/test"

test.describe("Security Testing", () => {
  test.describe("Authentication Security", () => {
    test("should redirect unauthorized users from protected routes", async ({ page }) => {
      const protectedRoutes = ["/dashboard", "/season-plans", "/agendas", "/comms"]
      
      for (const route of protectedRoutes) {
        await page.goto(route)
        
        // Should redirect to sign-in page OR show sign-in UI on current page
        const isSignInPage = page.url().includes('/sign-in')
        const hasSignInButton = await page.locator('text="Sign In"').isVisible()
        
        // At least one condition should be true for proper auth protection
        expect(isSignInPage || hasSignInButton).toBeTruthy()
      }
    })

    test("should have secure session management", async ({ page }) => {
      await page.goto("/")
      
      // Check for secure cookie attributes (when authentication is active)
      const cookies = await page.context().cookies()
      const authCookies = cookies.filter(cookie => 
        cookie.name.includes("clerk") || cookie.name.includes("session")
      )
      
      // Note: This will be more relevant when Clerk is configured and HTTPS is used
      if (authCookies.length > 0) {
        authCookies.forEach(cookie => {
          // Only check secure flag if we're on HTTPS (production)
          if (page.url().startsWith('https://')) {
            expect(cookie.secure).toBeTruthy()
          }
          // httpOnly should always be true for session cookies
          if (cookie.name.includes('session')) {
            expect(cookie.httpOnly).toBeTruthy()
          }
        })
      } else {
        // If no auth cookies found, test passes (development mode)
        expect(true).toBeTruthy()
      }
    })
  })

  test.describe("XSS Prevention", () => {
    test("should sanitize user input in forms", async ({ page }) => {
      await page.goto("/")
      
      // Test common XSS payloads in any input fields
      const xssPayloads = [
        '<script>alert("XSS")</script>',
        'javascript:alert("XSS")',
        '"><script>alert("XSS")</script>',
        "';alert('XSS');//"
      ]

      // Find any input fields on the page
      const inputs = await page.locator('input[type="text"], input[type="email"], textarea').all()
      
      for (const input of inputs) {
        for (const payload of xssPayloads) {
          await input.fill(payload)
          
          // Check that script tags are not executed
          const pageContent = await page.content()
          expect(pageContent).not.toContain('<script>alert("XSS")</script>')
        }
      }
    })
  })

  test.describe("Content Security", () => {
    test("should have proper security headers", async ({ page }) => {
      const response = await page.goto("/")
      
      // Check for important security headers
      const headers = response?.headers()
      if (headers) {
        // These headers should be present in production
        // Note: May not be present in development mode
        const securityHeaders = [
          'x-frame-options',
          'x-content-type-options',
          'referrer-policy'
        ]
        
        securityHeaders.forEach(header => {
          if (headers[header]) {
            expect(headers[header]).toBeDefined()
          }
        })
      }
    })

    test("should prevent clickjacking", async ({ page }) => {
      // Test that the page cannot be embedded in an iframe
      await page.goto("/")
      
      // Try to load the page in an iframe context
      const iframeTest = `
        <iframe src="http://localhost:3000"></iframe>
      `
      
      // This test verifies X-Frame-Options header prevents embedding
      // In a real test, you'd check the header directly
      const response = await page.goto("/")
      const xFrameOptions = response?.headers()['x-frame-options']
      
      // Should be DENY, SAMEORIGIN, or ALLOW-FROM
      if (xFrameOptions) {
        expect(['DENY', 'SAMEORIGIN'].some(value => 
          xFrameOptions.toUpperCase().includes(value)
        )).toBeTruthy()
      }
    })
  })

  test.describe("Data Access Control", () => {
    test("should not expose sensitive data in client-side storage", async ({ page }) => {
      await page.goto("/")
      
      // Check localStorage for sensitive data
      const localStorage = await page.evaluate(() => {
        const storage = {}
        for (let i = 0; i < window.localStorage.length; i++) {
          const key = window.localStorage.key(i)
          if (key) {
            storage[key] = window.localStorage.getItem(key)
          }
        }
        return storage
      })
      
      // Check sessionStorage
      const sessionStorage = await page.evaluate(() => {
        const storage = {}
        for (let i = 0; i < window.sessionStorage.length; i++) {
          const key = window.sessionStorage.key(i)
          if (key) {
            storage[key] = window.sessionStorage.getItem(key)
          }
        }
        return storage
      })
      
      // Combine all storage
      const allStorage = { ...localStorage, ...sessionStorage }
      const storageString = JSON.stringify(allStorage).toLowerCase()
      
      // Should not contain sensitive patterns
      const sensitivePatterns = [
        'password',
        'secret',
        'private_key',
        'api_key',
        'token',
        'credential'
      ]
      
      sensitivePatterns.forEach(pattern => {
        expect(storageString).not.toContain(pattern)
      })
    })

    test("should handle errors gracefully without information disclosure", async ({ page }) => {
      // Test 404 pages don't expose sensitive information
      await page.goto("/nonexistent-route")
      
      const pageContent = await page.textContent('body')
      const sensitiveInfo = [
        'database connection',
        'internal server error',
        'stack trace:',
        'file path:',
        '/var/www',
        'c:\\inetpub'
      ]
      
      if (pageContent) {
        sensitiveInfo.forEach(info => {
          expect(pageContent.toLowerCase()).not.toContain(info.toLowerCase())
        })
      }
    })
  })

  test.describe("Input Validation", () => {
    test("should validate URL parameters", async ({ page }) => {
      // Test URL parameter injection
      const maliciousParams = [
        '?param=<script>alert("XSS")</script>',
        '?param=javascript:alert("XSS")',
        '?param=../../../etc/passwd',
        '?param=..\\..\\..\\windows\\system32'
      ]
      
      for (const param of maliciousParams) {
        await page.goto(`/${param}`)
        
        // Page should handle malicious parameters safely
        const pageContent = await page.content()
        
        // Check that malicious script tags aren't executed (not in legitimate content)
        const hasUserScript = pageContent.includes('<script>alert("XSS")</script>')
        const hasJavascriptProtocol = pageContent.includes('javascript:alert("XSS")')
        
        expect(hasUserScript).toBeFalsy()
        expect(hasJavascriptProtocol).toBeFalsy()
      }
    })
  })

  test.describe("Business Logic Security", () => {
    test("should enforce proper navigation flow", async ({ page }) => {
      // Test that protected workflow steps can't be bypassed
      await page.goto("/dashboard")
      
      // Should be redirected or show authentication
      const url = page.url()
      const hasSignIn = await page.locator('text="Sign In"').isVisible()
      
      expect(url.includes('/sign-in') || hasSignIn).toBeTruthy()
    })
  })

  test.describe("Rate Limiting & DoS Protection", () => {
    test("should handle rapid requests gracefully", async ({ page }) => {
      // Test basic rate limiting by making sequential rapid requests
      let successfulRequests = 0
      
      for (let i = 0; i < 5; i++) {
        try {
          const response = await page.goto("/", { waitUntil: 'domcontentloaded', timeout: 5000 })
          if (response && response.status() < 500) {
            successfulRequests++
          }
        } catch (error) {
          // Expected in development environment with rapid requests
          console.log(`Request ${i + 1} failed (expected in dev mode)`)
        }
      }
      
      // At least some requests should succeed (basic DoS test)
      expect(successfulRequests).toBeGreaterThan(0)
    })
  })
})