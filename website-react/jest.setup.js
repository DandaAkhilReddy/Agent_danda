import '@testing-library/jest-dom'

// Mock Firebase
jest.mock('./lib/firebase', () => ({
  db: {},
}))

// Mock Firestore functions
jest.mock('firebase/firestore', () => ({
  collection: jest.fn(),
  addDoc: jest.fn(() => Promise.resolve({ id: 'mock-id' })),
  query: jest.fn(),
  orderBy: jest.fn(),
  getDocs: jest.fn(() => Promise.resolve({
    forEach: jest.fn()
  })),
  serverTimestamp: jest.fn(() => new Date()),
}))

// Mock Framer Motion
jest.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }) => {
      const React = require('react')
      return React.createElement('div', props, children)
    },
    h1: ({ children, ...props }) => {
      const React = require('react')
      return React.createElement('h1', props, children)
    },
    p: ({ children, ...props }) => {
      const React = require('react')
      return React.createElement('p', props, children)
    },
    form: ({ children, ...props }) => {
      const React = require('react')
      return React.createElement('form', props, children)
    },
    button: ({ children, ...props }) => {
      const React = require('react')
      return React.createElement('button', props, children)
    },
    section: ({ children, ...props }) => {
      const React = require('react')
      return React.createElement('section', props, children)
    },
  },
}))
