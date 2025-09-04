import React from "react"

const mockUser = {
  id: "test-user-id",
  firstName: "Test",
  lastName: "User",
  emailAddresses: [{ emailAddress: "test@example.com" }],
}

export const useUser = jest.fn(() => ({
  isSignedIn: true,
  user: mockUser,
  isLoaded: true,
}))

export const useAuth = jest.fn(() => ({
  isSignedIn: true,
  userId: "test-user-id",
  isLoaded: true,
  signOut: jest.fn(),
}))

export const SignInButton = jest.fn(({ children, mode, ...props }) =>
  React.createElement("button", { "data-testid": "sign-in-button", ...props }, children)
)

export const SignUpButton = jest.fn(({ children, mode, ...props }) =>
  React.createElement("button", { "data-testid": "sign-up-button", ...props }, children)
)

export const SignOutButton = jest.fn(({ children, ...props }) =>
  React.createElement("button", { "data-testid": "sign-out-button", ...props }, children)
)

export const UserButton = jest.fn(() =>
  React.createElement("div", { "data-testid": "user-button" }, "User Button")
)

export const ClerkProvider = jest.fn(({ children }) =>
  React.createElement("div", { "data-testid": "clerk-provider" }, children)
)
