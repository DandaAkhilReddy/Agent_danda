import { test, expect } from '@playwright/test'

test.describe('Waitlist Form E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000')
  })

  test('should display homepage with all sections', async ({ page }) => {
    // Check hero section
    await expect(page.getByRole('heading', { name: /Screenshot. AI Analyzes. Reply Ready/i })).toBeVisible()

    // Check navigation
    await expect(page.locator('nav')).toContainText('AgentChains')

    // Check waitlist section exists
    await expect(page.getByRole('heading', { name: /Join the Waitlist/i })).toBeVisible()
  })

  test('should scroll to waitlist section when clicking Join Waitlist button', async ({ page }) => {
    // Click the CTA button in nav
    await page.getByRole('link', { name: /Join Waitlist/i }).first().click()

    // Wait for scroll animation
    await page.waitForTimeout(500)

    // Check that waitlist form is in viewport
    const waitlistSection = page.locator('#waitlist')
    await expect(waitlistSection).toBeInViewport()
  })

  test('should validate required fields', async ({ page }) => {
    // Navigate to waitlist section
    await page.locator('#waitlist').scrollIntoViewIfNeeded()

    // Try to submit empty form
    await page.getByRole('button', { name: /Join the Waitlist.*🚀/i }).click()

    // Check browser validation messages (HTML5 validation)
    const nameInput = page.getByPlaceholder(/Your name/i)
    const emailInput = page.getByPlaceholder(/your@email.com/i)

    // Check that inputs are marked as invalid
    await expect(nameInput).toHaveAttribute('required', '')
    await expect(emailInput).toHaveAttribute('required', '')
  })

  test('should complete full waitlist form submission flow', async ({ page }) => {
    // Navigate to waitlist section
    await page.locator('#waitlist').scrollIntoViewIfNeeded()

    // Fill in name
    await page.getByPlaceholder(/Your name/i).fill('E2E Test User')

    // Fill in email
    await page.getByPlaceholder(/your@email.com/i).fill('e2e@test.com')

    // Fill in phone (optional)
    await page.getByPlaceholder(/555/i).fill('+1234567890')

    // Select ChatGPT usage - use radio input directly
    await page.locator('input[type="radio"][value="yes-all-the-time"]').check()

    // Select struggles (checkboxes) - use checkbox inputs directly
    await page.locator('input[type="checkbox"][value="Taking too long to reply"]').check()
    await page.locator('input[type="checkbox"][value="Don\'t know what to say"]').check()

    // Select apps (checkboxes)
    await page.locator('input[type="checkbox"][value="WhatsApp"]').check()
    await page.locator('input[type="checkbox"][value="iMessage"]').check()

    // Select time spent
    await page.getByRole('combobox').selectOption('1-2hours')

    // Fill in ideas
    await page.getByPlaceholder(/Share your thoughts/i).fill('This is an amazing product idea!')

    // Submit form
    await page.getByRole('button', { name: /Join the Waitlist.*🚀/i }).click()

    // Wait for success message
    await expect(page.getByText(/You're on the List!/i)).toBeVisible({ timeout: 5000 })
    await expect(page.getByText(/Thank you for joining!/i)).toBeVisible()
  })

  test('should handle email validation', async ({ page }) => {
    await page.locator('#waitlist').scrollIntoViewIfNeeded()

    // Fill in name
    await page.getByPlaceholder(/Your name/i).fill('Test User')

    // Fill in invalid email
    await page.getByPlaceholder(/your@email.com/i).fill('invalid-email')

    // Select radio button using value
    await page.locator('input[type="radio"][value="yes-all-the-time"]').check()

    // Select dropdown
    await page.getByRole('combobox').selectOption('less-than-30min')

    // Try to submit
    await page.getByRole('button', { name: /Join the Waitlist.*🚀/i }).click()

    // Browser should show validation error for email
    const emailInput = page.getByPlaceholder(/your@email.com/i)
    await expect(emailInput).toHaveAttribute('type', 'email')
  })

  test('should show loading state during submission', async ({ page }) => {
    await page.locator('#waitlist').scrollIntoViewIfNeeded()

    // Fill minimum required fields
    await page.getByPlaceholder(/Your name/i).fill('Test User')
    await page.getByPlaceholder(/your@email.com/i).fill('test@example.com')
    await page.locator('input[type="radio"][value="yes-all-the-time"]').check()
    await page.getByRole('combobox').selectOption('less-than-30min')

    // Submit form
    await page.getByRole('button', { name: /Join the Waitlist.*🚀/i }).click()

    // Check for loading state (button should show "Submitting...")
    await expect(page.getByText(/Submitting.../i)).toBeVisible({ timeout: 1000 })
  })

  test('should handle checkbox "Other" option for struggles', async ({ page }) => {
    await page.locator('#waitlist').scrollIntoViewIfNeeded()

    // Check "Other" checkbox using value
    await page.locator('input[type="checkbox"][value="Other"]').first().check()

    // Check that the "Other" text input appears or is enabled
    const otherInput = page.locator('input[type="text"]').filter({ hasText: '' }).first()
    await expect(otherInput).toBeVisible()
  })

  test('should display all pricing tiers', async ({ page }) => {
    // Scroll to pricing section
    await page.locator('#pricing').scrollIntoViewIfNeeded()

    // Check for actual pricing tiers (Free, Pro, Enterprise)
    await expect(page.getByText('Free')).toBeVisible()
    await expect(page.getByText('Pro')).toBeVisible()
    await expect(page.getByText('Enterprise')).toBeVisible()
  })

  test('should navigate to demo section', async ({ page }) => {
    // Click demo link in nav - use first() to avoid strict mode violation
    await page.getByRole('link', { name: /Demo/i }).first().click()

    // Wait for scroll
    await page.waitForTimeout(500)

    // Check that demo section is visible
    const demoSection = page.locator('#demo')
    await expect(demoSection).toBeInViewport()
  })

  test('should have responsive navigation menu', async ({ page }) => {
    // Check desktop navigation - use first() to target nav links specifically
    await expect(page.getByRole('navigation').getByRole('link', { name: /How It Works/i })).toBeVisible()
    await expect(page.getByRole('navigation').getByRole('link', { name: /Demo/i })).toBeVisible()
    await expect(page.getByRole('navigation').getByRole('link', { name: /Pricing/i })).toBeVisible()
  })

  test('should display roadmap section', async ({ page }) => {
    // Scroll to bottom
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight))

    // Wait for roadmap section
    await page.waitForTimeout(500)

    // Check for roadmap items
    await expect(page.getByText(/iOS App/i)).toBeVisible()
    await expect(page.getByText(/In Development/i)).toBeVisible()
  })
})
