import { SignIn } from "@clerk/nextjs"

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-900">
      <div className="w-full max-w-md">
        <SignIn
          appearance={{
            elements: {
              formButtonPrimary: "bg-blue-500 hover:bg-blue-600",
              card: "bg-slate-800 border-slate-700",
              headerTitle: "text-slate-50",
              headerSubtitle: "text-slate-400",
              socialButtonsBlockButton: "bg-slate-900 border-slate-700 hover:bg-slate-800",
              formFieldLabel: "text-slate-300",
              formFieldInput: "bg-slate-900 border-slate-700 text-slate-50",
              footerActionLink: "text-blue-400 hover:text-blue-300",
            },
          }}
        />
      </div>
    </div>
  )
}
