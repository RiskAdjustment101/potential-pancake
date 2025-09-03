"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Label } from "@/components/ui/label"
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
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")

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

          <Card className="border-slate-700 bg-slate-800">
            <CardContent className="p-6">
              <Tabs defaultValue="login" className="w-full">
                <TabsList className="grid w-full grid-cols-2 bg-slate-900">
                  <TabsTrigger value="login">Sign In</TabsTrigger>
                  <TabsTrigger value="register">Sign Up</TabsTrigger>
                </TabsList>

                <TabsContent value="login" className="mt-6">
                  <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
                    <div className="space-y-2">
                      <Label htmlFor="email-login">Email</Label>
                      <Input
                        id="email-login"
                        type="email"
                        placeholder="mentor@team.com"
                        className="border-slate-700 bg-slate-900"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="password-login">Password</Label>
                      <Input
                        id="password-login"
                        type="password"
                        className="border-slate-700 bg-slate-900"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                      />
                    </div>
                    <Button className="w-full bg-blue-500 hover:bg-blue-600">
                      Sign In
                      <ChevronRight className="ml-2 h-4 w-4" />
                    </Button>
                  </form>
                </TabsContent>

                <TabsContent value="register" className="mt-6">
                  <form className="space-y-4" onSubmit={(e) => e.preventDefault()}>
                    <div className="space-y-2">
                      <Label htmlFor="email-register">Email</Label>
                      <Input
                        id="email-register"
                        type="email"
                        placeholder="mentor@team.com"
                        className="border-slate-700 bg-slate-900"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="password-register">Password</Label>
                      <Input
                        id="password-register"
                        type="password"
                        className="border-slate-700 bg-slate-900"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="password-confirm">Confirm Password</Label>
                      <Input
                        id="password-confirm"
                        type="password"
                        className="border-slate-700 bg-slate-900"
                      />
                    </div>
                    <Button className="w-full bg-blue-500 hover:bg-blue-600">
                      Create Account
                      <ChevronRight className="ml-2 h-4 w-4" />
                    </Button>
                  </form>
                </TabsContent>
              </Tabs>

              <div className="mt-6">
                <div className="relative">
                  <div className="absolute inset-0 flex items-center">
                    <span className="w-full border-t border-slate-700" />
                  </div>
                  <div className="relative flex justify-center text-xs uppercase">
                    <span className="bg-slate-800 px-2 text-slate-400">Or continue with</span>
                  </div>
                </div>

                <div className="mt-6 grid grid-cols-2 gap-3">
                  <Button variant="outline" className="border-slate-700 bg-slate-900 hover:bg-slate-800">
                    <svg className="mr-2 h-4 w-4" viewBox="0 0 24 24">
                      <path
                        fill="currentColor"
                        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                      />
                      <path
                        fill="currentColor"
                        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                      />
                      <path
                        fill="currentColor"
                        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                      />
                      <path
                        fill="currentColor"
                        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                      />
                    </svg>
                    Google
                  </Button>
                  <Button variant="outline" className="border-slate-700 bg-slate-900 hover:bg-slate-800">
                    <svg className="mr-2 h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
                    </svg>
                    GitHub
                  </Button>
                </div>
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