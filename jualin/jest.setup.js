import '@testing-library/jest-dom'

// Firebase Auth checks for Fetch API support while modules are imported.
// JSDOM does not provide it consistently, so define it before test modules load.
if (!global.fetch) {
  global.fetch = jest.fn()
}
