import { render, screen } from "@testing-library/react"
import { MainNav } from "@/components/main-nav"

jest.mock("next/navigation", () => ({
  usePathname: () => "/",
}))

describe("MainNav", () => {
  it("renders navigation links", () => {
    render(<MainNav />)

    expect(screen.getByText("Dashboard")).toBeInTheDocument()
    expect(screen.getByText("Season Plans")).toBeInTheDocument()
    expect(screen.getByText("Agendas")).toBeInTheDocument()
    expect(screen.getByText("Comms")).toBeInTheDocument()
  })

  it("renders with proper navigation structure", () => {
    render(<MainNav />)

    const nav = screen.getByRole("navigation")
    expect(nav).toBeInTheDocument()
    expect(nav).toHaveClass("relative", "z-10", "flex")
  })
})
