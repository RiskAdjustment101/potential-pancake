"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { SignInButton, SignUpButton, UserButton, useUser } from "@clerk/nextjs"
import {
  Calendar,
  FileText,
  Mail,
  Target,
  Package,
  Trophy,
  ChevronRight,
  Sparkles,
} from "lucide-react"

export default function HomePage() {
  const { isSignedIn, user } = useUser()

  const features = [
    {
      icon: Calendar,
      title: "Season Plans",
      description: "Generate 12-16 week plans tailored to your team",
      color: "text-blue-400",
    },
    {
      icon: FileText,
      title: "Weekly Agendas",
      description: "Structured meeting plans for every session",
      color: "text-green-400",
    },
    {
      icon: Mail,
      title: "Parent Comms",
      description: "Ready-to-send emails and updates",
      color: "text-purple-400",
    },
    {
      icon: Target,
      title: "Rubric Feedback",
      description: "AI-aligned guidance for student work",
      color: "text-orange-400",
    },
    {
      icon: Package,
      title: "Supply Lists",
      description: "Never forget essential materials",
      color: "text-pink-400",
    },
    {
      icon: Trophy,
      title: "Competition Prep",
      description: "Run-of-show templates for success",
      color: "text-yellow-400",
    },
  ]

  return (
    <div className="flex min-h-screen flex-col lg:flex-row">
      {/* Left Section - Authentication */}
      <div className="flex w-full flex-col justify-center bg-slate-900 px-6 py-12 sm:px-8 lg:w-1/2 lg:px-16 lg:py-0">
        <div className="mx-auto w-full max-w-md">
          <div className="mb-8">
            <div className="mb-2 flex items-center gap-2">
              <Sparkles className="h-8 w-8 text-orange-500" />
              <h1 className="text-2xl font-bold text-slate-50">FLL Mentor Copilot</h1>
            </div>
            <p className="text-slate-400">Your AI-powered FIRST LEGO League assistant</p>
          </div>

          {!isSignedIn ? (
            <Card className="border-slate-700 bg-slate-800">
              <CardContent className="p-6">
                <div className="space-y-4">
                  <SignInButton mode="modal">
                    <Button className="w-full bg-blue-500 hover:bg-blue-600">
                      Sign In
                      <ChevronRight className="ml-2 h-4 w-4" />
                    </Button>
                  </SignInButton>

                  <div className="relative">
                    <div className="absolute inset-0 flex items-center">
                      <span className="w-full border-t border-slate-700" />
                    </div>
                    <div className="relative flex justify-center text-xs uppercase">
                      <span className="bg-slate-800 px-2 text-slate-400">or</span>
                    </div>
                  </div>

                  <SignUpButton mode="modal">
                    <Button variant="outline" className="w-full border-slate-700 bg-slate-900 hover:bg-slate-800">
                      Create Account
                      <ChevronRight className="ml-2 h-4 w-4" />
                    </Button>
                  </SignUpButton>
                </div>

                <p className="mt-6 text-center text-xs text-slate-400">
                  By continuing, you agree to our{" "}
                  <a href="#" className="underline hover:text-slate-300">
                    Terms
                  </a>{" "}
                  and{" "}
                  <a href="#" className="underline hover:text-slate-300">
                    Privacy Policy
                  </a>
                </p>
              </CardContent>
            </Card>
          ) : (
            <Card className="border-slate-700 bg-slate-800">
              <CardContent className="p-6">
                <div className="flex items-center space-x-4">
                  <UserButton />
                  <div className="flex-1">
                    <p className="text-slate-50">Welcome back, {user?.firstName}!</p>
                    <p className="text-sm text-slate-400">Ready to mentor your team?</p>
                  </div>
                </div>
                <Button 
                  className="mt-4 w-full bg-blue-500 hover:bg-blue-600"
                  onClick={() => window.location.href = '/dashboard'}
                >
                  Go to Dashboard
                  <ChevronRight className="ml-2 h-4 w-4" />
                </Button>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Right Section - Features */}
      <div className="w-full bg-gradient-to-br from-slate-800 to-slate-900 px-6 py-12 sm:px-8 lg:w-1/2 lg:px-16">
        <div className="mx-auto flex h-full max-w-2xl flex-col justify-center lg:max-w-none">
          <div className="mb-8 lg:mb-12">
            <h2 className="mb-4 text-3xl font-bold text-slate-50 lg:text-4xl">
              AI-powered mentoring
              <br className="hidden sm:inline" />
              made simple
            </h2>
            <p className="text-base text-slate-300 lg:text-lg">
              Everything you need to run a successful FIRST LEGO League season
            </p>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            {features.map((feature, index) => (
              <div
                key={index}
                className="group relative overflow-hidden rounded-2xl border border-slate-700 bg-slate-800/50 p-6 backdrop-blur transition-all hover:scale-105 hover:bg-slate-800"
              >
                <div className="absolute inset-0 bg-gradient-to-br from-transparent to-slate-900/50" />
                <div className="relative">
                  <feature.icon className={`mb-3 h-8 w-8 ${feature.color}`} />
                  <h3 className="mb-2 font-semibold text-slate-50">{feature.title}</h3>
                  <p className="text-sm text-slate-400">{feature.description}</p>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-12 rounded-xl bg-orange-500/10 p-6">
            <div className="flex items-center gap-3">
              <Sparkles className="h-6 w-6 text-orange-400" />
              <div>
                <p className="text-sm font-medium text-orange-400">
                  Join the mentor community
                </p>
                <p className="mt-1 text-xs text-slate-400">
                  Help inspire the next generation of innovators
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}