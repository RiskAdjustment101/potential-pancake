import { MainNav } from "@/components/main-nav"

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-slate-900">
      <header className="sticky top-0 z-50 w-full border-b border-slate-700 bg-slate-900/95 backdrop-blur supports-[backdrop-filter]:bg-slate-900/60">
        <div className="container flex h-14 items-center">
          <MainNav />
        </div>
      </header>
      <main className="container mx-auto py-6">{children}</main>
    </div>
  )
}
