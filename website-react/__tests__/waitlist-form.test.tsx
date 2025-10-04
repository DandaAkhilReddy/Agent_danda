import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Home from '../app/page'
import { addDoc } from 'firebase/firestore'

// Mock Firebase
jest.mock('firebase/firestore')

describe('Waitlist Form Integration Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Form Rendering', () => {
    it('should render the waitlist form section', () => {
      render(<Home />)
      expect(screen.getByRole('heading', { name: /Join the Waitlist/i })).toBeInTheDocument()
    })

    it('should render all required form fields', () => {
      render(<Home />)

      expect(screen.getByPlaceholderText(/Your name/i)).toBeInTheDocument()
      expect(screen.getByPlaceholderText(/your@email.com/i)).toBeInTheDocument()
      expect(screen.getByText(/Are you currently using ChatGPT/i)).toBeInTheDocument()
      expect(screen.getByText(/What's your biggest struggle/i)).toBeInTheDocument()
      expect(screen.getByText(/Which apps do you use most/i)).toBeInTheDocument()
    })

    it('should render the submit button', () => {
      render(<Home />)
      expect(screen.getByRole('button', { name: /Join the Waitlist/i })).toBeInTheDocument()
    })
  })

  describe('Form Validation', () => {
    it('should require name field', async () => {
      render(<Home />)
      const submitButton = screen.getByRole('button', { name: /Join the Waitlist/i })

      fireEvent.click(submitButton)

      const nameInput = screen.getByPlaceholderText(/Your name/i) as HTMLInputElement
      expect(nameInput.validity.valid).toBe(false)
    })

    it('should require email field', async () => {
      render(<Home />)
      const submitButton = screen.getByRole('button', { name: /Join the Waitlist/i })

      fireEvent.click(submitButton)

      const emailInput = screen.getByPlaceholderText(/your@email.com/i) as HTMLInputElement
      expect(emailInput.validity.valid).toBe(false)
    })

    it('should validate email format', async () => {
      render(<Home />)
      const emailInput = screen.getByPlaceholderText(/your@email.com/i) as HTMLInputElement

      await userEvent.type(emailInput, 'invalid-email')
      expect(emailInput.validity.valid).toBe(false)

      await userEvent.clear(emailInput)
      await userEvent.type(emailInput, 'valid@email.com')
      expect(emailInput.validity.valid).toBe(true)
    })
  })

  describe('Form Input Handling', () => {
    it('should handle text input changes', async () => {
      render(<Home />)

      const nameInput = screen.getByPlaceholderText(/Your name/i)
      await userEvent.type(nameInput, 'John Doe')
      expect(nameInput).toHaveValue('John Doe')

      const emailInput = screen.getByPlaceholderText(/your@email.com/i)
      await userEvent.type(emailInput, 'john@example.com')
      expect(emailInput).toHaveValue('john@example.com')
    })

    it('should handle radio button selection', async () => {
      render(<Home />)

      const radioOptions = screen.getAllByRole('radio')
      expect(radioOptions.length).toBeGreaterThan(0)

      await userEvent.click(radioOptions[0])
      expect(radioOptions[0]).toBeChecked()
    })

    it('should handle checkbox selections', async () => {
      render(<Home />)

      const checkboxes = screen.getAllByRole('checkbox')
      expect(checkboxes.length).toBeGreaterThan(0)

      // Select multiple checkboxes
      await userEvent.click(checkboxes[0])
      await userEvent.click(checkboxes[1])

      expect(checkboxes[0]).toBeChecked()
      expect(checkboxes[1]).toBeChecked()
    })

    it('should handle textarea input', async () => {
      render(<Home />)

      const textareas = screen.getAllByRole('textbox')
      const ideasTextarea = textareas.find(
        (textarea) => textarea.getAttribute('placeholder')?.includes('thoughts')
      )

      if (ideasTextarea) {
        await userEvent.type(ideasTextarea, 'Great product idea!')
        expect(ideasTextarea).toHaveValue('Great product idea!')
      }
    })
  })

  describe('Form Submission', () => {
    it('should submit form with valid data', async () => {
      const mockAddDoc = addDoc as jest.MockedFunction<typeof addDoc>
      mockAddDoc.mockResolvedValueOnce({ id: 'test-id' } as any)

      render(<Home />)

      // Fill in required fields
      const nameInput = screen.getByPlaceholderText(/Your name/i)
      const emailInput = screen.getByPlaceholderText(/your@email.com/i)

      await userEvent.type(nameInput, 'Test User')
      await userEvent.type(emailInput, 'test@example.com')

      // Select radio button
      const radioOptions = screen.getAllByRole('radio')
      await userEvent.click(radioOptions[0])

      // Select dropdown
      const dropdown = screen.getByRole('combobox')
      await userEvent.selectOptions(dropdown, 'less-than-30min')

      // Submit form
      const submitButton = screen.getByRole('button', { name: /Join the Waitlist/i })
      await userEvent.click(submitButton)

      // Wait for Firebase call
      await waitFor(() => {
        expect(mockAddDoc).toHaveBeenCalledTimes(1)
      }, { timeout: 3000 })
    })

    it('should show loading state during submission', async () => {
      const mockAddDoc = addDoc as jest.MockedFunction<typeof addDoc>
      mockAddDoc.mockImplementation(() => new Promise(resolve => setTimeout(resolve, 1000)))

      render(<Home />)

      // Fill required fields
      await userEvent.type(screen.getByPlaceholderText(/Your name/i), 'Test User')
      await userEvent.type(screen.getByPlaceholderText(/your@email.com/i), 'test@example.com')

      const radioOptions = screen.getAllByRole('radio')
      await userEvent.click(radioOptions[0])

      const dropdown = screen.getByRole('combobox')
      await userEvent.selectOptions(dropdown, 'less-than-30min')

      const submitButton = screen.getByRole('button', { name: /Join the Waitlist/i })
      await userEvent.click(submitButton)

      // Check for loading state
      await waitFor(() => {
        expect(screen.getByText(/Submitting.../i)).toBeInTheDocument()
      })
    })

    it('should show success message after submission', async () => {
      const mockAddDoc = addDoc as jest.MockedFunction<typeof addDoc>
      mockAddDoc.mockResolvedValueOnce({ id: 'test-id' } as any)

      render(<Home />)

      // Fill and submit form
      await userEvent.type(screen.getByPlaceholderText(/Your name/i), 'Test User')
      await userEvent.type(screen.getByPlaceholderText(/your@email.com/i), 'test@example.com')

      const radioOptions = screen.getAllByRole('radio')
      await userEvent.click(radioOptions[0])

      const dropdown = screen.getByRole('combobox')
      await userEvent.selectOptions(dropdown, 'less-than-30min')

      const submitButton = screen.getByRole('button', { name: /Join the Waitlist/i })
      await userEvent.click(submitButton)

      // Wait for success message
      await waitFor(() => {
        expect(screen.getByText(/You're on the List!/i)).toBeInTheDocument()
      }, { timeout: 3000 })
    })

    it('should handle submission errors', async () => {
      const mockAddDoc = addDoc as jest.MockedFunction<typeof addDoc>
      mockAddDoc.mockRejectedValueOnce(new Error('Firebase error'))

      // Mock window.alert
      const alertMock = jest.spyOn(window, 'alert').mockImplementation()

      render(<Home />)

      // Fill and submit form
      await userEvent.type(screen.getByPlaceholderText(/Your name/i), 'Test User')
      await userEvent.type(screen.getByPlaceholderText(/your@email.com/i), 'test@example.com')

      const radioOptions = screen.getAllByRole('radio')
      await userEvent.click(radioOptions[0])

      const dropdown = screen.getByRole('combobox')
      await userEvent.selectOptions(dropdown, 'less-than-30min')

      const submitButton = screen.getByRole('button', { name: /Join the Waitlist.*🚀/i })
      await userEvent.click(submitButton)

      // Wait for error alert
      await waitFor(() => {
        expect(alertMock).toHaveBeenCalledWith('Error submitting form. Please try again.')
      }, { timeout: 3000 })

      alertMock.mockRestore()
    }, 10000)
  })

  describe('Form Data Collection', () => {
    it('should collect all form data correctly', async () => {
      const mockAddDoc = addDoc as jest.MockedFunction<typeof addDoc>
      mockAddDoc.mockResolvedValueOnce({ id: 'test-id' } as any)

      render(<Home />)

      // Fill all fields
      await userEvent.type(screen.getByPlaceholderText(/Your name/i), 'John Doe')
      await userEvent.type(screen.getByPlaceholderText(/your@email.com/i), 'john@example.com')
      await userEvent.type(screen.getByPlaceholderText(/555/i), '+1234567890')

      // Select radio
      const radioOptions = screen.getAllByRole('radio')
      await userEvent.click(radioOptions[0])

      // Select checkboxes
      const checkboxes = screen.getAllByRole('checkbox')
      await userEvent.click(checkboxes[0])
      await userEvent.click(checkboxes[1])

      // Select dropdown
      const dropdown = screen.getByRole('combobox')
      await userEvent.selectOptions(dropdown, '1-2hours')

      // Submit
      const submitButton = screen.getByRole('button', { name: /Join the Waitlist.*🚀/i })
      await userEvent.click(submitButton)

      // Verify data structure - check the call was made and data includes expected fields
      await waitFor(() => {
        expect(mockAddDoc).toHaveBeenCalledTimes(1)
        const callArgs = mockAddDoc.mock.calls[0][1]
        expect(callArgs).toMatchObject({
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          timeSpent: '1-2hours',
          usingChatGPT: 'yes-all-the-time',
        })
        expect(callArgs.submittedAt).toBeDefined()
      }, { timeout: 3000 })
    }, 10000)
  })

  describe('Form Reset', () => {
    it('should show success state after submission', async () => {
      const mockAddDoc = addDoc as jest.MockedFunction<typeof addDoc>
      mockAddDoc.mockResolvedValueOnce({ id: 'test-id' } as any)

      render(<Home />)

      // Fill and submit
      const nameInput = screen.getByPlaceholderText(/Your name/i)
      const emailInput = screen.getByPlaceholderText(/your@email.com/i)

      await userEvent.type(nameInput, 'Test User')
      await userEvent.type(emailInput, 'test@example.com')

      const radioOptions = screen.getAllByRole('radio')
      await userEvent.click(radioOptions[0])

      const dropdown = screen.getByRole('combobox')
      await userEvent.selectOptions(dropdown, 'less-than-30min')

      const submitButton = screen.getByRole('button', { name: /Join the Waitlist.*🚀/i })
      await userEvent.click(submitButton)

      // Verify success state is shown
      await waitFor(() => {
        expect(screen.getByText(/You're on the List!/i)).toBeInTheDocument()
        expect(screen.getByText(/Thank you for joining!/i)).toBeInTheDocument()
      }, { timeout: 3000 })
    }, 10000)
  })
})
