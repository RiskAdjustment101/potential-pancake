const nextJest = require("next/jest")

const createJestConfig = nextJest({
  // Provide the path to your Next.js app to load next.config.js and .env files
  dir: "./",
})

// Add any custom config to be passed to Jest
const customJestConfig = {
  setupFilesAfterEnv: ["<rootDir>/jest.setup.js"],
  testEnvironment: "jsdom",
  moduleDirectories: ["node_modules", "<rootDir>/"],
  testPathIgnorePatterns: ["<rootDir>/.next/", "<rootDir>/node_modules/", "<rootDir>/e2e/"],
  // Handle ESM modules that don't work with Jest by default
  transformIgnorePatterns: [
    "node_modules/(?!(@clerk/nextjs|@clerk/clerk-sdk-node|@clerk/backend|@clerk/shared)/)",
  ],
  // Mock Clerk modules and path mapping
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/$1",
    "^@clerk/nextjs$": "<rootDir>/__mocks__/@clerk/nextjs.js",
  },
  collectCoverageFrom: [
    "app/**/*.{js,jsx,ts,tsx}",
    "components/**/*.{js,jsx,ts,tsx}",
    "lib/**/*.{js,jsx,ts,tsx}",
    "!**/*.d.ts",
    "!**/node_modules/**",
    "!**/.next/**",
  ],
}

// createJestConfig is exported this way to ensure that next/jest can load the Next.js config which is async
module.exports = createJestConfig(customJestConfig)
